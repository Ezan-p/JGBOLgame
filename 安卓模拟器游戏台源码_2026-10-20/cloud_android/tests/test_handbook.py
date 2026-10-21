import unittest

from game_config import load_config
from local_game.assets import Resources, catalog
from local_game.handbook import build_handbook, portrait


class HandbookTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.root = load_config()["game_root"]
        cls.book = build_handbook(cls.root)

    def test_reference_order_and_complete_roster(self):
        heroes = self.book["heroes"]
        self.assertEqual([h["id"] for h in heroes], catalog(self.root)["recruitable"])
        self.assertEqual([h["name"] for h in heroes[:18]], [
            "阎罗王", "牛魔王", "东海龙王", "沙悟净", "辟尘大王", "蝎子精",
            "哪吒", "红孩儿", "托塔天王", "铁扇公主", "六耳猕猴", "金翅大鹏王",
            "谛听", "青狮大王", "猪八戒", "白象大王", "二郎神", "地藏王菩萨",
        ])
        self.assertTrue(all(h["description"] and h["skill_description"] for h in heroes))
        self.assertEqual(sum(len(h["fates"]) for h in heroes), 690)

    def test_atlas_boundaries_and_updated_portrait(self):
        for quality in (2, 3, 4, 5):
            for resource, page, index in ((1, 1, 1), (50, 1, 50), (51, 2, 1), (61, 2, 11)):
                icon = portrait({"quality": quality, "resource": resource})
                self.assertTrue(icon["file"].endswith(f"head{page}.png"))
                self.assertEqual(icon["index"], index)
        rulai = next(h for h in self.book["heroes"] if h["id"] == 5053)
        self.assertEqual(rulai["icon"]["file"], "chars/5_all_head2.png")
        self.assertEqual(rulai["icon"]["index"], 11)

    def test_other_tabs_match_original_classification_and_resources(self):
        r = Resources(self.root)
        items = r.rows("csv_config/item_base.csv")
        self.assertEqual({i["id"] for i in self.book["equipment"]},
                         {int(i["type_id"]) for i in items if 2000 <= int(i["type_id"]) < 5000})
        self.assertEqual({i["id"] for i in self.book["essence"]},
                         {int(i["type_id"]) for i in items if i["main_type"] == "15"})
        self.assertEqual({i["id"] for i in self.book["spells"]},
                         {int(i["type_id"]) for i in r.rows("csv_config/skill_base.csv") if i["type_id"] != "1"})
        for name in self.book["resources"]:
            self.assertTrue(r.read(name).startswith(b"\x89PNG"))


if __name__ == "__main__":
    unittest.main()
