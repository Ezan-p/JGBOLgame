import concurrent.futures
import copy
import json
import tempfile
import unittest
from collections import Counter
from pathlib import Path

from game_config import load_config
from local_game.assets import catalog
from local_game.inventory import build_inventory, grant, value
from local_game.service import Game, GameError


class InventoryTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        root = load_config()["game_root"]
        cls.catalog = catalog(root)
        cls.inventory = build_inventory(root)
        cls.catalog["inventory"] = cls.inventory

    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.game = Game(Path(self.temp.name)/"save.db", self.catalog)
        self.player = "inventory-test"
        self.counter = 0
        self.call("login")

    def call(self, op, **args):
        self.counter += 1
        return self.game.request(self.player, f"request-{self.counter:05}", op, args)

    def raw(self):
        with self.game.connect() as con:
            return json.loads(con.execute("SELECT state FROM players WHERE id=?", (self.player,)).fetchone()[0])

    def save(self, state):
        with self.game.connect() as con:
            con.execute("UPDATE players SET state=? WHERE id=?", (json.dumps(state), self.player))

    def entry(self, key):
        return next(e for e in self.raw()["inventory"]["entries"] if e["key"] == key)

    def test_extraction_counts_icons_and_reference_examples(self):
        items = self.inventory["items"]
        self.assertEqual(Counter(x["category"] for x in items.values()),
                         {1: 44, 2: 40, 3: 25, 4: 64, 5: 3, 6: 717})
        self.assertEqual(self.inventory["missing_icons"], [])
        for key, name in (("i4002", "筋斗云"), ("i4012", "曼陀罗"), ("i4013", "定风珠"),
                          ("s43", "火眼金睛"), ("s42", "一气化三清"), ("i10000", "精魄石")):
            self.assertEqual(items[key]["name"], name)
        self.assertEqual(value(items["s43"], 10), 32.6)
        self.assertEqual(value(items["s42"], 10), 32.5)
        self.assertEqual(items["i10301"]["icon"]["file"], "v2/wakeUI/icon/301.png")
        self.assertEqual(items["i1142"]["icon"]["file"], "v2/destinyUI/card.png")
        self.assertEqual(items["i1094"]["icon"]["file"], "v2/CardUI/card_bkg.png")

    def test_migration_claim_idempotency_and_concurrency(self):
        before = self.raw()
        state = self.call("state")["state"]
        self.assertEqual(state["inventory"], {"claimed": False, "entries": []})
        with concurrent.futures.ThreadPoolExecutor(4) as pool:
            results = list(pool.map(lambda _: self.game.request(
                self.player, "same-claim-request", "bag_claim", {}), range(4)))
        self.assertTrue(all(x == results[0] for x in results))
        after = self.raw()
        for field in ("silver", "heroes", "lineup", "wins", "battle_count", "experience"):
            self.assertEqual(before[field], after[field])
        with self.assertRaises(GameError):
            self.call("bag_claim")
        resumed = Game(self.game.db, self.catalog)
        self.assertEqual(resumed.view(after)["inventory"], results[0]["state"]["inventory"])

    def test_equipment_upgrade_socket_combat_and_unload(self):
        self.call("bag_claim")
        weapon = self.entry("i2006")
        gem = self.entry("i1090")
        base = self.game.hero(5022, 1)
        state = self.call("bag_equip", uid=weapon["uid"], hero=5022)["state"]
        equipped = next(h for h in state["heroes"] if h["id"] == 5022)
        self.assertGreater(equipped["attack"], base["attack"])
        self.call("bag_upgrade", uid=weapon["uid"])
        self.call("bag_socket", uid=weapon["uid"], gem=gem["uid"])
        upgraded = self.game.hero(5022, 1, self.raw())
        self.assertGreater(upgraded["attack"], equipped["attack"])
        shown = next(e for e in self.game.view(self.raw())["inventory"]["entries"] if e["uid"] == weapon["uid"])
        raw_attack = self.catalog["heroes"]["5022"]["attack"]
        self.assertEqual(upgraded["attack"], round((raw_attack+shown["value"])*1.065))
        report = self.call("battle", stage=1)["battle"]
        self.assertEqual(report["units"][0]["attack"], upgraded["attack"])
        self.call("bag_unsocket", uid=weapon["uid"])
        self.assertEqual(self.entry("i1090")["count"], 3)
        self.call("bag_equip", uid=weapon["uid"], hero=0)
        self.assertEqual(self.game.hero(5022, 1, self.raw())["attack"], base["attack"])

    def test_two_extra_spell_positions_preserve_native_skill(self):
        self.call("bag_claim")
        a, b = self.entry("s42"), self.entry("s43")
        self.call("bag_equip", uid=a["uid"], hero=5022, equip_pos=2)
        self.call("bag_equip", uid=b["uid"], hero=5022, equip_pos=3)
        base = self.game.hero(5022, 1)
        hero = self.game.hero(5022, 1, self.raw())
        self.assertEqual(hero["attack"], round(self.catalog["heroes"]["5022"]["attack"]*1.275))
        self.assertEqual(hero["skill_id"], base["skill_id"])
        active = self.entry("s202")
        self.call("bag_equip", uid=active["uid"], hero=5022, equip_pos=2)
        self.assertEqual(self.entry("s42")["hero"], 0)
        self.assertEqual(self.entry("s43")["hero"], 5022)
        self.assertEqual(self.game.hero(5022, 1, self.raw())["skill_id"], base["skill_id"])
        self.assertNotIn("skill_factor", self.game.hero(5022, 1, self.raw()))
        self.assertEqual([(s["id"],s["position"]) for s in self.game.hero(5022, 1, self.raw())["spells"]], [(45,1),(202,2),(43,3)])
        self.call("bag_equip", uid=active["uid"], hero=5004, equip_pos=3)
        self.assertEqual(self.entry("s202")["hero"], 5004)
        resumed=Game(self.game.db,self.catalog).view(self.raw())
        self.assertEqual(next(e for e in resumed["inventory"]["entries"] if e["uid"]==active["uid"])["equip_pos"],3)

    def test_spell_native_duplicate_and_invalid_positions_are_atomic(self):
        self.call("bag_claim")
        a = self.entry("s43")
        self.call("bag_equip",uid=a["uid"],hero=5022,equip_pos=2)
        state=self.raw()
        grant(state,"s43",catalog=self.inventory)
        native=self.catalog["heroes"]["5022"]["skill_id"]
        grant(state,"s"+str(native),catalog=self.inventory)
        self.save(state)
        copy_uid=state["inventory"]["entries"][-2]["uid"]
        native_uid=state["inventory"]["entries"][-1]["uid"]
        for uid,pos in [(copy_uid,3),(native_uid,3),(a["uid"],1),(a["uid"],True),(a["uid"],4)]:
            before=self.raw()
            with self.assertRaises(GameError):self.call("bag_equip",uid=uid,hero=5022,equip_pos=pos)
            self.assertEqual(self.raw(),before)
        # A different copy may replace the same spell in its existing position.
        self.call("bag_equip",uid=copy_uid,hero=5022,equip_pos=2)
        self.assertEqual(self.entry("s43")["hero"],0)

    def test_legacy_spell_positions_are_stable_and_read_only(self):
        self.call("bag_claim")
        s=self.raw()
        for e in s["inventory"]["entries"]:
            if e["key"] in ("s202","s43"):e["hero"]=5022
        self.save(s)
        v=self.game.view(s)
        worn=[e for e in v["inventory"]["entries"] if e["hero"]==5022]
        self.assertEqual([e["equip_pos"] for e in worn],[2,3])
        self.assertEqual(self.raw(),s)
        self.assertEqual(next(h for h in v["heroes"] if h["id"]==5022)["skill_id"],self.catalog["heroes"]["5022"]["skill_id"])

    def test_compose_use_smelt_and_purchase(self):
        self.call("bag_claim")
        gem = self.entry("i1090")
        self.call("bag_compose", uid=gem["uid"])
        self.assertEqual((self.entry("i1090")["count"], self.entry("i1090")["level"]), (1, 2))
        self.call("bag_compose", uid=self.entry("i7006")["uid"])
        self.assertEqual(len([e for e in self.raw()["inventory"]["entries"] if e["key"] == "i2006"]), 2)
        before = self.raw()
        with self.assertRaises(GameError):
            self.call("bag_use", uid=self.entry("i1020")["uid"])
        self.assertEqual(self.raw(), before)
        state = self.raw();state["energy"] = 50;self.save(state)
        self.call("bag_use", uid=self.entry("i1020")["uid"])
        self.assertEqual(self.raw()["energy"], 55)
        self.call("bag_use", uid=self.entry("i1024")["uid"], hero=5022)
        self.assertEqual(self.raw()["heroes"]["5022"], 2)
        self.call("bag_smelt", uid=self.entry("i4002")["uid"])
        self.assertEqual(self.entry("i10000")["count"], 15)
        self.call("bag_buy", key="i4002")
        self.assertEqual(self.entry("i4002")["level"], 1)
        old = self.raw()["silver"]
        self.call("bag_use", uid=self.entry("i10000")["uid"])
        self.assertEqual(self.raw()["silver"], old+20)

    def test_rejected_mutations_are_atomic_and_cross_player_safe(self):
        self.call("bag_claim")
        weapon, gem = self.entry("i2006"), self.entry("i1091")
        for op, args in [
            ("bag_socket", dict(uid=weapon["uid"], gem=gem["uid"])),
            ("bag_equip", dict(uid=weapon["uid"], hero=999999)),
            ("bag_equip", dict(uid=True, hero=5022)),
            ("bag_upgrade", dict(uid=-1)),
            ("bag_buy", dict(key="i1001")),
            ("bag_compose", dict(uid=weapon["uid"])),
        ]:
            before = self.raw()
            with self.assertRaises(GameError):
                self.call(op, **args)
            self.assertEqual(self.raw(), before)
        self.call("bag_equip", uid=weapon["uid"], hero=5022)
        with self.assertRaises(GameError):
            self.call("bag_smelt", uid=weapon["uid"])
        self.game.request("second-player", "second-player-login", "login", {})
        with self.assertRaises(GameError):
            self.game.request("second-player", "second-player-equip", "bag_equip",
                              dict(uid=weapon["uid"], hero=5022))
        state = self.raw();state["silver"] = 0;self.save(state)
        before = self.raw()
        with self.assertRaises(GameError):
            self.call("bag_upgrade", uid=weapon["uid"])
        self.assertEqual(self.raw(), before)

    def test_level_caps_and_all_composable_fragments(self):
        for item in self.inventory["items"].values():
            if item["action"] == "fragment":
                self.assertLessEqual(self.inventory["items"][f'i{item["id"]-5000}']["category"], 3)
        self.call("bag_claim")
        state = self.raw()
        for e in state["inventory"]["entries"]:
            if e["key"] == "s43":
                e["level"] = 10
        self.save(state)
        before = self.raw()
        with self.assertRaises(GameError):
            self.call("bag_upgrade", uid=self.entry("s43")["uid"])
        self.assertEqual(self.raw(), before)
