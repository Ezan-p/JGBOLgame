"""Loopback-only, persistent backend for the independent local client.

These are new local PvE rules, not a reproduction of the unavailable game server.
All currency, progression, roster mutations and combat are resolved here.
"""
import argparse
import copy
import hashlib
import hmac
import json
import re
import sqlite3
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import parse_qs, urlsplit

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / ".runtime/local_game"
PORT = 8770
# Also support direct execution by manage.py.
import sys
sys.path.insert(0, str(ROOT))
from local_game.combat import resolve, apply_passives
from local_game import cortege
from local_game import inventory
from local_game import synergy
from local_game import summon as summon_rules
from local_game import battle_modes, battle_training, training


class GameError(ValueError):
    pass


class Game:
    def __init__(self, db, catalog):
        self.db = Path(db)
        self.catalog = catalog
        self.db.parent.mkdir(parents=True, exist_ok=True)
        with self.connect() as con:
            con.executescript("""
                PRAGMA journal_mode=WAL;
                CREATE TABLE IF NOT EXISTS players (id TEXT PRIMARY KEY, state TEXT NOT NULL);
                CREATE TABLE IF NOT EXISTS requests (
                    player TEXT NOT NULL, request TEXT NOT NULL, hash TEXT NOT NULL, response TEXT NOT NULL,
                    PRIMARY KEY(player, request));
            """)

    def connect(self):
        con = sqlite3.connect(self.db, timeout=15)
        con.row_factory = sqlite3.Row
        return con

    def initial(self):
        return {
            "schema": 1, "name": "本地行者", "silver": 1200, "gold": 500, "experience": 0,
            "energy": 60, "energy_time": int(time.time()), "unlocked": 1,
            "heroes": {"5022": 1, "5004": 1}, "lineup": [5022, 5004],
            "souls": {}, "wins": {}, "battle_count": 0,
            "summon": summon_rules.initial_state(self.catalog),
        }

    def hero(self, ident, level, state=None, resolve_synergy=True):
        if state is not None and resolve_synergy and self.catalog.get("synergy"):
            return self.roster(state)[0][int(ident)]
        base = self.catalog["heroes"].get(str(ident))
        if not base:
            raise GameError("角色不存在")
        result = dict(base)
        result["level"] = level
        for key in ("hp", "attack", "defense", "magic"):
            result[key] = round(base.get(key, 0) * (1 + .14 * (level - 1)))
        result["upgrade_cost"] = 80 * level
        learned = None
        if state is not None:
            learned = training.read(state, int(ident), level)
            bonus = learned["bonus"]
            result["culture_point"] = learned["potential"]
            result["hp_plus"] = int(bonus.get("hp", 0))
            result["attack_plus"] = int(bonus.get("attack", 0))
            result["defense_plus"] = int(bonus.get("defense", 0))
            result["magic_plus"] = int(bonus.get("magic", 0))
            result["train_pending"] = learned["pending"]
        if state is not None and self.catalog.get("inventory"):
            result = inventory.hero_with_inventory(result, state, self.catalog["inventory"])
        result = apply_passives(result, self.catalog.get("skills", {}))
        # Original training points are flat additions: +1 potential = +1 final stat.
        if learned is not None:
            for key in ("hp", "attack", "defense", "magic"):
                result[key] += int(learned["bonus"].get(key, 0))
        return result

    def roster(self, state):
        heroes = [self.hero(k, v, state, False) for k, v in state["heroes"].items()]
        if self.catalog.get("synergy"):
            return synergy.evaluate(heroes, state, self.catalog["synergy"], self.catalog.get("inventory", {"items": {}}))
        return {h["id"]: h for h in heroes}, None

    def view(self, state):
        result = copy.deepcopy(state)
        heroes, support = self.roster(state)
        result["heroes"] = list(heroes.values())
        if support is not None:
            result["support"] = support
        if self.catalog.get("inventory"):
            result["inventory"] = inventory.view(state, self.catalog["inventory"])
            result["owned"] = inventory.owned(state)
        result["summon"] = summon_rules.view(state, self.catalog)
        for hero in result["heroes"]:
            hero["active"] = hero["id"] in state["lineup"]
        result["stages"] = [
            {**s, "unlocked": s["id"] <= state["unlocked"],
             "cleared": str(s["id"]) in state["wins"]}
            for s in self.catalog["stages"]
        ]
        result["recruits"] = [
            {**self.hero(i, 1), "cost": 600}
            for i in self.catalog["recruitable"] if str(i) not in state["heroes"]
        ]
        result["combat_modes"] = battle_modes.MODES
        result["level"] = 1 + state["experience"] // 200
        return result

    @staticmethod
    def integer(args, name):
        value = args.get(name)
        if type(value) is not int:
            raise GameError("参数必须是整数：" + name)
        return value

    @staticmethod
    def capacity(state):
        return max(4, min(8, int(state.get("lineup_capacity", 4))))

    def add_to_lineup(self, state, ident):
        lineup = state["lineup"]
        if 0 in lineup:
            lineup[lineup.index(0)] = ident
        elif len(lineup) < self.capacity(state):
            lineup.append(ident)
        else:
            raise GameError("阵位已满，请先让一名神仙休息")

    def battle(self, state, stage_id):
        stages = self.catalog["stages"]
        if not 1 <= stage_id <= len(stages) or stage_id > state["unlocked"]:
            raise GameError("关卡尚未解锁")
        if state["energy"] < 2:
            raise GameError("体力不足，每五分钟恢复一点")
        if not any(state["lineup"]):
            raise GameError("请至少安排一名角色出战")
        stage = stages[stage_id - 1]
        roster, _ = self.roster(state)
        allies = [dict(roster[i], lineup_slot=slot) for slot, i in enumerate(state["lineup"], 1) if i]
        enemies = copy.deepcopy(self.catalog.get("battle_modes", {}).get("pve", {}).get(str(stage["original_id"])))
        original_enemies = bool(enemies)
        enemies = enemies or [self.hero(i, 1) for i in stage["enemies"]]
        scale = .75 + stage_id * .11
        for unit in ([] if original_enemies else enemies):
            for stat in ("hp", "attack", "defense"):
                unit[stat] = round(unit[stat] * scale)
        report = resolve(allies, enemies, self.catalog.get("skills", {}), seed=state["battle_count"] * 1009 + stage_id, rules=self.catalog.get("combat_rules"))
        won = report["won"]
        first = won and str(stage_id) not in state["wins"]
        reward = stage["silver"] * (2 if first else 1) if won else 20
        experience = stage["exp"] if won else 0
        state["silver"] += reward
        state["experience"] += experience
        state["energy"] -= 2
        state["battle_count"] += 1
        if won:
            state["wins"][str(stage_id)] = state["wins"].get(str(stage_id), 0) + 1
            state["unlocked"] = min(len(stages), max(state["unlocked"], stage_id + 1))
        return {**report, "stage": stage,
                "silver": reward, "experience": experience, "first_clear": first,
                "number": state["battle_count"]}

    def apply(self, state, op, args):
        now = int(time.time())
        state.setdefault("gold", 500)
        state.setdefault("souls", {})
        summon_rules.ensure(state, self.catalog, now)
        training.ensure(state, self.catalog.get("inventory", self.catalog))
        elapsed = max(0, (now - state["energy_time"]) // 300)
        if elapsed:
            state["energy"] = min(60, state["energy"] + elapsed)
            state["energy_time"] += elapsed * 300
        if state["energy"] >= 60:
            state["energy_time"] = now
        extra = {}
        if op in ("login", "state"):
            pass
        elif op in ("train", "train_accept", "train_giveup"):
            extra["notice"] = training.apply(
                state, op, args, self.catalog.get("inventory", self.catalog), GameError)
        elif op == "upgrade":
            ident = str(self.integer(args, "hero"))
            if ident not in state["heroes"]:
                raise GameError("尚未拥有该角色")
            level = state["heroes"][ident]
            if level >= 20:
                raise GameError("当前本地版角色等级上限为 20")
            if state["silver"] < level * 80:
                raise GameError("银两不足，可挑战已通关关卡获取")
            state["silver"] -= level * 80
            state["heroes"][ident] += 1
            extra["notice"] = "角色升级成功，已保存"
        elif op == "recruit":
            ident = self.integer(args, "hero")
            if ident not in self.catalog["recruitable"] or str(ident) in state["heroes"]:
                raise GameError("该角色不可招募或已经拥有")
            if state["silver"] < 600:
                raise GameError("招募需要 600 银两")
            state["silver"] -= 600
            state["heroes"][str(ident)] = 1
            if sum(bool(i) for i in state["lineup"]) < self.capacity(state):
                self.add_to_lineup(state, ident)
            extra["notice"] = "招募成功，已保存"
        elif op == "summon":
            result = summon_rules.pull(
                state, args.get("grade"), self.catalog, GameError,
                lambda ident: self.add_to_lineup(state, ident), now=now)
            extra["summon_result"] = result
            extra["notice"] = ("召唤成功：" + result["hero"]["name"] if result["new"] else
                               "重复神仙，获得 %d 魂魄（共有 %d）" %
                               (result["soul_gain"], result["soul_total"]))
            if result["free"]:
                extra["notice"] = result["grade_name"] + "免费召唤：" + result["hero"]["name"]
                if not result["new"]:
                    extra["notice"] += "（重复，获得 %d 魂魄）" % result["soul_gain"]
        elif op == "cortege_compose":
            extra["notice"] = cortege.compose(
                state, args, self.catalog, GameError,
                lambda ident: self.add_to_lineup(state, ident))
        elif op == "cortege_convert":
            extra["notice"] = cortege.convert(state, args, self.catalog, GameError)
        elif op == "lineup":
            ident = self.integer(args, "hero")
            if str(ident) not in state["heroes"]:
                raise GameError("尚未拥有该角色")
            if ident in state["lineup"]:
                if sum(bool(i) for i in state["lineup"]) == 1:
                    raise GameError("至少保留一名出战角色")
                if self.capacity(state) > 4:
                    state["lineup"][state["lineup"].index(ident)] = 0
                    while state["lineup"] and not state["lineup"][-1]:
                        state["lineup"].pop()
                else:
                    state["lineup"].remove(ident)
            else:
                if ident in synergy.support_ids(state):
                    raise GameError("该神仙正在助阵，请先卸下助阵")
                self.add_to_lineup(state, ident)
        elif op == "lineup_swap":
            source = self.integer(args, "source")
            target = self.integer(args, "target")
            limit = self.capacity(state) if self.capacity(state) > 4 else len(state["lineup"])
            if not (1 <= source <= len(state["lineup"]) and state["lineup"][source-1] and
                    1 <= target <= limit):
                raise GameError("请选择已有神仙的阵位")
            lineup = state["lineup"]
            lineup.extend([0] * max(0, target-len(lineup)))
            lineup[source - 1], lineup[target - 1] = lineup[target - 1], lineup[source - 1]
            extra["notice"] = "阵位已保存"
        elif op == "lineup_replace":
            slot = self.integer(args, "slot")
            ident = self.integer(args, "hero")
            if str(ident) not in state["heroes"]:
                raise GameError("尚未拥有该角色")
            if ident in state["lineup"]:
                raise GameError("该神仙已在阵中，请使用布阵调整站位")
            if ident in synergy.support_ids(state):
                raise GameError("该神仙正在助阵，请先卸下助阵")
            limit = self.capacity(state) if self.capacity(state) > 4 else min(4, len(state["lineup"]) + 1)
            if not 1 <= slot <= limit:
                raise GameError("阵位无效")
            state["lineup"].extend([0] * max(0, slot-len(state["lineup"])))
            state["lineup"][slot - 1] = ident
            extra["notice"] = "神仙已更换，阵容已保存"
        elif op.startswith("support_") and self.catalog.get("synergy"):
            extra["notice"] = synergy.apply(state, op, args, self.catalog, GameError)
        elif op == "battle_mode":
            extra["battle"] = battle_modes.fight(self,state,args.get('mode'),GameError)
        elif op in ("battle_native_upgrade", "battle_awaken", "battle_cheer_upgrade"):
            extra['notice']=battle_training.apply(state,op,args,self.catalog,GameError)
        elif op == "battle":
            extra["battle"] = self.battle(state, self.integer(args, "stage"))
        elif op.startswith("bag_") and self.catalog.get("inventory"):
            extra["notice"] = inventory.apply(state, op, args, self.catalog["inventory"], GameError)
        else:
            raise GameError("当前本地版不支持此操作")
        synergy.tidy_targets(state)
        training.ensure(state, self.catalog.get("inventory", self.catalog))
        state["saved_at"] = now
        return {"ok": True, "state": self.view(state), **extra}

    def request(self, player, request_id, op, args):
        if not re.fullmatch(r"[a-zA-Z0-9_-]{8,96}", player or ""):
            raise GameError("本地存档标识无效")
        if not re.fullmatch(r"[a-zA-Z0-9_-]{8,120}", request_id or ""):
            raise GameError("请求标识无效")
        # The original Lua JSON library serializes an empty table as [].
        if op in ("login", "state") and args == []:
            args = {}
        if not isinstance(args, dict) or len(args) > 8:
            raise GameError("参数格式无效")
        fingerprint = hashlib.sha256(json.dumps([op, args], sort_keys=True).encode()).hexdigest()
        with self.connect() as con:
            con.execute("BEGIN IMMEDIATE")
            old = con.execute("SELECT hash,response FROM requests WHERE player=? AND request=?",
                              (player, request_id)).fetchone()
            if old:
                if old["hash"] != fingerprint:
                    raise GameError("重复请求标识对应了不同操作")
                return json.loads(old["response"])
            row = con.execute("SELECT state FROM players WHERE id=?", (player,)).fetchone()
            if not row and op != "login":
                raise GameError("请先进入本地存档")
            state = json.loads(row["state"]) if row else self.initial()
            response = self.apply(state, op, args)
            con.execute("INSERT OR REPLACE INTO players VALUES (?,?)",
                        (player, json.dumps(state, ensure_ascii=False)))
            con.execute("INSERT INTO requests VALUES (?,?,?,?)",
                        (player, request_id, fingerprint, json.dumps(response, ensure_ascii=False)))
            return response


def handler(game, key):
    class Handler(BaseHTTPRequestHandler):
        def log_message(self, fmt, *args):
            # URL contains the local installation key: never write it to logs.
            pass

        def reply(self, result, code=200):
            data = json.dumps(result, ensure_ascii=False, separators=(",", ":")).encode()
            self.send_response(code)
            self.send_header("Content-Type", "application/json; charset=utf-8")
            self.send_header("Cache-Control", "no-store")
            self.send_header("Content-Length", str(len(data)))
            self.end_headers()
            self.wfile.write(data)

        def do_GET(self):
            if len(self.path) > 8192:
                return self.reply({"ok": False, "error": "请求过大"}, 413)
            url = urlsplit(self.path)
            if url.path == "/health":
                return self.reply({"ok": True, "service": "jingubang-local", "rules": "local-v4"})
            if url.path != "/rpc":
                return self.reply({"ok": False, "error": "接口不存在"}, 404)
            query = parse_qs(url.query)
            supplied = query.get("key", [""])[0]
            if not hmac.compare_digest(supplied, key):
                return self.reply({"ok": False, "error": "本地客户端密钥不匹配"}, 403)
            try:
                get = lambda field: query.get(field, [""])[0]
                args = json.loads(get("args") or "{}")
                result = game.request(get("player"), get("request"), get("op"), args)
            except (ValueError, TypeError) as exc:
                result = {"ok": False, "error": str(exc)}
            except Exception:
                import traceback
                traceback.print_exc()
                result = {"ok": False, "error": "本地服务发生错误，存档未提交"}
            self.reply(result)
    return Handler


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--port", type=int, default=PORT)
    parser.add_argument("--data-dir", type=Path, default=DATA)
    args = parser.parse_args()
    key = (args.data_dir / "client-key").read_text().strip()
    catalog = json.loads((args.data_dir / "catalog.json").read_text())
    game = Game(args.data_dir / "save.sqlite3", catalog)
    server = ThreadingHTTPServer(("127.0.0.1", args.port), handler(game, key))
    server.daemon_threads = True
    print(f"金箍棒本地服务 http://127.0.0.1:{args.port}，存档 {game.db}", flush=True)
    server.serve_forever()


if __name__ == "__main__":
    main()
