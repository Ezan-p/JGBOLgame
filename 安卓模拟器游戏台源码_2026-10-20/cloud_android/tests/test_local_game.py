import concurrent.futures
import json
import tempfile
import threading
import unittest
import urllib.error
import urllib.parse
import urllib.request
from http.server import ThreadingHTTPServer
from pathlib import Path

from game_config import load_config
from local_game.assets import Resources, catalog, decode_index, encode_index
from local_game.service import Game, GameError, handler


class LocalGameTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.catalog = catalog(load_config()["game_root"])

    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.database = Path(self.temp.name) / "save.sqlite3"
        self.game = Game(self.database, self.catalog)
        self.player = "test-player-01"
        self.game.request(self.player, "request-login-01", "login", {})

    def state(self):
        with self.game.connect() as db:
            return json.loads(db.execute("SELECT state FROM players WHERE id=?", (self.player,)).fetchone()[0])

    def test_real_resource_index_roundtrip_and_catalog_sprites(self):
        directory = load_config()["game_root"] / "assets/release_"
        header, index = decode_index((directory / "index.txt").read_bytes())
        self.assertEqual(decode_index(encode_index(header, index)), (header, index))
        resources = Resources(load_config()["game_root"])
        for hero in self.catalog["heroes"].values():
            self.assertTrue(resources.read(hero["sprite"]).startswith(b"\x89PNG"))
        self.assertEqual(len(self.catalog["stages"]), 597)

    def test_complete_updated_handbook_and_new_character(self):
        resources = Resources(load_config()["game_root"])
        rows = resources.rows("csv_config/cortege/cortege_base_0.csv")
        expected = {int(r["type_id"]) for r in rows
                    if 100 < int(r["type_id"]) < 6000 and int(r["quality"]) > 1 and r["book_hide"] == "1"}
        self.assertEqual(set(self.catalog["recruitable"]), expected)
        self.assertEqual(len(expected), 166)
        self.assertEqual(self.catalog["heroes"]["5053"]["name"], "如来佛祖")
        self.assertIn(5046, expected)
        self.assertNotIn(1, expected)
        self.assertNotIn(1020, expected)
        self.assertNotIn(6001, expected)
        view = self.game.view(self.state())
        self.assertEqual(len(view["recruits"]), 164)
        self.assertTrue(all(hero["cost"] == 600 for hero in view["recruits"]))

    def test_every_hero_can_be_recruited_persisted_and_used_in_battle(self):
        state = self.state()
        remaining = set(self.catalog["recruitable"]) - {int(i) for i in state["heroes"]}
        # Isolated test fixture only: real players still earn their silver.
        state["silver"] = len(remaining) * 600
        with self.game.connect() as con:
            con.execute("UPDATE players SET state=? WHERE id=?", (json.dumps(state), self.player))
        for ident in sorted(remaining):
            with self.subTest(hero=ident):
                reply = self.game.request(self.player, f"all-recruit-{ident}", "recruit", {"hero": ident})
                self.assertNotIn(ident, [h["id"] for h in reply["state"]["recruits"]])
                self.assertLessEqual(len(reply["state"]["lineup"]), 4)
                with self.assertRaises(GameError):
                    self.game.request(self.player, f"duplicate-recruit-{ident}", "recruit", {"hero": ident})
        resumed = Game(self.database, self.catalog)
        reply = resumed.request(self.player, "after-all-restart", "state", {})
        self.assertEqual(reply["state"]["silver"], 0)
        self.assertEqual(reply["state"]["recruits"], [])
        self.assertEqual({h["id"] for h in reply["state"]["heroes"]}, set(self.catalog["recruitable"]))
        for ident in self.catalog["recruitable"]:
            state = resumed.initial()
            state["heroes"] = {str(ident): 1}
            state["lineup"] = [ident]
            battle = resumed.battle(state, 1)
            self.assertTrue(battle["events"])
            self.assertEqual(battle["units"][0]["id"], ident)

    def test_mutation_persists_across_service_restart_and_is_idempotent(self):
        reply = self.game.request(self.player, "upgrade-once-01", "upgrade", {"hero": 5022})
        resumed = Game(self.database, self.catalog)
        self.assertEqual(resumed.request(self.player, "upgrade-once-01", "upgrade", {"hero": 5022}), reply)
        state = self.state()
        self.assertEqual(state["heroes"]["5022"], 2)
        self.assertEqual(state["silver"], 1120)
        with self.assertRaises(GameError):
            resumed.request(self.player, "upgrade-once-01", "upgrade", {"hero": 5004})

    def test_rejected_requests_do_not_change_save(self):
        before = self.state()
        for op, args in [("battle", {"stage": 10}), ("upgrade", {"hero": 9999}),
                         ("upgrade", {"hero": True}), ("recruit", {"hero": 5004}),
                         ("battle", {"stage": -1}), ("give-money", {"amount": 99999})]:
            with self.assertRaises(GameError):
                self.game.request(self.player, "invalid-" + op, op, args)
            self.assertEqual(self.state(), before)

    def test_parallel_duplicate_battle_settles_once(self):
        def request(_):
            return self.game.request(self.player, "battle-once-01", "battle", {"stage": 1})
        with concurrent.futures.ThreadPoolExecutor(max_workers=4) as pool:
            results = list(pool.map(request, range(4)))
        self.assertTrue(all(r == results[0] for r in results))
        battle = results[0]["battle"]
        state = self.state()
        self.assertTrue(battle["won"])
        self.assertTrue(battle["events"])
        self.assertEqual(state["battle_count"], 1)
        self.assertEqual(state["energy"], 59)
        self.assertEqual(state["unlocked"], 2)
        self.assertEqual(state["silver"], 1200 + battle["silver"])
        self.assertTrue(battle["first_clear"])
        replay = self.game.request(self.player, "battle-again-02", "battle", {"stage": 1})
        self.assertFalse(replay["battle"]["first_clear"])
        self.assertEqual(replay["battle"]["silver"] * 2, battle["silver"])

    def test_roster_limits_and_purchased_hero_persist(self):
        reply = self.game.request(self.player, "recruit-test-01", "recruit", {"hero": 5018})
        self.assertEqual(len(reply["state"]["lineup"]), 3)
        self.game.request(self.player, "recruit-test-02", "recruit", {"hero": 5023})
        self.assertEqual(len(self.state()["lineup"]), 4)
        state = self.state()
        state["heroes"]["5034"] = 1  # A fifth owned hero in this isolated fixture.
        with self.game.connect() as con:
            con.execute("UPDATE players SET state=? WHERE id=?", (json.dumps(state), self.player))
        with self.assertRaises(GameError):
            self.game.request(self.player, "lineup-full-01", "lineup", {"hero": 5034})
        self.game.request(self.player, "lineup-leave-01", "lineup", {"hero": 5004})
        self.game.request(self.player, "lineup-enter-01", "lineup", {"hero": 5034})
        self.assertEqual(self.state()["lineup"], [5022, 5018, 5023, 5034])
        self.assertEqual(self.state()["silver"], 0)
        with self.assertRaises(GameError):
            self.game.request(self.player, "too-expensive-01", "upgrade", {"hero": 5022})

    def test_http_key_required_and_actual_roundtrip(self):
        server = ThreadingHTTPServer(("127.0.0.1", 0), handler(self.game, "local-test-key"))
        thread = threading.Thread(target=server.serve_forever, daemon=True)
        thread.start()
        try:
            base = f"http://127.0.0.1:{server.server_port}"
            with self.assertRaises(urllib.error.HTTPError) as error:
                urllib.request.urlopen(base + "/rpc?op=login", timeout=2)
            self.assertEqual(error.exception.code, 403)
            query = urllib.parse.urlencode({
                "key": "local-test-key", "op": "upgrade", "args": '{"hero":5022}',
                "player": self.player, "request": "http-upgrade-01",
            })
            with urllib.request.urlopen(base + "/rpc?" + query, timeout=2) as response:
                data = json.load(response)
            self.assertTrue(data["ok"])
            self.assertEqual(self.state()["heroes"]["5022"], 2)
        finally:
            server.shutdown()
            server.server_close()
            thread.join(timeout=2)

    def test_ten_stage_campaign_with_earned_currency(self):
        self.game.request(self.player, "campaign-recruit", "recruit", {"hero": 5018})
        for stage in range(1, 11):
            # Level up using the previous battles' currency, no injected balances.
            if stage in (3, 6, 9):
                for hero in (5022, 5004, 5018):
                    self.game.request(self.player, f"campaign-upgrade-{stage}-{hero}",
                                      "upgrade", {"hero": hero})
            reply = self.game.request(self.player, f"campaign-battle-{stage}", "battle", {"stage": stage})
            self.assertTrue(reply["battle"]["won"], f"Stage {stage} should be playable")
        self.assertEqual(len(self.state()["wins"]), 10)
        self.assertEqual(self.state()["energy"], 50)


if __name__ == "__main__":
    unittest.main()
