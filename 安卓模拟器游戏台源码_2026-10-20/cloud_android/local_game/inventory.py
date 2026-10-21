"""Versioned original inventory catalog and explicit, transactional local rules."""
import copy
import struct

from local_game.assets import Resources
from local_game.handbook import atlas, UI_RESOURCES

CATEGORIES = {1: "武器", 2: "防具", 3: "法宝", 4: "法术", 5: "灵石", 6: "道具"}
EXCLUDED_PROPS = {10, 11, 13, 15}


def build_inventory(game_root):
    r = Resources(game_root)
    sources = []

    def rows(name):
        name = "csv_config/" + name + ".csv"
        sources.append(r.source(name))
        return [{k.split("(")[0]: v for k, v in x.items() if k} for x in r.rows(name)]

    names = {int(x["Ftype_id"]): x for x in rows("item_name")}
    card_letters = {int(x["level"]): x["letter"] for x in rows("cards_letter")}
    summer_letters = {int(x["level"]): x["letter"] for x in rows("summer_cards_letter")}
    from .battle_rules import build_rules
    combat_rules = build_rules(r)
    items = {}
    dependencies = set(UI_RESOURCES)
    dependencies.update(n for n in r.names() if n.startswith("v2/packageUI/"))
    dependencies.update(["v2/smithUI/smith1.png", "v2/smithUI/smith2.png",
                         "v2/stoneUI/putin_btn1.png", "v2/enhanceUI/up1.png", "map/parts.png",
                         "v2/common/frame1.png", "v2/common/frame2.png",
                         "v2/common/small_label.png", "v2/common/close1.png",
                         "v2/enhanceUI/equipEnhance.png", "v2/enhanceUI/mid2.png",
                         "v2/enhanceUI/mid3.png", "v2/enhanceUI/en_1.png",
                         "v2/enhanceUI/continue_1.png", "v2/newIntroUI/star_bkg.png"])
    for b in rows("item_base"):
        ident, kind, resource = int(b["type_id"]), int(b["main_type"]), int(b["resource"])
        category = kind if kind <= 3 else 5 if kind == 9 else 6
        if kind == 19:
            icon = dict(file=f"v2/wakeUI/icon/{ident % 1000}.png", overlays=[
                dict(file=f'v2/wakeUI/icon/q{b["quality"]}.png', x=.5, y=.5, scale=1),
                dict(file=f'v2/wakeUI/icon/f{b["quality"]}{b["sub_type"]}.png', x=.84, y=.838, scale=1)])
        elif kind == 20:
            icon = dict(file="v2/destinyUI/card.png", overlays=[
                dict(file=f'v2/towerUI/b_num{5 if ident == 1142 else 10}.png', x=.62, y=.47, scale=.9)])
        elif kind in (10, 18):
            icon = dict(file="v2/CardUI/card_bkg.png" if kind == 10 else "v2/summerUI/cbkg3.png",
                        text=(card_letters if kind == 10 else summer_letters).get(1, ""))
        elif kind == 15:
            icon = {"file": f"skill/ext/{resource}.png"}
        elif kind == 9:
            icon = atlas("items/stone.png", resource, 8, 4)
        elif kind <= 3 or kind == 14:
            icon = atlas(f"items/all_items{(resource-1)//100+1}.png", (resource-1)%100+1, 10, 10)
        else:
            icon = atlas(f"items/all_daoju{(resource-1)//64+1}.png", (resource-1)%64+1, 8, 8)
        action = "equip" if kind <= 3 else "trait" if kind == 15 and str(ident) in combat_rules["traits"] else "star" if kind == 19 and str(ident) in combat_rules["stars"] else "gem" if kind == 9 else "reference"
        if kind == 5 and int(b["strength_plus"]) > 0:
            action = "energy"
        if kind == 5 and int(b["experience_plus"]) > 0:
            action = "experience"
        if ident == 1024:
            action = "train"
        if ident == 10000:
            action = "material"
        if ident == 1206:
            action = "cheer_material"
        if ident == 1015:
            action = "support_material"
        if kind == 14 and ident-5000 in names:
            action = "fragment"
        items[f"i{ident}"] = dict(key=f"i{ident}", id=ident, category=category,
            name=names[ident]["name"], description=names[ident]["desc"],
            obtain=names[ident].get("product_desc", ""), quality=int(b["quality"]),
            main_type=kind, sub_type=int(b["sub_type"]), icon=icon,
            top_level=5 if action == "trait" else 10 if action == "star" else int(b["top_level"]), original=b, action=action,
            original_bag=kind not in EXCLUDED_PROPS,
            price=max(40, int(b["quality"])*100) if action != "reference" else 0)
    names = {int(x["type_id"]): x for x in rows("skill_name")}
    for b in rows("skill_base"):
        ident = int(b["type_id"])
        if ident == 1:
            continue
        active = int(b["use_mode"]) == 1
        # Original equip_pos rules do not restrict a spell by its effect field.
        action = "spell"
        items[f"s{ident}"] = dict(key=f"s{ident}", id=ident, category=4,
            name=names[ident]["name"], description=names[ident]["desc"],
            obtain=names[ident].get("introduce", ""), quality=int(b["quality"]),
            main_type=0, sub_type=0, icon=atlas("skill/skill_icons.png", int(b["resource"]), 10, 10),
            top_level=int(b["top_level"]), original=b, active=active, action=action,
            original_bag=True, price=max(100, int(b["quality"])*100) if action != "reference" else 0)
    missing = []
    for item in items.values():
        icon = item["icon"]
        if icon["file"] not in r.names():
            missing.append(dict(key=item["key"], file=icon["file"]))
            item["missing_icon"] = icon["file"]
            item["icon"] = None
            continue
        raw = r.read(icon["file"])
        if not raw.startswith(b"\x89PNG\r\n\x1a\n"):
            raise ValueError("Invalid item image: " + icon["file"])
        w, h = struct.unpack(">II", raw[16:24])
        if "index" in icon and (not 1 <= icon["index"] <= icon["rows"]*icon["columns"]
                               or w % icon["columns"] or h % icon["rows"]):
            raise ValueError("Invalid item atlas: " + item["key"])
        dependencies.add(icon["file"])
        dependencies.update(o["file"] for o in icon.get("overlays", []))
    costs = rows("equip_enhance_cost")
    stones = rows("stone_cost_worth")
    raw_tables = {name: rows(name) for name in (
        "skill_enhance_cost", "skill_enhance_worth", "equip_compose_random",
        "equip_advance_cost", "equip_star_cost", "item_sell_config", "item_receive_config")}
    sources.extend(r.source(n) for n in ("lua/ui/packageUI.lua", "lua/common/common_def.lua", "lua/data.lua",
                                        "lua/ui/wakeUI.lua", "lua/ui/destinyUI.lua"))
    for n in dependencies:
        r.read(n)
    native_skills = {x["type_id"]: int(x["chushijineng"]) for x in r.rows("csv_config/cortege/cortege_base_0.csv")}
    return dict(schema=2, combat_rules=combat_rules, items=items, categories=CATEGORIES, native_skills=native_skills,
        enhance_cost={x["level"]: x for x in costs},
        stones={f'{x["stone_type"]}:{x["level"]}': x for x in stones},
        raw_tables=raw_tables, sources=sources, missing_icons=missing, resources=sorted(dependencies))


def migrate(state):
    """Only add empty storage; old balances, team and progression remain intact."""
    state.setdefault("inventory", {"version": 1, "next": 1, "claimed": False, "entries": []})
    return state["inventory"]


def grant(state, key, count=1, level=1, catalog=None):
    bag = migrate(state)
    item = catalog["items"][key]
    stack = item["category"] in (5, 6) and item["action"] not in ("trait","star")
    if stack:
        for entry in bag["entries"]:
            if entry["key"] == key and entry["level"] == level:
                entry["count"] += count
                return
    for _ in range(1 if stack else count):
        bag["entries"].append(dict(uid=bag["next"], key=key, count=count if stack else 1,
                                   level=level, hero=0, gem=0))
        bag["next"] += 1


def owned(state):
    """Catalogue ownership used by the 图鉴 brightness/dimming state.

    Original handbookUI compares the owned package with the whole catalogue;
    the local save keeps equipment/spells/traits as inventory entries.
    """
    result = {"heroes": sorted(int(ident) for ident in state.get("heroes", {})),
              "equipment": set(), "spells": set(), "essence": set()}
    for entry in state.get("inventory", {}).get("entries", []):
        if int(entry.get("count", 0)) <= 0:
            continue
        key = str(entry.get("key", ""))
        if key.startswith("i") and key[1:].isdigit():
            ident = int(key[1:])
            if 2000 <= ident < 5000:
                result["equipment"].add(ident)
            elif ident >= 10000:
                result["essence"].add(ident)
        elif key.startswith("s") and key[1:].isdigit():
            result["spells"].add(int(key[1:]))
    return {name: sorted(values) if isinstance(values, set) else values
            for name, values in result.items()}


def value(item, level):
    b = item["original"]
    field = {1: "gongji_plus", 2: "fangyu_plus", 3: "maxhp_plus"}.get(item["category"])
    if field:
        return round(float(b[field]) + float(b["upgrade_plus"])*(level-1))
    if item["category"] == 4:
        field = {1: "gongji_plus", 2: "fangyu_plus", 3: "magic_plus", 5: "hp_plus"}.get(int(b["effect_field"]), "intensity")
        return round(float(b[field]) + float(b["upgrade_plus"])*(level-1), 2)
    return 0


def upgrade_cost(catalog, item, level):
    if item["category"] <= 3:
        return int(catalog["enhance_cost"].get(str(level), {}).get(f'star{item["quality"]}_money', 0))
    return 100 * max(1, item["quality"]) * level  # Explicit local spell silver cost.


def slot(item):
    return str(item["category"]) if item["category"] != 4 else ("active" if item["active"] else "passive")


def spell_positions(state, catalog):
    """Read legacy active/passive saves as two extra positions without rewriting saves."""
    result, occupied = {}, {}
    spells = [e for e in state.get("inventory", {}).get("entries", [])
              if e["hero"] and catalog["items"][e["key"]]["category"] == 4]
    for e in sorted(spells, key=lambda e: (e.get("equip_pos") not in (2, 3), e["uid"])):
        used = occupied.setdefault(e["hero"], set())
        pos = e.get("equip_pos")
        if pos not in (2, 3) or pos in used:
            pos = next((p for p in (2, 3) if p not in used), 0)
        result[e["uid"]] = pos
        used.add(pos)
    return result


def hero_with_inventory(hero, state, catalog):
    hero = copy.deepcopy(hero)
    bonuses = {"attack": 0, "defense": 0, "hp": 0, "magic": 0}
    percent = {"attack": 0, "defense": 0, "hp": 0, "magic": 0}
    positions = spell_positions(state, catalog)
    from .battle_training import training
    from .synergy import support_ids
    rules=catalog.get('combat_rules',{})
    learned=training(state,hero['id'])
    native_level=learned.get('native_level',1)
    hero['battle_training']=dict(native_level=native_level,awaken=learned.get('awaken',0),cheer_level=learned.get('cheer_level',0))
    cheer_rate=float(rules.get('cheer',{}).get(str(learned.get('cheer_level',0)),{}).get('plus_rate',.5)) if hero['id'] in support_ids(state) else 1
    hero["traits"] = []
    hero["stars"] = []
    hero["spells"] = [{"id": hero.get("skill_id", 1), "level": native_level, "position": 1, "awaken": learned.get("awaken",0)}]
    native = catalog["items"].get('s'+str(hero.get('skill_id', 1)))
    if native and not native['active']:
        stat = {1: "attack", 2: "defense", 3: "magic", 5: "hp"}.get(int(native['original']['effect_field']))
        if stat:
            percent[stat] += value(native, native_level)/100*(1+rules.get('awaken_rates',{}).get(str(native['id']),0)/100 if learned.get('awaken') else 1)
    for entry in state.get("inventory", {}).get("entries", []):
        if entry["hero"] != hero["id"]:
            continue
        item = catalog["items"][entry["key"]]
        if item["action"] == "trait":
            hero["traits"].append(dict(id=item["id"],level=entry["level"]))
        elif item['action']=='star':
            hero['stars'].append(dict(id=item['id'],level=entry['level']))
            star=rules['stars'][str(item['id'])];family=star['family'];strength=star['values'][min(10,entry['level'])-1]
            if family<=8:
                stat={1:'attack',2:'defense',3:'hp',4:'magic'}[(family+1)//2]
                if family%2:percent[stat]+=strength
                else:bonuses[stat]+=strength
            else:
                field={9:'spell_power_percent',10:'spell_power_flat',11:'crit_rate',12:'crit_bonus',13:'crit_resist',14:'crit_reduction',15:'death_prevent_rate'}[family]
                hero[field]=hero.get(field,0)+strength
                if family==15:
                    params=star['parameters'].split('/')[min(10,entry['level'])-1].split('|')
                    hero['death_prevent_limit']=int(float(params[1])) if len(params)>1 else 1
        elif item["category"] <= 3:
            stat = {1: "attack", 2: "defense", 3: "hp"}[item["category"]]
            bonus = value(item, entry["level"])
            stone = catalog["stones"].get(f'{item["category"]}:{entry["gem"]}', {})
            bonuses[stat] += round(bonus * (1 + float(stone.get("base", 0))))
        elif item["category"] == 4:
            position = positions.get(entry['uid'], 0)
            if not position:
                continue
            hero["spells"].append(dict(id=item['id'], level=entry['level'], position=position, awaken=entry.get('awaken',0), advanced=entry.get('advanced',False)))
            if not item["active"]:
                stat = {1: "attack", 2: "defense", 3: "magic", 5: "hp"}.get(int(item["original"]["effect_field"]))
                if stat:
                    percent[stat] += value(item, entry["level"])/100*cheer_rate
            if entry.get('advanced'):
                percent['hp']+=float(rules.get('advance',{}).get(str(item['id']),{}).get('hp_plus',0))/100*cheer_rate
    awaken=rules.get('awaken',{}).get(str(learned.get('awaken',0)))
    if awaken:
        bonuses[{1:'attack',2:'defense',3:'magic'}[learned['awaken']]]+=int(awaken['plus_value'])
    for stat in bonuses:
        hero[stat] = round((hero.get(stat, 0) + bonuses[stat]) * (1 + percent[stat]))
    hero["battle_stats_ready"] = True
    hero["equipment_bonus"] = bonuses
    return hero


def view(state, catalog):
    bag = state.get("inventory", {"claimed": False, "entries": []})
    entries = []
    positions = spell_positions(state, catalog)
    for entry in bag["entries"]:
        item = catalog["items"][entry["key"]]
        shown_value = value(item, entry["level"])
        if item["category"] <= 3 and entry["gem"]:
            stone = catalog["stones"].get(f'{item["category"]}:{entry["gem"]}', {})
            shown_value = round(shown_value * (1 + float(stone.get("base", 0))))
        entries.append({**entry, "equip_pos": positions.get(entry["uid"], 0), "value": shown_value,
                        "upgrade_cost": upgrade_cost(catalog, item, entry["level"])})
    return {"claimed": bag["claimed"], "entries": entries}


def apply(state, op, args, catalog, error):
    bag = migrate(state)

    def check(test, message):
        if not test:
            raise error(message)

    def integer(name):
        check(type(args.get(name)) is int, "参数必须是整数：" + name)
        return args[name]

    def spend(amount):
        check(amount > 0 and state["silver"] >= amount, f"银两不足，需要 {amount}")
        state["silver"] -= amount

    def consume(entry, amount=1):
        check(entry["count"] >= amount, "数量不足")
        entry["count"] -= amount
        if entry["count"] == 0:
            bag["entries"].remove(entry)

    if op == "bag_claim":
        check(not bag["claimed"], "入门包裹已领取")
        for key, count in (("i2006", 1), ("i3002", 1), ("i4002", 1), ("i4012", 1),
                           ("i4013", 1), ("s202", 1), ("s22", 1), ("s42", 1), ("s43", 1), ("i1090", 3),
                           ("i1091", 3), ("i1092", 3), ("i1020", 3), ("i1024", 2),
                           ("i10000", 10), ("i7006", 10), ("i1001", 169)):
            grant(state, key, count, catalog=catalog)
        bag["claimed"] = True
        return "已领取入门包裹；点击物品可装备或使用"
    if op == "bag_buy":
        check(isinstance(args.get("key"), str), "请选择物品")
        item = catalog["items"].get(args["key"])
        check(item and item["action"] != "reference", "该物品仅供原版资料查阅")
        count=args.get('count',1)
        check(type(count) is int and 1<=count<=999 and (count==1 or item['action']=='cheer_material'), '兑换数量无效')
        spend(item["price"]*count)
        grant(state, item["key"], count=count, catalog=catalog)
        return "已兑换 " + item["name"]
    uid = integer("uid")
    entry = next((e for e in bag["entries"] if e["uid"] == uid), None)
    check(entry is not None, "物品已不存在，请刷新包裹")
    item = catalog["items"][entry["key"]]
    category = item["category"]
    if op == "bag_equip":
        check(category <= 4 or item["action"] in ("trait","star"), "此物品不能装备")
        hero = integer("hero")
        check(hero == 0 or str(hero) in state["heroes"], "尚未拥有该神仙")
        if item['action']=='star' and hero:
            from .battle_training import training
            check(training(state,hero).get('awaken'), '原生法术觉醒后才能装备星宿')
            worn=[e for e in bag['entries'] if e['hero']==hero and catalog['items'][e['key']]['action']=='star' and e['uid']!=uid]
            check(len(worn)<5,'每位神仙最多装备五颗星宿')
            check(not any(catalog['items'][e['key']]['id']%100==item['id']%100 for e in worn),'同类星宿不能重复装备')
            if entry['count']>1:
                entry['count']-=1;grant(state,entry['key'],level=entry['level'],catalog=catalog);entry=bag['entries'][-1]
        elif item["action"] == "trait" and hero:
            worn=[e for e in bag['entries'] if e['hero']==hero and catalog['items'][e['key']]['action']=='trait' and e['uid']!=uid]
            check(len(worn)<4, '每位神仙最多装备四项特技')
            check(not any(catalog['items'][e['key']]['id']%100==item['id']%100 for e in worn), '不能重复装备同类特技')
            if entry['count']>1:
                entry['count']-=1
                grant(state,entry['key'],level=entry['level'],catalog=catalog)
                entry=bag['entries'][-1]
        elif category == 4 and hero:
            positions = spell_positions(state, catalog)
            equipped = [e for e in bag["entries"] if e["hero"] == hero and catalog["items"][e["key"]]["category"] == 4]
            pos = args.get("equip_pos")
            if pos is None:
                pos = positions.get(uid) if entry["hero"] == hero else None
                pos = pos or next((p for p in (2, 3) if all(positions[e["uid"]] != p for e in equipped)), 0)
            check(type(pos) is int and pos in (2, 3), "自带法术不可更换；请选择第2或第3法术格")
            check(item["id"] != catalog["native_skills"].get(str(hero)), "不能重复装备自带法术")
            check(not any(e["uid"] != uid and e["key"] == entry["key"] and positions[e["uid"]] != pos for e in equipped), "该神仙已装备同名法术")
            for e in bag["entries"]:
                if e["uid"] in positions:
                    e["equip_pos"] = positions[e["uid"]]
            for other in equipped:
                if positions[other["uid"]] == pos and other["uid"] != uid:
                    other["hero"], other["equip_pos"] = 0, 0
            entry["equip_pos"] = pos
        elif hero:
            for other in bag["entries"]:
                if other["hero"] == hero and slot(catalog["items"][other["key"]]) == slot(item):
                    other["hero"] = 0
        entry["hero"] = hero
        if category == 4 and not hero:
            entry["equip_pos"] = 0
        return "装备已保存" if hero else "已卸下"
    if op == "bag_advance":
        from .battle_training import consume_materials
        rule=catalog.get('combat_rules',{}).get('advance',{}).get(str(item['id']))
        check(category==4 and rule and entry['level']>=int(rule['min_level']), '该法术不满足进阶条件')
        check(not entry.get('advanced'), '该法术已经进阶')
        consume_materials(state,rule['material_list'],error,exclude_uid=uid)
        entry['advanced']=True
        return '法术进阶成功，装备后增加生命'
    if op == "bag_upgrade":
        check(category <= 4 or item["action"] in ("trait","star"), "此物品不能强化")
        check(entry["level"] < item["top_level"], "已达到等级上限")
        spend(upgrade_cost(catalog, item, entry["level"]))
        entry["level"] += 1
        return "强化成功" if category <= 3 else "法术升级成功"
    if op == "bag_socket":
        check(category <= 3, "只有装备可以镶嵌")
        gem = next((e for e in bag["entries"] if e["uid"] == integer("gem")), None)
        check(gem is not None, "灵石不存在")
        gem_item = catalog["items"][gem["key"]]
        check(gem_item["category"] == 5 and gem_item["sub_type"] == category, "灵石类型不匹配")
        check(not entry["gem"], "请先卸下已镶嵌的灵石")
        entry["gem"] = gem["level"]
        consume(gem)
        return "镶嵌成功，装备属性已提升"
    if op == "bag_unsocket":
        check(category <= 3 and entry["gem"] > 0, "没有已镶嵌的灵石")
        grant(state, f"i{1089+category}", level=entry["gem"], catalog=catalog)
        entry["gem"] = 0
        return "灵石已归还包裹"
    if op == "bag_compose":
        if category == 5:
            check(entry["level"] < 10, "本地灵石最高10级")
            check(entry["count"] >= 3, "需要3颗同类同级灵石")
            level = entry["level"] + 1
            consume(entry, 3)
            grant(state, item["key"], level=level, catalog=catalog)
            return "已合成更高一级灵石"
        check(item["action"] == "fragment", "该物品没有本地合成配方")
        check(entry["count"] >= 10, "需要10个同名装备碎片")
        consume(entry, 10)
        grant(state, f'i{item["id"]-5000}', catalog=catalog)
        return "已合成对应装备"
    if op == "bag_smelt":
        check(category <= 4, "只能熔炼装备和法术")
        check(not entry["hero"] and not entry["gem"], "请先卸下装备和灵石")
        consume(entry)
        grant(state, "i10000", max(1, item["quality"])*entry["level"], catalog=catalog)
        return "熔炼成功，获得精魄石"
    if op == "bag_use":
        action = item["action"]
        if action == "energy":
            check(state["energy"] < 60, "体力已满，不消耗道具")
            state["energy"] = min(60, state["energy"] + int(item["original"]["strength_plus"]))
        elif action == "experience":
            state["experience"] += int(item["original"]["experience_plus"])
        elif action == "train":
            hero = str(integer("hero"))
            check(hero in state["heroes"], "尚未拥有该神仙")
            check(state["heroes"][hero] < 20, "神仙已达到本地等级上限")
            state["heroes"][hero] += 1
        elif action == "material":
            state["silver"] += 20
        else:
            raise error("该道具属于尚未接入的原版系统，未消耗")
        consume(entry)
        return "道具使用成功，已保存"
    raise error("未知包裹操作")
