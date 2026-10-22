import json
import tempfile
import unittest
from pathlib import Path

from game_config import load_config
from local_game.assets import catalog
from local_game.inventory import build_inventory, grant
from local_game.service import Game, GameError


class ExpBookTests(unittest.TestCase):
    """Original expbookUI.lua rules: 仙佛密卷/培元丹 -> hero exp."""

    @classmethod
    def setUpClass(cls):
        root = load_config()["game_root"]
        cls.catalog = catalog(root)
        cls.catalog["inventory"] = build_inventory(root)

    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.game = Game(Path(self.temp.name) / "save.db", self.catalog)
        self.player = "exp-book-test-player"
        self.counter = 0
        self.call("login")

    def call(self, op, **args):
        self.counter += 1
        return self.game.request(self.player, f"exp-{self.counter:05}", op, args)

    def raw(self):
        with self.game.connect() as con:
            return json.loads(con.execute("SELECT state FROM players WHERE id=?",
                                          (self.player,)).fetchone()[0])

    def save(self, state):
        with self.game.connect() as con:
            con.execute("UPDATE players SET state=? WHERE id=?",
                        (json.dumps(state), self.player))

    def give(self, key, count=1):
        state = self.raw()
        grant(state, key, count, catalog=self.catalog["inventory"])
        self.save(state)
        return next(e for e in self.raw()["inventory"]["entries"] if e["key"] == key)

    def test_full_then_twenty_percent_band_and_carry(self):
        # 5★ 孙悟空 Lv.1: next_exp 132.  角色 Lv.1 => normal=floor(1*2.5)=2, hard cap=3.
        # 1200 raw: 132 fills Lv.1 (rate 1), remaining 1068 at 20% => +213, Lv.2.
        book = self.give("i1041")
        reply = self.call("use_exp_book", hero=5022, items=[dict(uid=book["uid"], count=1)])
        state = self.raw()
        self.assertEqual(state["heroes"]["5022"], 2)
        self.assertEqual(state["hero_exp"]["5022"], 213)
        self.assertNotIn("i1041", [e["key"] for e in state["inventory"]["entries"]])
        self.assertIn("提升至 2 级", reply["notice"])
        hero = next(h for h in reply["state"]["heroes"] if h["id"] == 5022)
        self.assertEqual((hero["level"], hero["cur_exp"], hero["next_exp"]), (2, 213, 275))

    def test_role_level_cap_blocks_further_exp(self):
        state = self.raw()
        state["heroes"]["5022"] = 3  # role Lv.1 hard cap = floor(1*3) = 3
        self.save(state)
        book = self.give("i1041")
        with self.assertRaises(GameError):
            self.call("use_exp_book", hero=5022, items=[dict(uid=book["uid"], count=1)])
        self.assertEqual(self.raw()["inventory"]["entries"][0]["count"], 1)

    def test_raise_role_level_unlocks_more_hero_levels(self):
        state = self.raw()
        state["experience"] = 400  # role Lv.3 => normal=7, hard cap=9
        state["heroes"]["5022"] = 2
        self.save(state)
        book = self.give("i1041")
        self.call("use_exp_book", hero=5022, items=[dict(uid=book["uid"], count=1)])
        state = self.raw()
        self.assertGreaterEqual(state["heroes"]["5022"], 3)
        self.assertLessEqual(state["heroes"]["5022"], 9)

    def test_high_tier_book_caps_and_reports_waste(self):
        book = self.give("i1080")  # 156,000,000 神仙经验
        reply = self.call("use_exp_book", hero=5022, items=[dict(uid=book["uid"], count=1)])
        self.assertEqual(self.raw()["heroes"]["5022"], 3)
        self.assertIn("浪费", reply["notice"])

    def test_chemistry_pill_rejected(self):
        book = self.give("i1442")  # 药灵丹 sub_type 101 -> 炼药, not 神仙经验书
        with self.assertRaises(GameError):
            self.call("use_exp_book", hero=5022, items=[dict(uid=book["uid"], count=1)])

    def test_quantity_and_item_validation(self):
        book = self.give("i1041", 1)
        for args in (dict(hero=5022, items=[dict(uid=book["uid"], count=2)]),
                     dict(hero=5022, items=[dict(uid=-1, count=1)]),
                     dict(hero=9999, items=[dict(uid=book["uid"], count=1)]),
                     dict(hero=5022, items=[])):
            with self.assertRaises(GameError):
                self.call("use_exp_book", **args)
        self.assertEqual(self.raw()["inventory"]["entries"][0]["count"], 1)

    def test_request_idempotency_consumes_once(self):
        book = self.give("i1041", 2)
        args = dict(hero=5022, items=[dict(uid=book["uid"], count=1)])
        first = self.game.request(self.player, "exp-idem", "use_exp_book", args)
        again = self.game.request(self.player, "exp-idem", "use_exp_book", args)
        self.assertEqual(first, again)
        self.assertEqual(next(e for e in self.raw()["inventory"]["entries"]
                              if e["key"] == "i1041")["count"], 1)

    def test_battle_exp_is_not_affected_by_books(self):
        # Books only feed 神仙经验; 行者经验(修为) must stay unchanged.
        before = self.raw()["experience"]
        book = self.give("i1041")
        self.call("use_exp_book", hero=5022, items=[dict(uid=book["uid"], count=1)])
        self.assertEqual(self.raw()["experience"], before)


if __name__ == "__main__":
    unittest.main()
