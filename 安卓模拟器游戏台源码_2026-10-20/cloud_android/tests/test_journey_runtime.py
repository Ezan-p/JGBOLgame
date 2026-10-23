import copy
import json
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

from game_config import load_config
from local_game.assets import Resources, catalog
from local_game import journey_runtime as runtime, journey_rules, role_progression
from local_game.service import Game, GameError


def report(hp=100, won=True):
    return dict(won=won, seed=178, units=[dict(uid="0-0", side=0)],
                final_units=[dict(uid="0-0", hp=hp, max_hp=100)], events=[])


class JourneyRuntimeTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.root = load_config()["game_root"]
        cls.catalog = catalog(cls.root)

    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.game = Game(Path(self.tmp.name)/"save.db", self.catalog)

    def test_all_597_rows_and_enemy_positions_match_original(self):
        resources = Resources(self.root)
        rows = resources.rows("csv_config/tollgate_config.csv")
        stages = self.catalog["stages"]
        self.assertEqual(len(stages), len(rows))
        self.assertEqual([s["original_id"] for s in stages[:10]],
                         [101, 102, 103, 104, 105, 201, 202, 203, 204, 205])
        bases = {}
        for name in resources.names():
            if name.startswith("csv_config/cortege/cortege_base_") and name.endswith(".csv"):
                bases.update({int(r["type_id"]): r for r in resources.rows(name)})
        for row, stage in zip(rows, stages):
            with self.subTest(stage=stage["original_id"]):
                self.assertEqual(stage["original_id"], int(row["id"]))
                for field, raw in (("energy", "strenth_consume"), ("require_level", "require_level"),
                                   ("exp", "exp"), ("silver", "money"), ("daily_limit", "day_fight_count"),
                                   ("skill_level", "skill_level")):
                    self.assertEqual(stage[field], int(row[raw]))
                enemy = self.catalog["battle_modes"]["pve"][row["id"]]
                tokens = next(v for k,v in row.items() if k.startswith("cortege_list"))
                expected = [(slot, int(t.split("|")[0]), int(t.split("|")[1]))
                            for slot,t in enumerate(tokens.split("/"), 1) if t]
                self.assertEqual([(u["lineup_slot"],u["id"],u["level"]) for u in enemy], expected)
                for u in enemy:
                    self.assertEqual(u["level"], 1)  # All NPC stats are baked into per-stage bases.
                    b = bases[u["id"]]
                    self.assertEqual((u["hp"], u["attack"], u["defense"], u["magic"]),
                                     tuple(int(b[k]) for k in ("base_max_hp", "base_gongji", "base_fangyu", "base_max_magic")))
                    token = tokens.split("/")[u["lineup_slot"]-1].split("|")
                    extras = [int(s) for s in token[2].split("+") if s] if len(token)>2 else []
                    self.assertEqual([s["id"] for s in u["spells"]], list(dict.fromkeys([int(b["chushijineng"])]+extras)))
                    self.assertTrue(all(s["level"]==stage["skill_level"] for s in u["spells"]))
                for dest, prefix in (("drops", "random_prize"), ("three_star", "com_win_prize"),
                                     ("first_drops", "first_random_prize")):
                    raw = next(v for k,v in row.items() if k.startswith(prefix))
                    self.assertEqual([[p[k] for k in ("type","id","count","level","rate")] for p in stage[dest]],
                                     [[int(v) for v in p.split("|")] for p in raw.split("/") if p])
                    for p in stage[dest]:
                        if p["type"] in (5,6):
                            self.assertIn(("i" if p["type"]==5 else "s")+str(p["id"]), self.catalog["inventory"]["items"])
                raw = next(v for k,v in row.items() if k.startswith("first_win_prize"))
                self.assertEqual(stage["first_exp"], raw)

    def test_star_hp_thresholds_inclusive_and_defeat(self):
        for hp, expected in ((100,3),(70,3),(69,2),(40,2),(39,1),(1,1)):
            self.assertEqual(runtime.evaluate_stars(report(hp)), expected)
        self.assertEqual(runtime.evaluate_stars(report(0, False)), 0)

    def test_old_star_history_replays_hp_and_never_replays_rewards(self):
        state = self.game.initial()
        state["wins"] = {"1":2, "2":1, "3":1}
        before = copy.deepcopy(state)
        old = dict(stage={"id":1}, won=True,
                   units=[dict(uid="0-0",side=0,hp=100,max_hp=100)],
                   events=[dict(target="0-0", hp=39)])
        better = {**old, "events":[dict(hits=[dict(target="0-0",hp=70)])]}
        second = {**report(40), "stage":{"id":2}}
        runtime.restore_star_history(state, self.catalog["stages"],
            [{"battle":old}, {"battle":better}, {"battle":second}])
        self.assertEqual(state["journey"]["legacy_stars"], {"101":3,"102":2,"103":1})
        self.assertEqual(state["journey"]["stars"], {})
        self.assertEqual(state["journey"]["chapter_claimed"], [])
        for key in before:
            self.assertEqual(state[key], before[key])
        views=runtime.stage_views(state,self.catalog["stages"])
        self.assertEqual([s["stars"] for s in views[:3]], [3,2,1])
        saved=copy.deepcopy(state)
        runtime.restore_star_history(state,self.catalog["stages"],[])
        self.assertEqual(state,saved)

    def test_old_ten_stage_save_resumes_at_eleven_without_replaying_ten(self):
        state = self.game.initial()
        state.update(unlocked=10, wins={str(i):1 for i in range(1,11)}, battle_count=10)
        with self.game.connect() as db:
            db.execute("INSERT INTO players VALUES (?,?)", ("journey-player", json.dumps(state)))
        reply = self.game.request("journey-player", "resume-old-ten", "login", {})
        self.assertEqual(reply["state"]["unlocked"], 11)
        self.assertTrue(reply["state"]["stages"][10]["unlocked"])
        self.assertFalse(reply["state"]["stages"][11]["unlocked"])
        saved = self.raw()
        for key in ("silver", "gold", "energy", "battle_count", "wins"):
            self.assertEqual(saved[key], state[key])
        with patch("local_game.service.resolve", return_value=report()):
            fought = self.game.request("journey-player", "resume-fight-eleven", "battle", {"stage":11})
        self.assertEqual(fought["battle"]["stage"]["original_id"],206)
        self.assertEqual(fought["state"]["unlocked"],12)
        # An unfinished tenth stage stays locked at ten.
        unfinished = self.game.initial(); unfinished["unlocked"] = 10
        runtime.restore_progress(unfinished, self.catalog["stages"])
        self.assertEqual(unfinished["unlocked"],10)

    def test_first_victory_and_first_three_are_distinct(self):
        state = self.game.initial()
        with patch("local_game.service.resolve", return_value=report(69)):
            a = self.game.battle(state, 1)
        with patch("local_game.service.resolve", return_value=report(70)):
            b = self.game.battle(state, 1)
            c = self.game.battle(state, 1)
        self.assertTrue(a["first_clear"])
        self.assertFalse(a["first_three_star"])
        self.assertFalse(b["first_clear"])
        self.assertTrue(b["first_three_star"])
        self.assertEqual([x["silver"] for x in (a,b,c)], [150,300,150])
        self.assertEqual(state["journey"]["stars"]["101"], 3)
        self.assertEqual(state["energy"], 57)
        self.assertEqual(state["experience"], 15)  # role win_exp=5, not stage exp=100.
        self.assertGreater(sum(state["hero_exp"].values()), 0)

    def test_every_chapter_is_routable_without_fake_enemy_fallback(self):
        state = self.game.initial()
        state.update(unlocked=597, energy=1000)
        with patch("local_game.service.resolve", return_value=report(0, False)) as resolver:
            for stage in self.catalog["stages"]:
                result = self.game.battle(state, stage["id"])
                self.assertEqual(result["stage"]["original_id"], stage["original_id"])
                enemies = resolver.call_args.args[1]
                self.assertEqual([u["id"] for u in enemies], stage["enemies"])
        self.assertEqual(state["energy"], 403)
        self.assertEqual(state["battle_count"], 597)

    def test_first_items_three_star_and_chapter_granted_once(self):
        state = self.game.initial()
        with patch("local_game.service.resolve", return_value=report()):
            results = [self.game.battle(state,i) for i in range(1,6)]
            repeat = self.game.battle(state,5)
        self.assertIn(2041, [p["id"] for p in results[2]["awarded"]])
        self.assertIn(2038, [p["id"] for p in results[4]["awarded"]])
        self.assertIn("chapter_three_star", [p["reason"] for p in results[4]["awarded"]])
        self.assertNotIn("chapter_three_star", [p["reason"] for p in repeat["awarded"]])
        self.assertNotIn("first_three_star", [p["reason"] for p in repeat["awarded"]])
        self.assertEqual(state["journey"]["chapter_claimed"], [1])

    def test_all_597_victories_settle_all_67_chapter_rewards(self):
        state = self.game.initial()
        state["energy"] = 1000
        with patch("local_game.service.resolve", return_value=report()):
            for stage in self.catalog["stages"]:
                result = self.game.battle(state, stage["id"])
                self.assertEqual(result["silver"], stage["silver"]*2)
                self.assertEqual(result["stars"], 3)
        self.assertEqual(state["journey"]["chapter_claimed"], list(range(1,68)))
        self.assertEqual(len(state["wins"]),597)
        self.assertEqual(state["unlocked"],597)

    def test_constraints_transactional_replay_and_new_day(self):
        self.game.request("journey-player", "journey-login", "login", {})
        state = self.raw()
        state["unlocked"] = 5
        runtime.ensure(state)["daily"]["105"] = 9
        self.save(state)
        with patch("local_game.service.resolve", return_value=report()):
            first = self.game.request("journey-player", "journey-last", "battle", {"stage":5})
            saved = self.raw()
            repeat = self.game.request("journey-player", "journey-last", "battle", {"stage":5})
            self.assertEqual(first, repeat)
            with self.assertRaises(GameError):
                self.game.request("journey-player", "journey-limit", "battle", {"stage":5})
        self.assertEqual(self.raw(), saved)
        with patch("local_game.journey_runtime.day_number", return_value=saved["journey"]["day"]+1):
            next_day = self.game.request("journey-player", "journey-newday", "state", {})
        self.assertEqual(next_day["state"]["stages"][4]["daily_used"], 0)
        state = self.raw(); state["energy"] = 0; self.save(state)
        with self.assertRaises(GameError):
            self.game.request("journey-player", "journey-noenergy", "battle", {"stage":5})
        self.assertEqual(self.raw(), state)
        # Production table requires level 0; inject a requirement only to test the guard.
        configured = copy.deepcopy(self.catalog)
        configured["stages"][0]["require_level"] = 99
        g = Game(self.game.db, configured)
        with self.assertRaises(GameError):
            g.request("journey-player", "journey-lowlevel", "battle", {"stage":1})
        self.assertEqual(self.raw(), state)

    def test_inferred_random_boundaries_reproducibility_and_first_bonus(self):
        stage = copy.deepcopy(self.catalog["stages"][2])
        prize = stage["first_drops"][0]
        stage["drops"] = [{**prize,"rate":0}, {**prize,"rate":100}, {**prize,"rate":100}]
        stage["first_win"] = dict(exp_count=777, rate=100)
        a = journey_rules.rewards(stage,False,False,True,123)
        self.assertEqual(a, journey_rules.rewards(stage,False,False,True,123))
        self.assertEqual(len(a["drops"]), 2)
        first = journey_rules.rewards(stage,True,True,True,123)
        self.assertEqual(len(first["drops"]), 1)  # first list replaces the ordinary pool.
        self.assertEqual(first["hero_exp"], 2*stage["exp"]+777)
        self.assertEqual(first["bonus_exp"], 777)
        loss = journey_rules.rewards(stage,True,False,False,123)
        self.assertEqual((loss["drops"],loss["hero_exp"],loss["audit"]),([],0,[]))

    def test_legacy_migration_preserves_progress_and_thresholds(self):
        state=self.game.initial();state.update(experience=1850, unlocked=10, wins={"1":3,"9":1})
        old=copy.deepcopy(state)
        role_progression.migrate(state,self.catalog["role_levels"])
        role,cur,need=role_progression.info(state,self.catalog["role_levels"])
        self.assertEqual(role,10);self.assertEqual(cur,need//4)
        self.assertEqual(state["wins"],old["wins"]);self.assertEqual(state["unlocked"],10)
        converted=copy.deepcopy(state);role_progression.migrate(state,self.catalog["role_levels"])
        self.assertEqual(converted,state)
        self.assertEqual(runtime.ensure(state)["stars"],{})

    def raw(self):
        with self.game.connect() as con:
            return json.loads(con.execute("SELECT state FROM players WHERE id='journey-player'").fetchone()[0])

    def save(self,state):
        with self.game.connect() as con:
            con.execute("UPDATE players SET state=? WHERE id='journey-player'",(json.dumps(state),))
