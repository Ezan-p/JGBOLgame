import struct
import unittest

from game_config import load_config
from local_game.assets import Resources, catalog
from local_game.journey import build_journey


class JourneyTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.root = load_config()["game_root"]
        cls.data = build_journey(cls.root)

    def test_reference_screens_match_original_records(self):
        chapters = {c["id"]: c for c in self.data["chapters"]}
        self.assertEqual(chapters[46]["name"], "新任地藏")
        self.assertEqual(chapters[54]["name"], "暗访西海")
        stage = chapters[44]["stages"][-1]
        self.assertEqual((stage["id"], stage["name"], stage["exp"], stage["silver"]),
                         (4410, "猪八戒", 10435, 58327))
        self.assertEqual(stage["energy"], 1)
        self.assertEqual(stage["daily_limit"], 10)
        self.assertEqual([p["name"] for p in stage["drops"]], ["替身法", "冤魂乱舞"])
        self.assertEqual(stage["three_star"][0]["name"], "楮白枪")
        self.assertEqual(stage["boss"], 2)
        self.assertEqual(stage["sprite"], "chars/5/5_18.png")

    def test_complete_chapter_chains_and_local_save_mapping(self):
        chapters = self.data["chapters"]
        self.assertEqual(len(chapters), 67)
        self.assertEqual(sum(len(c["stages"]) for c in chapters), 597)
        self.assertEqual(sum("x" in c for c in chapters), 64)
        ids = set()
        for c in chapters:
            self.assertEqual(c["first"], c["stages"][0]["id"])
            for i, s in enumerate(c["stages"]):
                self.assertNotIn(s["id"], ids)
                ids.add(s["id"])
                self.assertEqual(s["map_id"], c["id"])
                self.assertEqual(s["next"], c["stages"][i+1]["id"] if i+1 < len(c["stages"]) else 0)
        # UI must map by original IDs, never reinterpret persisted local 1..10 IDs.
        local = catalog(self.root)["stages"]
        self.assertEqual(len(local), 10)
        self.assertTrue(all(s["original_id"] in ids for s in local))
        self.assertEqual([s["id"] for s in local], list(range(1, 11)))

    def test_all_art_and_reward_atlas_bounds(self):
        resources = Resources(self.root)
        self.assertEqual(self.data["missing_art"], [])
        for path in self.data["resources"]:
            self.assertTrue(resources.read(path))
        for c in self.data["chapters"]:
            for s in c["stages"]:
                for p in s["drops"] + s["three_star"] + s["first_drops"]:
                    icon = p.get("icon", {})
                    if "index" in icon:
                        w, h = struct.unpack(">II", resources.read(icon["file"])[16:24])
                        self.assertEqual(w % icon["columns"], 0)
                        self.assertEqual(h % icon["rows"], 0)
                        self.assertLessEqual(icon["index"], icon["columns"] * icon["rows"])
                        self.assertGreaterEqual(icon["index"], 1)

    def test_currency_consumables_and_stones_use_original_atlases(self):
        rewards = [p for c in self.data["chapters"] for p in c["prize"]]
        rewards += [p for c in self.data["chapters"] for s in c["stages"]
                    for p in s["drops"] + s["three_star"] + s["first_drops"]]
        gold = next(p for p in rewards if p["type"] == 11)
        self.assertEqual(gold["name"], "元宝")
        self.assertEqual(gold["icon"]["index"], 7)
        bun = next(p for p in rewards if p["type"] == 5 and p["id"] == 1022)
        self.assertEqual(bun["icon"]["file"], "items/all_daoju1.png")
        self.assertEqual(bun["icon"]["index"], 19)
        stone = next(p for p in rewards if p["type"] == 5 and p["id"] == 1091)
        self.assertEqual(stone["icon"]["file"], "items/stone.png")
        self.assertEqual(stone["icon"]["index"], 21 + stone["level"] - 1)
