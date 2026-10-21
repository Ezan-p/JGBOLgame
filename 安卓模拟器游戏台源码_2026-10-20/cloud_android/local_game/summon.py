"""Original summon pools and local summon rules.

Reverse engineered from ui/summonUI.lua, common/common_def.lua and
csv_config/summon_cortege_set.csv. The original client only knows the three
grades, the 10/100/300 gold prices, the five daily normal free picks and the
server-provided free timestamps; drop rates stayed on the server and are not
present in the APK. The rates below are explicit local rules.
"""
import copy
import random
import time

GRADES = {
    1: {"grade": 1, "name": "普通召唤", "cost": 10, "cooldown": 600},
    2: {"grade": 2, "name": "高级召唤", "cost": 100, "cooldown": 7200},
    3: {"grade": 3, "name": "超级召唤", "cost": 300, "cooldown": 259200},
}
NORMAL_DAILY_FREE = 5
NEWS_LIMIT = 7
# csv_config/cortege_quality.csv: spirit_convert_count / spirit_compose_count
SOUL_CONVERT = {1: 2, 2: 4, 3: 9, 4: 12, 5: 15}
SOUL_COMPOSE = {1: 5, 2: 10, 3: 20, 4: 30, 5: 40}
# Local-only rates: the original server tables were not shipped in the client.
RATES = {
    1: ((2, 70), (3, 25), (4, 5)),
    2: ((3, 70), (4, 25), (5, 5)),
    3: ((4, 80), (5, 20)),
}
QUALITY_RANGE = {1: (2, 4), 2: (3, 5), 3: (4, 5)}
# The left column in the reference screenshot. These are local seed
# announcements; real pulls prepend the local player's own announcements.
SEED_NEWS = ((5018, "雄霸"), (5002, "秒木山人"), (5042, "皇角晚雅"), (5020, "南山大王"))
SEED_LAST = 3034

UI_RESOURCES = [
    "v2/introUI/intro_bkg.png", "v2/introUI/small_label.png", "v2/introUI/close1.png",
    "v2/packageUI/board_edge1.png", "v2/packageUI/board_edge2.png",
    "v2/summonUI/newsHZ.png", "v2/summonUI/info_bkg.png",
    "v2/summonUI/bottom_bkg.png", "v2/summonUI/intro_bottom.png",
    "v2/summonUI/normal_bkg.jpg", "v2/summonUI/advance_bkg.jpg",
    "v2/summonUI/super_bkg.jpg",
    "v2/summonUI/summon_bkg_1.png", "v2/summonUI/summon_bkg_2.png",
    "v2/summonUI/summon_bkg_3.png",
    "v2/summonUI/summon_btn.png", "v2/summonUI/summon_btn_1.png",
    "v2/summonUI/summon_btn_2.png", "v2/summonUI/summon_btn_3.png",
    "v2/summonUI/bkg_bottom1.png", "v2/summonUI/bkg_bottom2.png",
    "v2/summonUI/bkg_bottom3.png",
    "v2/summonUI/soul_bkg.png", "v2/summonUI/get_soul.png",
    "v2/introUI/soul_label.png",
    "v2/summonUI/detail1.png", "v2/summonUI/detail2.png",
    "v2/summonUI/continue1.png", "v2/summonUI/continue2.png",
    "v2/trainingUI/stats_bkg.png",
    "v2/introUI/health.png", "v2/introUI/damage.png", "v2/introUI/defence.png",
    "v2/introUI/mana.png", "v2/introUI/yuanfen_label.png",
    "v2/charPositionUI/type_1.png", "v2/charPositionUI/type_2.png",
    "v2/charPositionUI/type_3.png", "v2/charPositionUI/type_4.png",
    "v2/charPositionUI/type_5.png",
    "chars/4_all_name1.png", "chars/4_all_name2.png",
    "chars/5_all_name1.png", "chars/5_all_name2.png",
    "chars/123_all_name1.png", "chars/123_all_name2.png",
    "v2/character_frame.png", "v2/money_gold.png", "v2/money_silver.png",
    "v2/Stamina2.png", "v2/Energy2.png", "v2/vip/vip_label.png", "v2/vip/0.png",
    "v2/CharaterUI/stars.png", "v2/namingUI/head_201.png",
]


def build_summon(game_root):
    """Return the original summon pools plus the local UI resource manifest."""
    from local_game.assets import Resources, catalog

    resources = Resources(game_root)
    game = catalog(game_root)
    recruitable = set(game["recruitable"])
    quality = {ident: game["heroes"][str(ident)]["quality"] for ident in recruitable}
    sets = {}
    for row in resources.rows("csv_config/summon_cortege_set.csv"):
        sets[int(row["index"])] = [int(value) for value in row["type_set(id1/id2/id3...)"].split("/")]
    if not set(sets[1]) <= recruitable or not set(sets[2]) <= recruitable:
        raise ValueError("Summon pool contains a non-recruitable character")
    pools = {
        "1": [ident for ident in game["recruitable"] if 2 <= quality[ident] <= 4],
        "2": sets[1],
        "3": sets[2],
    }
    if any(not pool for pool in pools.values()):
        raise ValueError("Empty summon pool")
    for grade, (low, high) in QUALITY_RANGE.items():
        if any(not low <= quality[ident] <= high for ident in pools[str(grade)]):
            raise ValueError("Summon pool quality outside its card range")
    files = set(UI_RESOURCES)
    for ident in set(sum(pools.values(), [])):
        files.add(game["heroes"][str(ident)]["sprite"])
    for name in files:
        resources.read(name)
    return {
        "pools": pools,
        "tiers": [GRADES[grade] for grade in (1, 2, 3)],
        "rates": {str(grade): [{"quality": q, "weight": w} for q, w in rates]
                  for grade, rates in RATES.items()},
        "normal_daily_free": NORMAL_DAILY_FREE,
        "soul_convert": {str(q): v for q, v in SOUL_CONVERT.items()},
        "soul_compose": {str(q): v for q, v in SOUL_COMPOSE.items()},
        "resources": sorted(files),
    }


def initial_state(catalog):
    """New-save summon block. Normal free picks start available."""
    now = int(time.time())
    news = []
    for ident, name in SEED_NEWS:
        if str(ident) in catalog["heroes"]:
            news.append({"type_id": ident, "name": name, "time": now - len(news) * 60})
    return {
        "normal_time": 0, "advance_time": 0, "super_time": 0,
        "normal_day": time.strftime("%Y-%m-%d", time.localtime(now)),
        "normal_used": 0, "pulls": 0,
        "last": SEED_LAST if str(SEED_LAST) in catalog["heroes"] else 0,
        "news": news,
    }


def ensure(state, catalog, now=None):
    """Add summon fields to saves created before this module existed."""
    now = int(time.time()) if now is None else now
    summon = state.setdefault("summon", initial_state(catalog))
    defaults = initial_state(catalog)
    for key, value in defaults.items():
        summon.setdefault(key, value)
    today = time.strftime("%Y-%m-%d", time.localtime(now))
    if summon.get("normal_day") != today:
        summon["normal_day"] = today
        summon["normal_used"] = 0
        summon["normal_time"] = 0
    return summon


def _time_key(grade):
    return {1: "normal_time", 2: "advance_time", 3: "super_time"}[grade]


def free_status(summon, grade, now):
    if grade == 1 and summon["normal_used"] >= NORMAL_DAILY_FREE:
        return False, 0
    remaining = max(0, int(summon.get(_time_key(grade), 0)) - now)
    return remaining == 0, remaining


def view(state, catalog, now=None):
    now = int(time.time()) if now is None else now
    summon = ensure(state, catalog, now)
    tiers = []
    for grade in (1, 2, 3):
        free, remaining = free_status(summon, grade, now)
        tiers.append({
            "grade": grade, "name": GRADES[grade]["name"],
            "cost": GRADES[grade]["cost"], "free": free,
            "remaining": remaining, "used": summon["normal_used"],
            "limit": NORMAL_DAILY_FREE,
        })
    last = summon.get("last")
    return {
        "tiers": tiers, "pulls": summon["pulls"],
        "last": {"id": int(last), "name": catalog["heroes"][str(last)]["name"]}
                if last and str(last) in catalog["heroes"] else None,
        "news": copy.deepcopy(summon["news"]),
    }


def _choose_quality(grade, rng):
    roll = rng.randrange(sum(weight for _, weight in RATES[grade]))
    for quality, weight in RATES[grade]:
        if roll < weight:
            return quality
        roll -= weight
    raise AssertionError("unreachable summon rate table")


def grant(state, catalog, ident, add_to_lineup, error):
    """Add a summoned character; duplicates become original-config souls."""
    hero = copy.deepcopy(catalog["heroes"][str(ident)])
    duplicate = str(ident) in state["heroes"]
    soul_gain = 0
    soul_total = 0
    if duplicate:
        soul_gain = SOUL_CONVERT[hero["quality"]]
        souls = state.setdefault("souls", {})
        soul_total = int(souls.get(str(ident), 0)) + soul_gain
        souls[str(ident)] = soul_total
    else:
        state["heroes"][str(ident)] = 1
        try:
            if sum(bool(value) for value in state["lineup"]) < 4:
                add_to_lineup(ident)
        except error:
            # A full lineup is not an error: the character still joins the roster.
            pass
    return hero, not duplicate, soul_gain, soul_total, SOUL_COMPOSE[hero["quality"]]


def pull(state, raw_grade, catalog, error, add_to_lineup, now=None, rng=None):
    if type(raw_grade) is not int or raw_grade not in GRADES:
        raise error("召唤类型无效")
    now = int(time.time()) if now is None else now
    summon = ensure(state, catalog, now)
    grade = raw_grade
    free, _ = free_status(summon, grade, now)
    cost = 0 if free else GRADES[grade]["cost"]
    if not free:
        if int(state.get("gold", 0)) < cost:
            raise error("元宝不足，需要 %d 元宝" % cost)
        state["gold"] -= cost
    if free and grade == 1:
        summon["normal_used"] += 1
    summon[_time_key(grade)] = now + GRADES[grade]["cooldown"]
    if rng is None:
        rng = random.Random((summon["pulls"] + 1) * 1000003 + now)
    quality = _choose_quality(grade, rng)
    pool = [ident for ident in pools(catalog)[str(grade)]
            if catalog["heroes"][str(ident)]["quality"] == quality]
    ident = rng.choice(pool)
    hero, is_new, soul_gain, soul_total, soul_need = grant(
        state, catalog, ident, add_to_lineup, error)
    summon["pulls"] += 1
    summon["last"] = ident
    summon["news"].insert(0, {"type_id": ident, "name": state.get("name") or "本地行者", "time": now})
    del summon["news"][NEWS_LIMIT:]
    return {
        "grade": grade, "grade_name": GRADES[grade]["name"], "free": free,
        "cost": cost, "hero": hero, "new": is_new,
        "soul_gain": soul_gain, "soul_total": soul_total, "soul_need": soul_need,
        "gold": state["gold"], "silver": state["silver"],
        "next_time": summon[_time_key(grade)],
    }


def pools(catalog):
    """Exact original pools shipped in catalog.json, with a quality-safe fallback."""
    configured = (catalog.get("summon") or {}).get("pools")
    if configured:
        return {str(key): [int(value) for value in values] for key, values in configured.items()}
    cached = getattr(catalog, "_summon_pools", None)
    if cached is None:
        recruitable = catalog["recruitable"]
        quality = {ident: catalog["heroes"][str(ident)]["quality"] for ident in recruitable}
        cached = {
            "1": [ident for ident in recruitable if 2 <= quality[ident] <= 4],
            "2": [ident for ident in recruitable if 3 <= quality[ident] <= 5],
            "3": [ident for ident in recruitable if 4 <= quality[ident] <= 5],
        }
        catalog._summon_pools = cached
    return cached

