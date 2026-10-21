import json
import tempfile
import unittest
from pathlib import Path

from game_config import load_config
from local_game.assets import catalog
from local_game.inventory import build_inventory
from local_game.service import Game, GameError
from local_game import training


class TrainingTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        root = load_config()["game_root"]
        cls.catalog = catalog(root)
        cls.catalog["inventory"] = build_inventory(root)

    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.game = Game(Path(self.temp.name) / "save.db", self.catalog)
        self.player = "training-test-player"
        self.counter = 0
        self.call("login")

    def call(self, op, **args):
        self.counter += 1
        return self.game.request(self.player, f"training-{self.counter:05}", op, args)

    def raw(self):
        with self.game.connect() as con:
            return json.loads(con.execute("SELECT state FROM players WHERE id=?",
                                          (self.player,)).fetchone()[0])

    def save(self, state):
        with self.game.connect() as con:
            con.execute("UPDATE players SET state=? WHERE id=?", (json.dumps(state), self.player))

    def hero(self, result, ident=5022):
        return next(h for h in result["state"]["heroes"] if h["id"] == ident)

    def set_training(self, ident=5022, **values):
        state = self.raw()
        data = state["training"][str(ident)]
        for key, value in values.items():
            data[key] = value
        self.save(state)

    def test_reference_potential_checkpoints(self):
        self.assertEqual(training.potential_total(15), 146)
        self.assertEqual(training.potential_total(95), 1370)
        self.assertEqual(training.potential_total(1), 30)
        self.assertLess(training.potential_total(1), training.potential_total(20))
        state = self.call("state")["state"]
        self.assertEqual(state["heroes"][0]["culture_point"], 30)

    def test_starter_peaches_normal_roll_and_accept(self):
        self.call("bag_claim")
        state = self.raw()
        peaches = next(e for e in state["inventory"]["entries"] if e["key"] == "i1001")
        self.assertEqual(peaches["count"], 169)
        result = self.call("train", hero=5022, kind=1)
        pending = self.hero(result)["train_pending"]
        self.assertEqual(pending["kind"], 1)
        self.assertTrue(1 <= pending["value"] <= 5)
        self.assertEqual(pending["cost"], {"peaches": 5, "gold": 0})
        peaches = next(e for e in self.raw()["inventory"]["entries"]
                       if e["key"] == "i1001")
        self.assertEqual(peaches["count"], 164)
        accepted = self.call("train_accept", hero=5022)
        hero = self.hero(accepted)
        stat = pending["increase"]
        self.assertEqual(hero[stat + "_plus"], pending["value"])
        self.assertEqual(hero["culture_point"], 30 - pending["value"])
        self.assertIsNone(hero["train_pending"])

    def test_ten_times_guard_matches_original_client(self):
        self.call("bag_claim")
        self.set_training(potential=0, bonus={"hp": 0, "attack": 0,
                                              "defense": 0, "magic": 0})
        with self.assertRaises(GameError):
            self.call("train", hero=5022, kind=2)
        self.set_training(potential=0, bonus={"hp": 20, "attack": 20,
                                              "defense": 0, "magic": 0})
        result = self.call("train", hero=5022, kind=2)
        pending = self.hero(result)["train_pending"]
        self.assertEqual(pending["rolls"], 10)
        self.assertTrue(10 <= pending["value"] <= 50)
        self.assertEqual(pending["cost"], {"peaches": 50, "gold": 0})

    def test_intensive_uses_gold_and_requires_thirty_potential(self):
        self.call("bag_claim")
        self.set_training(potential=29)
        with self.assertRaises(GameError):
            self.call("train", hero=5022, kind=4)
        self.set_training(potential=30)
        before = self.raw()["gold"]
        result = self.call("train", hero=5022, kind=4)
        pending = self.hero(result)["train_pending"]
        self.assertTrue(30 <= pending["value"] <= 150)
        self.assertEqual(pending["cost"], {"peaches": 0, "gold": 10})
        self.assertEqual(result["state"]["gold"], before - 10)

    def test_empty_pool_redistributes_between_stats(self):
        self.call("bag_claim")
        self.set_training(potential=0, bonus={"hp": 100, "attack": 100,
                                              "defense": 100, "magic": 100})
        result = self.call("train", hero=5022, kind=1)
        pending = self.hero(result)["train_pending"]
        self.assertEqual(pending["potential_used"], 0)
        self.assertIn(pending["decrease"], training.STATS)
        self.assertNotEqual(pending["decrease"], pending["increase"])
        before_total = 400
        accepted = self.hero(self.call("train_accept", hero=5022))
        after_total = sum(accepted[stat + "_plus"] for stat in training.STATS)
        self.assertEqual(after_total, before_total)
        self.assertEqual(accepted["culture_point"], 0)

    def test_giveup_keeps_stats_and_potential_but_consumes_cost(self):
        self.call("bag_claim")
        before = self.hero(self.call("state"))
        result = self.call("train", hero=5022, kind=1)
        self.assertIsNotNone(self.hero(result)["train_pending"])
        given = self.hero(self.call("train_giveup", hero=5022))
        self.assertIsNone(given["train_pending"])
        for key in ("culture_point", "hp_plus", "attack_plus",
                    "defense_plus", "magic_plus", "hp", "attack"):
            self.assertEqual(given[key], before[key])

    def test_level_up_adds_only_the_new_potential_difference(self):
        state = self.raw()
        state["heroes"]["5022"] = 15
        state["training"]["5022"].update(level=15, potential=100,
                                         bonus={"hp": 0, "attack": 0,
                                                "defense": 0, "magic": 0},
                                         potential_init_ok=True)
        self.save(state)
        upgraded = self.hero(self.call("upgrade", hero=5022))
        self.assertEqual(upgraded["level"], 16)
        self.assertEqual(upgraded["culture_point"], 100 + 15)

    def test_training_bonus_is_part_of_roster_stats(self):
        self.call("bag_claim")
        baseline = self.hero(self.call("state"))
        state = self.raw()
        state["training"]["5022"]["bonus"]["attack"] = 100
        self.save(state)
        hero = self.hero(self.call("state"))
        self.assertEqual(hero["attack"], baseline["attack"] + 100)
        self.assertEqual(hero["attack_plus"], 100)


if __name__ == "__main__":
    unittest.main()

