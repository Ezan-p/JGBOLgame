import json
import tempfile
import unittest
from pathlib import Path

from game_config import load_config
from local_game.assets import catalog, Resources
from local_game.inventory import build_inventory
from local_game.lineup import build_lineup
from local_game.service import Game, GameError


class LineupTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.root = load_config()["game_root"]
        cls.catalog = catalog(cls.root)
        cls.inventory = build_inventory(cls.root)

    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.game = Game(Path(self.tmp.name) / "save.db", self.catalog)
        self.player = "lineup-test-player"
        self.game.request(self.player, "login-request", "login", {})

    def request(self, ident, op, **args):
        return self.game.request(self.player, ident, op, args)

    def test_swap_persists_and_retry_does_not_swap_back(self):
        before = self.request("before-request", "state")["state"]
        result = self.request("swap-request", "lineup_swap", source=1, target=2)
        self.assertEqual(result["state"]["lineup"], before["lineup"][::-1])
        self.assertEqual(result, self.request("swap-request", "lineup_swap", source=1, target=2))
        loaded = Game(self.game.db, self.catalog).request(self.player, "reload-request", "state", {})
        self.assertEqual(loaded["state"]["lineup"], result["state"]["lineup"])
        for key in ("silver", "experience", "heroes", "wins", "battle_count"):
            self.assertEqual(loaded["state"][key], before[key])
        battle = self.request("battle-request", "battle", stage=1)["battle"]
        self.assertEqual(battle["units"][0]["id"], before["lineup"][1])

    def test_replace_atomic_at_capacity_and_append(self):
        ids = [i for i in self.catalog["recruitable"] if i not in (5022, 5004)][:3]
        with self.game.connect() as con:
            state = self.game.initial()
            state["heroes"].update({str(i): 1 for i in ids})
            state["lineup"] += ids[:2]
            con.execute("UPDATE players SET state=? WHERE id=?", (json.dumps(state), self.player))
        result = self.request("replace-request", "lineup_replace", slot=2, hero=ids[2])
        self.assertEqual(result["state"]["lineup"], [5022, ids[2], *ids[:2]])
        self.assertEqual(len(result["state"]["heroes"]), 5)
        self.assertEqual(result["state"]["silver"], 1200)
        self.assertEqual(result, self.request("replace-request", "lineup_replace", slot=2, hero=ids[2]))
        self.request("rest-request", "lineup", hero=ids[1])
        added = self.request("append-request", "lineup_replace", slot=4, hero=5004)
        self.assertEqual(added["state"]["lineup"], [5022, ids[2], ids[0], 5004])

    def test_invalid_mutations_leave_lineup_unchanged(self):
        for i, (op, args) in enumerate([
            ("lineup_swap", {"source": 0, "target": 1}),
            ("lineup_swap", {"source": 1, "target": 3}),
            ("lineup_swap", {"source": True, "target": 1}),
            ("lineup_replace", {"slot": 1, "hero": 5022}),
            ("lineup_replace", {"slot": 1, "hero": 5053}),
            ("lineup_replace", {"slot": 5, "hero": 5004}),
        ]):
            with self.assertRaises(GameError):
                self.request("invalid-request-%d" % i, op, **args)
        self.assertEqual(self.request("after-request", "state")["state"]["lineup"], [5022, 5004])

    def test_original_layout_and_name_atlases(self):
        data = build_lineup(self.root)
        self.assertEqual(len(data["positions"]), 8)
        self.assertEqual(data["positions"][:4], [[-.3, .02], [.37, .02], [.03, .37], [.03, -.34]])
        self.assertEqual(len(data["heroes"]), 166)
        r = Resources(self.root)
        for h in data["heroes"].values():
            self.assertTrue(r.read(h["name_icon"]["file"]).startswith(b"\x89PNG"))
            self.assertTrue(1 <= h["name_icon"]["index"] <= 50)
        self.assertTrue(all(len(s["sha256"]) == 64 for s in data["sources"]))

    def test_spell_intro_assets_and_level_formula(self):
        data = build_lineup(self.root)
        resources = set(data["resources"])
        r = Resources(self.root)
        for name in (
            "v2/charPositionUI/skill_small_bkg.png",
            "v2/charPositionUI/small_arrow.png",
            "v2/charPositionUI/detail1.png", "v2/charPositionUI/detail2.png",
            "v2/charPositionUI/change1.png", "v2/charPositionUI/change2.png",
            "v2/newIntroUI/upgrade1.png", "v2/newIntroUI/upgrade2.png",
            "v2/enhanceUI/up_2.png",
            "v2/introUI/skill_strong.png", "v2/introUI/level.png",
        ):
            self.assertIn(name, resources)
            self.assertTrue(r.read(name).startswith(b"\x89PNG"))
        skill = self.inventory["items"]["s22"]
        self.assertEqual(skill["name"], "指地成钢")
        original = skill["original"]
        self.assertEqual(original["effect_field"], "2")
        # Original createSkillLabel: fangyu_plus + upgrade_plus * (level - 1).
        self.assertAlmostEqual(float(original["fangyu_plus"])
                               + float(original["upgrade_plus"]) * 7, 27.5)

    def test_eight_slot_save_sparse_swap_and_removal_preserve_pairing(self):
        with self.game.connect() as con:
            state = self.game.initial()
            state['lineup_capacity'] = 8
            state['heroes']['5034'] = 1
            con.execute('UPDATE players SET state=? WHERE id=?', (json.dumps(state),self.player))
        result = self.request('eight-replace','lineup_replace',slot=8,hero=5034)['state']
        self.assertEqual(result['lineup'], [5022,5004,0,0,0,0,0,5034])
        result = self.request('eight-swap','lineup_swap',source=1,target=5)['state']
        self.assertEqual(result['lineup'], [0,5004,0,0,5022,0,0,5034])
        result = self.request('eight-remove','lineup',hero=5004)['state']
        self.assertEqual(result['lineup'], [0,0,0,0,5022,0,0,5034])
        report = self.request('eight-battle','battle',stage=1)['battle']
        self.assertEqual([u['slot'] for u in report['units'] if u['side']==0],[5,8])
        for e in report['events'][:2]: self.assertEqual(e['kind'],'enter')
        self.request('eight-remove-last-but-one','lineup',hero=5022)
        with self.assertRaises(GameError): self.request('eight-remove-last','lineup',hero=5034)
