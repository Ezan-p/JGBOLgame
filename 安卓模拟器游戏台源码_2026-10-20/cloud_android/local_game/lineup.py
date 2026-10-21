"""Reproducible charPositionUI assets and layout from APK 1061 / update 1263."""
from local_game.assets import Resources
from local_game.handbook import build_handbook


def build_lineup(game_root):
    r = Resources(game_root)
    book = build_handbook(game_root)
    heroes = {}
    for entry in book["heroes"]:
        hero = dict(entry)
        hero["name_icon"] = {**hero["icon"], "file": hero["icon"]["file"].replace("_head", "_name")}
        heroes[str(hero["id"])] = hero
    files = {n for n in r.names() if n.startswith("v2/charPositionUI/") and n.endswith(".png")}
    files.update([
        "v2/CharaterUI/stars.png", "v2/introUI/stars.png", "v2/CharaterUI/xiaguang.png",
        "v2/CharaterUI/expbar1.png", "v2/CharaterUI/expbar2.png",
        "v2/introUI/yuanfen_label.png", "v2/introUI/level.png",
        "v2/introUI/skill_strong.png",
        "v2/newIntroUI/upgrade1.png", "v2/newIntroUI/upgrade2.png",
        "v2/enhanceUI/up_2.png",
        "v2/enhanceUI/equipEnhance.png", "v2/enhanceUI/mid3.png",
        "v2/enhanceUI/mid2.png", "v2/enhanceUI/en_1.png", "v2/enhanceUI/en_2.png",
        "v2/enhanceUI/continue_1.png", "v2/enhanceUI/continue_2.png",
        "v2/common/frame1.png", "v2/common/frame2.png", "v2/common/small_label.png",
        "v2/common/close1.png", "v2/common/close2.png",
        "v2/newIntroUI/star_bkg.png",
        "v2/introUI/talent_label.png", "v2/introUI/small_label.png",
        "v2/introUI/intro_label_ql.png", "v2/introUI/introBkg2.png",
        "v2/introUI/rightBkg.png", "v2/introUI/floorHighLight.png",
        "v2/introUI/property_bkg.png", "v2/introUI/property_mid.png",
        "v2/introUI/property_up.png", "v2/introUI/close1.png",
        "v2/trainingUI/training1.png", "v2/trainingUI/training2.png",
        "v2/trainingUI/stats_bkg.png", "v2/trainingUI/choose_frame.png",
        "v2/trainingUI/choose.png", "v2/trainingUI/data_bkg.png",
        "v2/trainingUI/title_bkg.png", "v2/trainingUI/resultHZ.png",
        "v2/trainingUI/accept1.png", "v2/trainingUI/accept2.png",
        "v2/trainingUI/giveup1.png", "v2/trainingUI/giveup2.png",
        "v2/trainingUI/up.png", "v2/trainingUI/down.png",
        "v2/introUI/left_scroll.png", "v2/introUI/right_scroll.png",
        "v2/playerInfoUI/bkg_mid.png", "v2/playerInfoUI/bkg_frame.png",
        "v2/money_gold.png",
        "v2/buttons/inherit1.png", "v2/buttons/inherit2.png",
        "v2/multi-selectUI/back1.png", "v2/multi-selectUI/back2.png",
        "v2/CharaterUI/hongdian.png", "v2/CharaterUI/underline1.png",
        "v2/CharaterUI/underline2.png", "v2/soulExchangeUI/btn_bkg1.png",
        *["v2/introUI/" + n + ".png" for n in ("health", "damage", "defence", "mana")],
    ])
    files.update(h["name_icon"]["file"] for h in heroes.values())
    for file in files:
        if not r.read(file).startswith(b"\x89PNG"):
            raise ValueError("Invalid lineup image: " + file)
    sources = ["lua/ui/charPositionUI.lua", "lua/data.lua", "csv_config/fate_config.csv"]
    return {
        "heroes": heroes, "growth_max": book["growth_max"], "spells": book["spells"],
        "positions": [[-.3, .02], [.37, .02], [.03, .37], [.03, -.34],
                      [-.54, 0], [.12, 0], [-.21, .37], [-.21, -.36]],
        "resources": sorted(files),
        "sources": [r.source(n) for n in sources],
    }
