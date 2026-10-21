"""Original handbook ordering, portrait atlases and read-only reference data."""
import struct

from local_game.assets import Resources, catalog

# Original ui/lineupUI.lua side tabs: shenxian / hunpo / jingpo / common,
# plus v2/handbook/tj_btn* ("图鉴"). Original ui/handbookUI.lua uses the
# shenxian / equip / Label_spell / btn7 set for the catalogue page.
UI_RESOURCES = [
    "v2/introUI/intro_bkg.png", "v2/introUI/small_label.png", "v2/introUI/close1.png",
    "v2/packageUI/board_leftBkg.png", "v2/packageUI/board_edge1.png",
    "v2/packageUI/board_edge2.png", "v2/packageUI/board_mid_edge.png",
    "v2/packageUI/board_chain.png", "v2/handbook/name_frame.png", "v2/handbook/select.png",
    "v2/handbook/tj_btn1.png", "v2/handbook/tj_btn2.png",
    "v2/packageUI/xinxilan.png", "v2/introUI/stars.png", "v2/introUI/level.png",
    "v2/soulExchangeUI/btn_bkg1.png", "v2/charPositionUI/max_bkg.png",
    *["v2/CharaterUI/shenxian%d.png" % i for i in (1, 2)],
    *["v2/CharaterUI/hunpo%d.png" % i for i in (1, 2)],
    *["v2/CharaterUI/jingpo%d.png" % i for i in (1, 2)],
    *["v2/CharaterUI/common%d.png" % i for i in (1, 2)],
    *["v2/packageUI/equip%d.png" % i for i in (1, 2)],
    *["v2/packageUI/Label_spell%d.png" % i for i in (1, 2)],
    *["v2/handbook/btn7%d.png" % i for i in (1, 2)],
    *["v2/handbook/%s_txt.png" % s for s in ("cortege", "equip", "skill", "jp")],
]

# common_def.item_main_type: adaptive_spirit = 11, ext_skill = 15.
# cortege_base_0.csv category uses the same 1..5 order as the 界魂 sub_type.
SPIRIT_CATEGORIES = {1: "神", 2: "妖", 3: "人", 4: "魔", 5: "佛"}


def atlas(file, index, columns=10, rows=5):
    return dict(file=file, index=index, columns=columns, rows=rows)


def portrait(row):
    quality, resource = int(row["quality"]), int(row["resource"])
    group = str(quality) if quality >= 4 else "123"
    return atlas(f"chars/{group}_all_head{(resource - 1) // 50 + 1}.png", (resource - 1) % 50 + 1)


def build_handbook(game_root):
    resources = Resources(game_root)
    game = catalog(game_root)
    bases = {int(r["type_id"]): r for r in resources.rows("csv_config/cortege/cortege_base_0.csv")}
    skill_names = {int(r["type_id"]): r for r in resources.rows("csv_config/skill_name.csv")}
    # cortege_quality.csv: duplicate summon gain (spirit_convert_count) and
    # the souls required to conjure the character (spirit_compose_count).
    soul_quality = {int(r["cortege_quality"]): r
                    for r in resources.rows("csv_config/cortege_quality.csv")}
    fate_map = {}
    for row in resources.rows("csv_config/fate_config.csv"):
        fate_map.setdefault(int(row["cortege_type[effected_cortege]"]), []).append({
            "name": row["fate_name"], "description": row["fate_desc"],
        })
    heroes = []
    for ident in game["recruitable"]:
        base = bases[ident]
        hero = dict(game["heroes"][str(ident)])
        quality = soul_quality[int(base["quality"])]
        hero.update(icon=portrait(base), magic=int(base["base_max_magic"]),
                    skill_description=skill_names[hero["skill_id"]]["desc"],
                    fates=fate_map.get(ident, []),
                    soul_need=int(quality["spirit_compose_count"]),
                    soul_gain=int(quality["spirit_convert_count"]))
        heroes.append(hero)

    growth_max = {stat: max(h["growth"][stat] for h in heroes)
                  for stat in ("hp", "attack", "defense", "magic")}

    item_names = {int(r["Ftype_id"]): r for r in resources.rows("csv_config/item_name.csv")}
    equipment, essence, spirits = [], [], []
    for row in resources.rows("csv_config/item_base.csv"):
        ident, resource = int(row["type_id"]), int(row["resource"])
        if row["main_type"] == "11":
            # 五法界魂 (adaptive_spirit): 5 star levels x 5 categories.
            spirits.append(dict(
                id=ident, name=item_names[ident]["name"],
                description=item_names[ident]["desc"],
                quality=int(row["quality"]), sub_type=int(row["sub_type"]),
                category=SPIRIT_CATEGORIES[int(row["sub_type"])],
                icon=atlas(f"items/all_daoju{(resource - 1) // 64 + 1}.png",
                           (resource - 1) % 64 + 1, 8, 8)))
            continue
        if not (2000 <= ident < 5000 or row["main_type"] == "15"):
            continue
        item = dict(id=ident, name=item_names[ident]["name"], description=item_names[ident]["desc"],
                    quality=int(row["quality"]), main_type=int(row["main_type"]))
        if row["main_type"] == "15":
            # 精魄 (ext_skill) use the standalone skill/ext/<resource>.png art.
            item["icon"] = dict(file=f"skill/ext/{resource}.png")
            essence.append(item)
        else:
            item["icon"] = atlas(f"items/all_items{(resource - 1) // 100 + 1}.png",
                                 (resource - 1) % 100 + 1, 10, 10)
            equipment.append(item)
    equipment.sort(key=lambda r: (-r["quality"], r["main_type"], r["id"]))
    essence.sort(key=lambda r: (-r["quality"], r["id"]))
    # Original soulExchangeUI.adaptiveSpiritSort: quality desc, sub_type asc.
    spirits.sort(key=lambda r: (-r["quality"], r["sub_type"]))

    spells = []
    for row in resources.rows("csv_config/skill_base.csv"):
        ident = int(row["type_id"])
        if ident == 1:
            continue
        info = skill_names[ident]
        spells.append(dict(
            id=ident, name=info["name"], description=info["desc"],
            introduce=info["introduce"], quality=int(row["quality"]),
            icon=atlas("skill/skill_icons.png", int(row["resource"]), 10, 10),
            order=[int(row[k]) for k in (
                "use_mode(1-active，2-passive)", "effect_target(1-single，2-multi)",
                "effect_field(1-gongji，2-fangyu，3-magic，4-intensity，5-hp)")],
        ))
    spells.sort(key=lambda r: (-r["quality"], *r["order"], r["id"]))
    result = dict(heroes=heroes, growth_max=growth_max, equipment=equipment, spells=spells,
                  essence=essence, spirits=spirits)
    files = set(UI_RESOURCES)
    for entries in result.values():
        if not isinstance(entries, list):
            continue
        for entry in entries:
            icon = entry["icon"]
            data = resources.read(icon["file"])
            if not data.startswith(b"\x89PNG\r\n\x1a\n"):
                raise ValueError("Invalid handbook icon: " + icon["file"])
            width, height = struct.unpack(">II", data[16:24])
            if "index" in icon:
                if not 1 <= icon["index"] <= icon["columns"] * icon["rows"]:
                    raise ValueError("Atlas index out of bounds: " + str(entry["id"]))
                if width % icon["columns"] or height % icon["rows"]:
                    raise ValueError("Atlas dimensions do not match grid")
            files.add(icon["file"])
    # Keep this list with the fixture so APK packaging and tests share its exact dependencies.
    result["resources"] = sorted(files)
    return result
