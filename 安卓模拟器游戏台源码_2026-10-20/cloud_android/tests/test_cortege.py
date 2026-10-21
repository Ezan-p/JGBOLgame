import json
import tempfile
import unittest
from pathlib import Path

from game_config import load_config
from local_game.assets import Resources, catalog
from local_game import inventory
from local_game.handbook import build_handbook
from local_game.service import Game, GameError


class CortegeTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.root = load_config()["game_root"]
        cls.catalog = catalog(cls.root)
        cls.catalog["inventory"] = inventory.build_inventory(cls.root)
        cls.book = build_handbook(cls.root)

    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.game = Game(Path(self.temp.name) / "save.sqlite3", self.catalog)
        self.player = "cortege-test-01"
        self.game.request(self.player, "cortege-login-01", "login", {})

    def raw(self):
        with self.game.connect() as db:
            return json.loads(db.execute("SELECT state FROM players WHERE id=?",
                                         (self.player,)).fetchone()[0])

    def save(self, state):
        with self.game.connect() as db:
            db.execute("UPDATE players SET state=? WHERE id=?",
                       (json.dumps(state), self.player))

    def test_reverse_engineered_soul_jingpo_and_common_soul_data(self):
        self.assertEqual([(s["name"], s["quality"], s["sub_type"], s["category"])
                          for s in self.book["spirits"]], [
            ("五星仙界魂", 5, 1, "神"), ("五星妖界魂", 5, 2, "妖"),
            ("五星人界魂", 5, 3, "人"), ("五星魔界魂", 5, 4, "魔"),
            ("五星佛界魂", 5, 5, "佛"), ("四星仙界魂", 4, 1, "神"),
            ("四星妖界魂", 4, 2, "妖"), ("四星人界魂", 4, 3, "人"),
            ("四星魔界魂", 4, 4, "魔"), ("四星佛界魂", 4, 5, "佛"),
        ])
        self.assertEqual(len(self.book["essence"]), 38)
        self.assertTrue(all(s["icon"]["index"] for s in self.book["spirits"]))
        needs = {h["quality"]: (h["soul_need"], h["soul_gain"]) for h in self.book["heroes"]}
        self.assertEqual(needs[2], (10, 4))
        self.assertEqual(needs[3], (20, 9))
        self.assertEqual(needs[4], (30, 12))
        self.assertEqual(needs[5], (40, 15))
        resources = Resources(self.root)
        for name in ("v2/CharaterUI/shenxian1.png", "v2/CharaterUI/hunpo1.png",
                     "v2/CharaterUI/jingpo1.png", "v2/CharaterUI/common1.png",
                     "v2/CharaterUI/common2.png", "v2/handbook/tj_btn1.png",
                     "v2/packageUI/xinxilan.png", "v2/introUI/stars.png"):
            self.assertIn(name, self.book["resources"])
            self.assertTrue(resources.read(name).startswith(b"\x89PNG"))

    def test_soul_conjure_uses_original_compose_count(self):
        state = self.raw()
        state["souls"]["2001"] = 10
        self.save(state)
        result = self.game.request(self.player, "cortege-compose-01",
                                   "cortege_compose", {"hero": 2001})
        self.assertIn(2001, [h["id"] for h in result["state"]["heroes"]])
        stored = self.raw()
        self.assertEqual(stored["heroes"]["2001"], 1)
        self.assertNotIn("2001", stored["souls"])
        with self.assertRaises(GameError):
            self.game.request(self.player, "cortege-compose-02",
                              "cortege_compose", {"hero": 2001})

    def test_soul_conjure_insufficient_is_atomic(self):
        state = self.raw()
        state["souls"]["2001"] = 9
        self.save(state)
        before = self.raw()
        with self.assertRaises(GameError):
            self.game.request(self.player, "cortege-compose-broke",
                              "cortege_compose", {"hero": 2001})
        self.assertEqual(self.raw(), before)

    def test_common_soul_conversion_matches_category_and_quality(self):
        state = self.raw()
        inventory.grant(state, "i5001", 2, catalog=self.catalog["inventory"])
        self.save(state)
        result = self.game.request(self.player, "cortege-convert-01",
                                   "cortege_convert", {"item": 5001, "hero": 5003})
        self.assertEqual(self.raw()["souls"]["5003"], 1)
        self.assertEqual([e for e in self.raw()["inventory"]["entries"]
                          if e["key"] == "i5001"][0]["count"], 1)
        self.assertIn("东海龙王", result["notice"])
        with self.assertRaises(GameError):
            self.game.request(self.player, "cortege-convert-wrong-hero",
                              "cortege_convert", {"item": 5001, "hero": 5001})
        with self.assertRaises(GameError):
            self.game.request(self.player, "cortege-convert-wrong-item",
                              "cortege_convert", {"item": 2006, "hero": 5003})
        self.game.request(self.player, "cortege-convert-02",
                          "cortege_convert", {"item": 5001, "hero": 5003})
        self.assertEqual(self.raw()["souls"]["5003"], 2)
        self.assertFalse([e for e in self.raw()["inventory"]["entries"]
                          if e["key"] == "i5001"])
        before = self.raw()
        with self.assertRaises(GameError):
            self.game.request(self.player, "cortege-convert-empty",
                              "cortege_convert", {"item": 5001, "hero": 5003})
        self.assertEqual(self.raw(), before)

    def test_catalogue_ownership_lists_all_four_tabs(self):
        state = self.raw()
        for key in ("i2006", "s202", "i10101"):
            inventory.grant(state, key, 1, catalog=self.catalog["inventory"])
        self.save(state)
        owned = self.game.request(self.player, "cortege-owned-01", "state", {})["state"]["owned"]
        self.assertIn(5022, owned["heroes"])
        self.assertIn(2006, owned["equipment"])
        self.assertIn(202, owned["spells"])
        self.assertIn(10101, owned["essence"])
        self.assertTrue(all(isinstance(owned[name], list) and
                            owned[name] == sorted(owned[name]) for name in
                            ("heroes", "equipment", "spells", "essence")))


if __name__ == "__main__":
    unittest.main()
