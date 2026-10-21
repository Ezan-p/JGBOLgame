"""Extract the original journey design; keep it separate from local PvE rules."""
import json
from pathlib import Path

from local_game.assets import Resources, character_sprite
from local_game.handbook import atlas


def lua_literal(value):
    """Native tables avoid the bundled 2015 JSON decoder's empty-array bug."""
    if value is None:
        return "nil"
    if isinstance(value, bool):
        return "true" if value else "false"
    if isinstance(value, dict):
        return "{" + ",".join("[" + lua_literal(k) + "]=" + lua_literal(v)
                              for k, v in value.items()) + "}"
    if isinstance(value, list):
        return "{" + ",".join(lua_literal(v) for v in value) + "}"
    return json.dumps(value, ensure_ascii=False)


def build_journey(game_root):
    r = Resources(game_root)
    available = set(r.names())
    layout = json.loads(Path(__file__).with_name("journey_layout.json").read_text())
    if layout["source"]["sha256"] != r.source("lua/background/world_map.lua")["sha256"]:
        raise ValueError("World-map bytecode changed; re-extract the layout")
    dependencies = {f"map/{i}.jpg" for i in range(1, 13)}
    sources = []

    def rows(name):
        sources.append(r.source(name))
        return [{k.strip().split("(")[0]: v for k, v in row.items() if k} for row in r.rows(name)]

    maps = {int(v["id"]): v for v in rows("csv_config/map_name.csv")}
    names = {int(v["id"]): v for v in rows("csv_config/tollgate_name.csv")}
    items = {int(v["type_id"]): v for v in rows("csv_config/item_base.csv")}
    item_names = {int(v["Ftype_id"]): v for v in rows("csv_config/item_name.csv")}
    skills = {int(v["type_id"]): v for v in rows("csv_config/skill_base.csv")}
    skill_names = {int(v["type_id"]): v for v in rows("csv_config/skill_name.csv")}
    bases = {}
    for n in sorted(available):
        if n.startswith("csv_config/cortege/cortege_base_") and n.endswith(".csv"):
            bases.update({int(v["type_id"]): v for v in rows(n)})

    def prizes(raw):
        result = []
        for part in raw.split("/"):
            if not part:
                continue
            fields = [int(v) for v in part.split("|")]
            kind, ident, count = fields[:3]
            level, rate = fields[3:] if len(fields) == 5 else (1, fields[3])
            entry = dict(type=kind, id=ident, count=count, level=level, rate=rate)
            if kind == 5:
                base, info = items[ident], item_names[ident]
                resource = int(base["resource"])
                main_type = int(base["main_type"])
                if main_type == 15:
                    icon = dict(file=f"skill/ext/{resource}.png")
                elif main_type == 9:
                    icon = atlas("items/stone.png", resource + level - 1, 8, 4)
                    entry["icon_level"] = level
                elif main_type > 3 and main_type != 14:
                    icon = atlas(f"items/all_daoju{(resource-1)//64+1}.png",
                                 (resource-1) % 64+1, 8, 8)
                else:
                    icon = atlas(f"items/all_items{(resource-1)//100+1}.png",
                                 (resource-1) % 100+1, 10, 10)
                    if main_type == 14:
                        entry["fragment"] = True
                        dependencies.add("map/parts.png")
            elif kind == 6:
                base, info = skills[ident], skill_names[ident]
                icon = atlas("skill/skill_icons.png", int(base["resource"]), 10, 10)
            else:
                entry.update(name={11: "元宝", 12: "银两"}.get(kind, f"奖励 {kind}:{ident}"),
                             description="原版关卡奖励。", quality=1)
                if kind in (11, 12):
                    entry["icon"] = atlas("items/all_daoju1.png", 7 if kind == 11 else 8, 8, 8)
                    dependencies.add(entry["icon"]["file"])
                result.append(entry)
                continue
            entry.update(name=info["name"], description=info["desc"],
                         quality=int(base["quality"]), icon=icon)
            dependencies.add(icon["file"])
            result.append(entry)
        return result

    chapters = []
    for row in rows("csv_config/map_config.csv"):
        ident = int(row["id"])
        chapter = dict(id=ident, name=maps[ident]["name"], previous=int(row["pre_map"]),
                       next=int(row["next_map"]), first=int(row["first_tollgate"]),
                       prize=prizes(row["pass_map_prize"]), stages=[])
        if ident <= len(layout["coordinates"]):
            chapter.update(layout["coordinates"][ident-1])
        chapters.append(chapter)
    by_id = {c["id"]: c for c in chapters}
    missing_art = []
    for row in rows("csv_config/tollgate_config.csv"):
        ident, mid = int(row["id"]), int(row["map_id"])
        enemy_ids = [int(v.split("|")[0]) for v in row["cortege_list"].split("/") if v]
        base = bases[enemy_ids[0]]
        sprite = character_sprite(base)
        if sprite not in available:
            missing_art.append(dict(stage=ident, sprite=sprite))
            sprite = None
        else:
            dependencies.add(sprite)
        # Original bkg_mgr falls back to the nearest preceding scene, then map 1.
        background = next((f"map/{mid}/{i}.jpg" for i in range(ident % 100, 0, -1)
                           if f"map/{mid}/{i}.jpg" in available), "map/1/1.jpg")
        dependencies.add(background)
        stage = dict(id=ident, map_id=mid, name=names[ident]["name"],
                     previous=int(row["pre_tollgate"]), next=int(row["next_tollgate"]),
                     energy=int(row["strenth_consume"]), require_level=int(row["require_level"]),
                     exp=int(row["exp"]), silver=int(row["money"]),
                     daily_limit=int(row["day_fight_count"]), boss=int(row["boss_type"]),
                     enemies=enemy_ids, enemy_config=row["cortege_list"],
                     sprite=sprite, offset_x=float(base["offset_x"]), offset_y=float(base["offset_y"]),
                     background=background, drops=prizes(row["random_prize"]),
                     three_star=prizes(row["com_win_prize"]),
                     first_drops=prizes(row["first_random_prize"]),
                     first_exp=row["first_win_prize"])
        by_id[mid]["stages"].append(stage)
    for chapter in chapters:
        chapter["stages"].sort(key=lambda s: s["id"])
    ui_files = [
        "map/mingzidi1.png", "map/mingzidi2.png", "map/mingzidi3.png",
        "v2/subLevelUI/BOSS_bkg.png", "v2/subLevelUI/BOSS_bkg2.png",
        "v2/subLevelUI/char_bkg.png", "v2/subLevelUI/nameBkg.png",
        "v2/subLevelUI/start_fight1.png", "v2/subLevelUI/map_mask.png",
        "v2/subLevelUI/head_mid_bkg.png", "v2/introUI/close1.png",
        "v2/packageUI/board_edge1.png", "v2/packageUI/board_edge2.png",
        "v2/soulExchangeUI/btn_bkg1.png", "v2/introUI/stars.png",
    ]
    dependencies.update(ui_files)
    for name in dependencies:
        r.read(name)
    return dict(schema=1, chapters=chapters, resources=sorted(dependencies),
                sources=[layout["source"], *sources], missing_art=missing_art,
                notes="Original client reference data. Rate fields are not verified server probabilities.")
