"""Loopback-only, persistent backend for the independent local client.

These are new local PvE rules, not a reproduction of the unavailable game server.
All currency, progression, roster mutations and combat are resolved here.
"""
import argparse
import copy
import hashlib
import hmac
import json
import math
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
from local_game import cortege, power, journey_runtime, role_progression
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
            "hero_exp": {}, "souls": {}, "wins": {}, "battle_count": 0,
            "summon": summon_rules.initial_state(self.catalog),
        }


    def exp_table(self):
        return self.catalog.get("exp_table") or {}

    def next_exp(self, quality, level):
        """下一级所需经验 = cortege_experience.csv[quality][level]。

        ``assets.catalog()`` 用整数键；落盘成 catalog.json 再读回后 JSON 的键会变成
        字符串，所以这里同时接受 int/str 两种键。
        """
        tables = self.exp_table()
        table = tables.get(quality) or tables.get(str(quality)) or {}
        if not table:
            return 0
        value = table.get(level)
        if value is None:
            value = table.get(str(level))
        if value is not None:
            return value
        try:
            top = max(table, key=lambda key: int(key))
        except (TypeError, ValueError):
            return 0
        return table.get(top, 0)

    def role_level(self, state):
        """Original role thresholds after an explicit legacy-save migration."""
        return role_progression.info(state, self.catalog["role_levels"])[0]

    def level_cap(self, state, quality):
        """原版硬上限：min(floor(主角等级*3), 品质经验表最高级)。"""
        table = self.exp_table().get(quality) or self.exp_table().get(str(quality)) or {}
        top = max((int(key) for key in table), default=0)
        return min(self.role_level(state) * 3, top) if top else self.role_level(state) * 3

    def apply_hero_exp(self, state, ident, amount):
        """Original ui/expbookUI.lua getExpResult.

        lvLimit = {{lv=0, rate=1}, {lv=2.5, rate=0.2}, {lv=3, rate=0}}:
        below floor(主角*2.5) full exp, from floor(主角*2.5) to floor(主角*3)
        20% efficiency, at/above floor(主角*3) no exp.  Overshoot carries over
        to the next level and is never silently dropped except at the hard cap.
        """
        ident = str(ident)
        base = self.catalog["heroes"].get(ident)
        if not base or amount <= 0:
            return int(state["heroes"].get(ident, 1)), 0, 0, 0, 0
        quality = int(base.get("quality", 1))
        table = self.exp_table().get(quality) or self.exp_table().get(str(quality)) or {}
        if not table:
            return int(state["heroes"].get(ident, 1)), 0, 0, 0, 0
        role = self.role_level(state)
        normal = int(role * 2.5)
        maximum = role * 3
        top = max((int(key) for key in table), default=0)
        cap = min(maximum, top) if top else maximum
        level = int(state["heroes"][ident])
        hero_exp = state.setdefault("hero_exp", {})
        cur = float(hero_exp.get(ident, 0) or 0)
        rest = float(amount)
        added = 0.0
        levels = 0
        eps = 1e-9
        while rest > eps and level < cap:
            rate = 1.0 if level < normal else (0.2 if level < maximum else 0.0)
            if rate <= 0:
                break
            need = float(self.next_exp(quality, level) or 1)
            gap = need - cur
            if gap <= 0:
                cur = 0.0
                level += 1
                levels += 1
                continue
            raw_needed = gap / rate
            if rest + eps >= raw_needed:
                added += gap
                cur = 0.0
                rest -= raw_needed
                level += 1
                levels += 1
            else:
                gain = rest * rate
                cur += gain
                added += gain
                rest = 0.0
        if cur > 0:
            hero_exp[ident] = int(math.floor(cur))
        else:
            hero_exp.pop(ident, None)
        state["heroes"][ident] = level
        return level, int(math.floor(cur)), levels, int(math.floor(added)), int(math.floor(rest))

    def use_exp_book(self, state, args):
        """Feed 仙佛密卷/培元丹 to one 神仙, exactly like the original client."""
        hero_id = self.integer(args, "hero")
        ident = str(hero_id)
        if ident not in state.get("heroes", {}):
            raise GameError("尚未拥有该神仙")
        base = self.catalog["heroes"].get(ident)
        if not base:
            raise GameError("神仙不存在")
        quality = int(base.get("quality", 1))
        if int(state["heroes"][ident]) >= self.level_cap(state, quality):
            raise GameError("该神仙已达到主角等级限制的等级上限")
        items = args.get("items")
        if not isinstance(items, list) or not items:
            raise GameError("请选择经验书")
        bag = inventory.migrate(state)
        catalog_items = self.catalog.get("inventory", {}).get("items", {})
        wanted = {}
        for raw in items:
            if not isinstance(raw, dict):
                raise GameError("经验书参数无效")
            uid, count = raw.get("uid"), raw.get("count")
            if type(uid) is not int or type(count) is not int or count <= 0:
                raise GameError("经验书参数无效")
            wanted[uid] = wanted.get(uid, 0) + count
        picked, total = [], 0
        for uid, count in wanted.items():
            entry = next((e for e in bag["entries"] if e.get("uid") == uid), None)
            if entry is None:
                raise GameError("经验书不存在")
            item = catalog_items.get(entry["key"])
            if not item or item.get("action") != "experience":
                raise GameError("该物品不是神仙经验书")
            if int(entry.get("count", 0)) < count:
                raise GameError("经验书数量不足")
            total += int(item["original"]["experience_plus"]) * count
            picked.append((entry, count))
        if total <= 0:
            raise GameError("经验书经验为 0")
        for entry, count in picked:
            entry["count"] -= count
            if entry["count"] <= 0:
                bag["entries"].remove(entry)
        level, cur, levels, added, wasted = self.apply_hero_exp(state, hero_id, total)
        name = self.catalog["heroes"][ident]["name"]
        next_exp = self.next_exp(quality, level)
        if levels:
            notice = "%s 提升至 %d 级（神仙经验 +%d，当前 %d/%d）" % (name, level, added, cur, next_exp)
        else:
            notice = "%s 获得神仙经验 +%d（当前 %d/%d）" % (name, added, cur, next_exp)
        if wasted:
            notice += "；超出等级上限浪费 %d 点" % wasted
        return notice

    def hero(self, ident, level, state=None, resolve_synergy=True):
        if state is not None and resolve_synergy and self.catalog.get("synergy"):
            return self.roster(state)[0][int(ident)]
        base = self.catalog["heroes"].get(str(ident))
        if not base:
            raise GameError("角色不存在")
        result = dict(base)
        result["level"] = level
        # Original inheritUI/expbookUI stat formula: base + growth * (level - 1),
        # where the four growth values are the fixed per-level increments from
        # cortege_base_0.csv (base_*_plus).  This replaces the old local
        # "base * (1 + 0.14 * (level - 1))" placeholder.
        growth = base.get("growth", {})
        for key in ("hp", "attack", "defense", "magic"):
            result[key] = int(math.floor(base.get(key, 0) + float(growth.get(key, 0)) * (level - 1)))
        result["upgrade_cost"] = 80 * level
        # 经验条严格按原版：cur_exp 为当前经验，next_exp 为该级升到下一级所需经验。
        result["cur_exp"] = 0
        result["next_exp"] = self.next_exp(base.get("quality", 1), level)
        result["exp_ratio"] = 0.0
        if state is not None:
            result["cur_exp"] = int((state.get("hero_exp") or {}).get(str(ident), 0) or 0)
            result["exp_ratio"] = min(1.0, result["cur_exp"] / max(1, result["next_exp"]))
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
        # Inventory/formation helpers may normalize their input. A read-only
        # projection must not mutate the caller's save (including legacy saves).
        state = copy.deepcopy(state)
        journey_runtime.restore_progress(state, self.catalog["stages"])
        result = copy.deepcopy(state)
        heroes, support = self.roster(state)
        result["heroes"] = list(heroes.values())
        # Combat power is server-owned in the original protocol. Local stats
        # cannot reproduce it; do not reuse a stale imported/template value.
        result.pop("role_combat_power", None)
        for hero in result["heroes"]:
            hero.pop("combat_power", None)
            hero["combat_power_status"] = "unavailable"
        result["power"] = power.local_view(result["heroes"], state["lineup"])
        if support is not None:
            for slot in support["slots"]:
                hero = heroes.get(slot.get("hero"))
                if hero:
                    slot["cheer_level"] = hero.get("cheer_level", 0)
                    slot["cheer_rate"] = hero.get("cheer_rate", 1)
                    slot["hero_level"] = hero.get("level", 1)
                    slot["hero_exp"] = hero.get("cur_exp", 0)
                    slot["hero_next_exp"] = hero.get("next_exp", 0)
            result["support"] = support
        if self.catalog.get("inventory"):
            result["inventory"] = inventory.view(state, self.catalog["inventory"],
                                                 self.catalog.get("heroes"))
            result["owned"] = inventory.owned(state)
        result["summon"] = summon_rules.view(state, self.catalog)
        for hero in result["heroes"]:
            hero["active"] = hero["id"] in state["lineup"]
        result["stages"] = journey_runtime.stage_views(state, self.catalog["stages"])
        result["journey"] = {"rules": "journey-inferred-v1",
                             "settlement_status": "client_config_inferred_rules_v1"}
        result["recruits"] = [
            {**self.hero(i, 1), "cost": 600}
            for i in self.catalog["recruitable"] if str(i) not in state["heroes"]
        ]
        result["combat_modes"] = battle_modes.MODES
        result["level"], result["role_cur_exp"], result["role_next_exp"] = role_progression.info(state, self.catalog["role_levels"])
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
        journey_runtime.restore_progress(state, stages)
        if not 1 <= stage_id <= len(stages) or stage_id > state["unlocked"]:
            raise GameError("关卡尚未解锁")
        role_progression.migrate(state, self.catalog["role_levels"])
        stage = stages[stage_id - 1]
        if self.role_level(state) < stage["require_level"]:
            raise GameError("等级不足，需要等级 " + str(stage["require_level"]))
        if state["energy"] < stage["energy"]:
            raise GameError("体力不足，需要 " + str(stage["energy"]) + " 点体力")
        if not any(state["lineup"]):
            raise GameError("请至少安排一名角色出战")
        journey = journey_runtime.ensure(state)
        if journey["daily"].get(str(stage["original_id"]), 0) >= stage["daily_limit"]:
            raise GameError("今日挑战次数已用完")
        roster, _ = self.roster(state)
        allies = [dict(roster[i], lineup_slot=slot) for slot, i in enumerate(state["lineup"], 1) if i]
        enemies = copy.deepcopy(self.catalog["battle_modes"]["pve"][str(stage["original_id"])])
        report = resolve(allies, enemies, self.catalog.get("skills", {}),
                         seed=state["battle_count"] * 1009 + stage_id,
                         rules=self.catalog.get("combat_rules"))
        settlement = journey_runtime.settle(self, state, stage, report, self.catalog, allies)
        return {**report, "stage": stage, **settlement}

    def apply(self, state, op, args):
        now = int(time.time())
        role_progression.migrate(state, self.catalog["role_levels"])
        state["level"] = self.role_level(state)
        journey_runtime.ensure(state)
        journey_runtime.restore_progress(state, self.catalog["stages"])
        state.setdefault("gold", 500)
        state.setdefault("souls", {})
        summon_rules.ensure(state, self.catalog, now)
        training.ensure(state, self.catalog.get("inventory", self.catalog))
        if self.catalog.get("inventory"):
            inventory.migrate(state)
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
        elif op == "use_exp_book":
            extra["notice"] = self.use_exp_book(state, args)
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
            if state.get("journey", {}).get("star_history_version") != 1:
                history = con.execute("SELECT response FROM requests WHERE player=?", (player,))
                journey_runtime.restore_star_history(
                    state, self.catalog["stages"], (json.loads(r[0]) for r in history))
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
