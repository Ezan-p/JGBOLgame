"""Original handbook ordering, portrait atlases and read-only reference data."""
import struct

from local_game.assets import Resources, catalog

UI_RESOURCES = [
    "v2/introUI/intro_bkg.png", "v2/introUI/small_label.png", "v2/introUI/close1.png",
    "v2/packageUI/board_leftBkg.png", "v2/packageUI/board_edge1.png",
    "v2/packageUI/board_edge2.png", "v2/packageUI/board_mid_edge.png",
    "v2/packageUI/board_chain.png", "v2/handbook/name_frame.png", "v2/handbook/select.png",
    "v2/soulExchangeUI/btn_bkg1.png",
    *["v2/CharaterUI/shenxian%d.png" % i for i in (1, 2)],
    *["v2/packageUI/equip%d.png" % i for i in (1, 2)],
    *["v2/packageUI/Label_spell%d.png" % i for i in (1, 2)],
    *["v2/handbook/btn7%d.png" % i for i in (1, 2)],
    *["v2/handbook/%s_txt.png" % s for s in ("cortege", "equip", "skill", "jp")],
]


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
    fate_map = {}
    for row in resources.rows("csv_config/fate_config.csv"):
        fate_map.setdefault(int(row["cortege_type[effected_cortege]"]), []).append({
            "name": row["fate_name"], "description": row["fate_desc"],
        })
    heroes = []
    for ident in game["recruitable"]:
        base = bases[ident]
        hero = dict(game["heroes"][str(ident)])
        hero.update(icon=portrait(base), magic=int(base["base_max_magic"]),
                    skill_description=skill_names[hero["skill_id"]]["desc"],
                    fates=fate_map.get(ident, []))
        heroes.append(hero)

    item_names = {int(r["Ftype_id"]): r for r in resources.rows("csv_config/item_name.csv")}
    equipment, essence = [], []
    for row in resources.rows("csv_config/item_base.csv"):
        ident, resource = int(row["type_id"]), int(row["resource"])
        if not (2000 <= ident < 5000 or row["main_type"] == "15"):
            continue
        item = dict(id=ident, name=item_names[ident]["name"], description=item_names[ident]["desc"],
                    quality=int(row["quality"]), main_type=int(row["main_type"]))
        if row["main_type"] == "15":
            item["icon"] = dict(file=f"skill/ext/{resource}.png")
            essence.append(item)
        else:
            item["icon"] = atlas(f"items/all_items{(resource - 1) // 100 + 1}.png",
                                 (resource - 1) % 100 + 1, 10, 10)
            equipment.append(item)
    equipment.sort(key=lambda r: (-r["quality"], r["main_type"], r["id"]))
    essence.sort(key=lambda r: (-r["quality"], r["id"]))
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
    result = dict(heroes=heroes, equipment=equipment, spells=spells, essence=essence)
    files = set(UI_RESOURCES)
    for entries in result.values():
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
