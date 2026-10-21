"""Reverse-engineered 神仙 module rules: soul conjure and 五法界魂 conversion.

Sources inside the original client:

* ``ui/lineupUI.lua`` - four side tabs (神仙/魂魄/精魄/五法界魂), the 图鉴
  button, ``showJingpo`` and ``showCommonSoul``.
* ``ui/allLineupUI.lua`` - ``showAllSoul`` sorts souls by quality/count and
  offers ``幻魂`` (spirit_compose_count) or 飞升.
* ``ui/soulExchangeUI.lua`` - ``adaptiveSpiritSort`` and
  ``showCortegeSoulChooseLayer`` pick a same-category/same-quality character.
* ``csv_config/cortege_quality.csv`` - spirit_compose_count / spirit_convert_count.
* ``csv_config/item_base.csv`` - main_type 11 (adaptive_spirit) and 15 (ext_skill).

The original silver price per conversion came from the server and is not in the
APK; the local rule below charges no silver and converts one 界魂 into one soul.
"""
from local_game import inventory
from local_game.summon import SOUL_COMPOSE

ADAPTIVE_SPIRIT = 11
SPIRIT_CATEGORIES = {1: "神", 2: "妖", 3: "人", 4: "魔", 5: "佛"}


def _hero(catalog, value, error):
    if type(value) is not int or str(value) not in catalog["heroes"]:
        raise error("神仙不存在")
    return catalog["heroes"][str(value)]


def compose(state, args, catalog, error, add_to_lineup):
    """幻魂: spend the original per-quality soul count to obtain a character."""
    hero = _hero(catalog, args.get("hero"), error)
    ident = hero["id"]
    if str(ident) in state["heroes"]:
        raise error("已经拥有该神仙")
    need = SOUL_COMPOSE[hero["quality"]]
    souls = state.setdefault("souls", {})
    current = int(souls.get(str(ident), 0))
    if current < need:
        raise error("魂魄不足，需要 %d，当前 %d" % (need, current))
    current -= need
    if current:
        souls[str(ident)] = current
    else:
        souls.pop(str(ident), None)
    state["heroes"][str(ident)] = 1
    try:
        add_to_lineup(ident)
    except error:
        # A full lineup is not an error: the character still joins the roster.
        pass
    return "%s 幻魂成功，已加入神仙列表" % hero["name"]


def convert(state, args, catalog, error):
    """转化: one 五法界魂 becomes one soul of a matching 阵营/星级 character."""
    item_id = args.get("item")
    if type(item_id) is not int:
        raise error("参数必须是整数：item")
    item = (catalog.get("inventory") or {}).get("items", {}).get("i%d" % item_id)
    if not item or item["main_type"] != ADAPTIVE_SPIRIT:
        raise error("请选择五法界魂")
    hero = _hero(catalog, args.get("hero"), error)
    if (hero["quality"] != item["quality"] or
            hero["category"] != SPIRIT_CATEGORIES[item["sub_type"]]):
        raise error("只能转化为同品质、同阵营神仙的魂魄")
    bag = inventory.migrate(state)
    entry = next((e for e in bag["entries"]
                  if e["key"] == item["key"] and int(e.get("count", 0)) > 0), None)
    if entry is None:
        raise error("五法界魂数量不足")
    entry["count"] -= 1
    if entry["count"] <= 0:
        bag["entries"].remove(entry)
    souls = state.setdefault("souls", {})
    souls[str(hero["id"])] = int(souls.get(str(hero["id"]), 0)) + 1
    return "%s 转化成功：获得 %s 魂魄 ×1" % (item["name"], hero["name"])
