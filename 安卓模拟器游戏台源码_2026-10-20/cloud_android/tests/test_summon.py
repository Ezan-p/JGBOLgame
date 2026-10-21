import json
import tempfile
import unittest
from pathlib import Path

from game_config import load_config
from local_game.assets import Resources, catalog
from local_game.service import Game, GameError
from local_game import summon as rules
from local_game.summon import build_summon


class SummonTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.root = load_config()["game_root"]
        cls.summon = build_summon(cls.root)
        cls.catalog = catalog(cls.root)
        cls.catalog["summon"] = {"pools": cls.summon["pools"], "tiers": cls.summon["tiers"]}

    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.game = Game(Path(self.temp.name) / "save.sqlite3", self.catalog)
        self.player = "summon-test-01"
        self.game.request(self.player, "summon-login-01", "login", {})

    def raw(self):
        with self.game.connect() as db:
            return json.loads(db.execute("SELECT state FROM players WHERE id=?", (self.player,)).fetchone()[0])

    def save(self, state):
        with self.game.connect() as db:
            db.execute("UPDATE players SET state=? WHERE id=?", (json.dumps(state), self.player))

    def test_original_pools_and_ui_resources(self):
        pools = self.summon["pools"]
        self.assertEqual(len(pools["1"]), 120)  # 2-4 stars
        self.assertEqual(len(pools["2"]), 128)  # summon_cortege_set index 1
        self.assertEqual(len(pools["3"]), 93)   # summon_cortege_set index 2
        for grade, values in pools.items():
            self.assertTrue(set(values) <= set(self.catalog["recruitable"]))
            low, high = rules.QUALITY_RANGE[int(grade)]
            self.assertTrue(all(low <= self.catalog["heroes"][str(i)]["quality"] <= high
                                for i in values))
        self.assertEqual([tier["cost"] for tier in self.summon["tiers"]], [10, 100, 300])
        self.assertEqual(self.summon["normal_daily_free"], 5)
        self.assertIn("v2/summonUI/summon_bkg_1.png", self.summon["resources"])
        self.assertIn("v2/summonUI/newsHZ.png", self.summon["resources"])
        resources = Resources(self.root)
        for name in self.summon["resources"]:
            data = resources.read(name)
            self.assertTrue(data.startswith(b"\x89PNG") or data.startswith(b"\xff\xd8"), name)

    def test_initial_view_matches_reference_news_and_last_summon(self):
        summon = self.game.request(self.player, "summon-state-01", "state", {})["state"]["summon"]
        self.assertEqual(summon["last"]["name"], "南山大王")
        self.assertEqual([entry["type_id"] for entry in summon["news"]],
                         [5018, 5002, 5042, 5020])
        self.assertEqual([tier["free"] for tier in summon["tiers"]], [True, True, True])
        self.assertEqual([tier["cost"] for tier in summon["tiers"]], [10, 100, 300])

    def test_free_then_paid_and_cooldown_counts(self):
        before = self.raw()
        first = self.game.request(self.player, "summon-free-01", "summon", {"grade": 2})
        self.assertTrue(first["summon_result"]["free"])
        self.assertEqual(first["summon_result"]["cost"], 0)
        self.assertEqual(first["state"]["gold"], before["gold"])
        second = self.game.request(self.player, "summon-paid-02", "summon", {"grade": 2})
        self.assertFalse(second["summon_result"]["free"])
        self.assertEqual(second["summon_result"]["cost"], 100)
        self.assertEqual(second["state"]["gold"], before["gold"] - 100)
        self.assertGreater(second["state"]["summon"]["tiers"][1]["remaining"], 0)
        self.assertIn(second["summon_result"]["hero"]["quality"], (3, 4, 5))

    def test_five_daily_normal_free_picks_then_paid(self):
        state = self.raw()
        state["summon"]["normal_used"] = 5
        state["summon"]["normal_time"] = 0
        self.save(state)
        view = self.game.request(self.player, "summon-limit-01", "state", {})["state"]["summon"]
        self.assertFalse(view["tiers"][0]["free"])
        result = self.game.request(self.player, "summon-limit-02", "summon", {"grade": 1})
        self.assertFalse(result["summon_result"]["free"])
        self.assertEqual(result["summon_result"]["cost"], 10)
        self.assertEqual(result["state"]["gold"], 490)

    def test_duplicate_grant_converts_to_souls(self):
        state = self.raw()
        state["gold"] = 1000
        before_silver = state["silver"]
        add = lambda ident: state["lineup"].append(ident)
        hero, is_new, soul_gain, soul_total, soul_need = rules.grant(
            state, self.catalog, 2001, add, GameError)
        self.assertTrue(is_new)
        self.assertEqual((soul_gain, soul_total), (0, 0))
        hero, is_new, soul_gain, soul_total, soul_need = rules.grant(
            state, self.catalog, 2001, add, GameError)
        self.assertFalse(is_new)
        self.assertEqual(soul_gain, rules.SOUL_CONVERT[hero["quality"]])
        self.assertEqual(soul_total, soul_gain)
        self.assertEqual(soul_need, rules.SOUL_COMPOSE[hero["quality"]])
        hero, is_new, soul_gain, soul_total, soul_need = rules.grant(
            state, self.catalog, 2001, add, GameError)
        self.assertEqual(state["souls"]["2001"], rules.SOUL_CONVERT[hero["quality"]] * 2)
        self.assertEqual(state["silver"], before_silver)

    def test_soul_conversion_amounts_match_original_quality_config(self):
        for ident, expected in ((2001, 4), (3001, 9), (4001, 12), (5001, 15)):
            with self.subTest(hero=ident):
                state = self.raw()
                hero, *_ = rules.grant(state, self.catalog, ident, lambda i: None, GameError)
                hero, is_new, soul_gain, soul_total, soul_need = rules.grant(
                    state, self.catalog, ident, lambda i: None, GameError)
                self.assertFalse(is_new)
                self.assertEqual(soul_gain, expected)
                self.assertEqual(soul_total, expected)
                self.assertEqual(soul_need, rules.SOUL_COMPOSE[hero["quality"]])

    def test_duplicate_summon_returns_soul_counts(self):
        state = self.raw()
        state["heroes"] = {str(ident): 1 for ident in self.catalog["recruitable"]}
        state["lineup"] = [5022]
        state["summon"]["normal_time"] = 0
        state["summon"]["normal_used"] = 0
        self.save(state)
        result = self.game.request(self.player, "summon-soul-01", "summon", {"grade": 1})["summon_result"]
        self.assertFalse(result["new"])
        self.assertIn(result["soul_gain"], (4, 9, 12, 15))
        self.assertEqual(result["soul_total"], result["soul_gain"])
        self.assertEqual(result["soul_need"], rules.SOUL_COMPOSE[result["hero"]["quality"]])
        stored = self.raw()
        self.assertEqual(stored["souls"][str(result["hero"]["id"])], result["soul_total"])

    def test_news_limited_to_seven_and_survives_restart(self):
        state = self.raw()
        state["gold"] = 100000
        self.save(state)
        for index in range(8):
            self.game.request(self.player, f"summon-news-{index:02d}", "summon", {"grade": 1})
            state = self.raw()
            state["summon"]["normal_time"] = 0
            state["summon"]["normal_used"] = 0
            self.save(state)
        state = self.raw()
        self.assertEqual(len(state["summon"]["news"]), 7)
        self.assertEqual(state["summon"]["news"][0]["name"], "本地行者")
        self.assertEqual(state["summon"]["last"], state["summon"]["news"][0]["type_id"])
        resumed = Game(self.game.db, self.catalog)
        loaded = resumed.request(self.player, "summon-reload-01", "state", {})["state"]
        self.assertEqual(loaded["summon"]["pulls"], 8)
        self.assertEqual(loaded["summon"]["last"]["id"], state["summon"]["last"])

    def test_invalid_grades_do_not_mutate(self):
        before = self.raw()
        for index, grade in enumerate((0, 4, "1", True, None)):
            with self.assertRaises(GameError):
                self.game.request(self.player, f"summon-bad-{index:02d}", "summon", {"grade": grade})
            self.assertEqual(self.raw(), before)

    def test_insufficient_gold_is_atomic(self):
        state = self.raw()
        state["gold"] = 50
        state["summon"]["advance_time"] = 2 ** 31
        self.save(state)
        before = self.raw()
        with self.assertRaises(GameError):
            self.game.request(self.player, "summon-broke-01", "summon", {"grade": 2})
        self.assertEqual(self.raw(), before)


if __name__ == "__main__":
    unittest.main()
