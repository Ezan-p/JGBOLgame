"""Journey progression using original tables and documented client rules.

Combat remains the existing local resolver. Inferred sampling and experience
distribution are isolated in journey_rules and reported in every settlement.
"""
import time

from . import inventory, journey_rules


def day_number(now=None):
    # Original mainUI.getRefreshTime resets at midnight. This local Chinese
    # deployment uses Asia/Shanghai; no original server timezone was recovered.
    return int(((time.time() if now is None else now) + 8 * 3600) // 86400)


def ensure(state):
    journey = state.setdefault("journey", {"schema": 1, "stars": {},
        "chapter_claimed": [], "daily": {}})
    today = day_number()
    if journey.get("day", -1) < today:
        journey["day"] = today
        journey["daily"] = {}
    return journey


def restore_progress(state, stages):
    """Resume completed frontiers, including saves capped by the old ten-stage build."""
    frontier = max(1, min(len(stages), int(state.get("unlocked", 1))))
    while frontier < len(stages) and state.get("wins", {}).get(str(frontier), 0) > 0:
        frontier += 1
    state["unlocked"] = frontier


def stage_views(state, stages):
    restore_progress(state, stages)
    journey = ensure(state)
    # Detailed, immutable reward/roster data lives in local_journey_data.lua.
    # Avoid sending it 597 times on every bag, formation or login operation.
    keys = ("id", "original_id", "name", "chapter", "energy", "require_level",
            "exp", "silver", "daily_limit")
    return [{**{k: s[k] for k in keys},
             "unlocked": s["id"] <= state["unlocked"],
             "cleared": str(s["id"]) in state["wins"],
             "stars": max(journey["stars"].get(str(s["original_id"]), 0),
                          journey.get("legacy_stars", {}).get(str(s["original_id"]), 0)),
             "daily_used": journey["daily"].get(str(s["original_id"]), 0)}
            for s in stages]


def restore_star_history(state, stages, responses):
    """Recover display-only stars; never replay rewards or change claim eligibility."""
    journey = ensure(state)
    if journey.get("star_history_version") == 1:
        return
    by_local = {s["id"]: s["original_id"] for s in stages}
    recovered = {}
    for reply in responses:
        battle = reply.get("battle")
        if not battle or not battle.get("won"):
            continue
        local_id = battle.get("stage", {}).get("id")
        if local_id not in by_local or not state.get("wins", {}).get(str(local_id), 0):
            continue
        stars = battle.get("stars")
        if type(stars) is not int or not 1 <= stars <= 3:
            try:
                final = battle.get("final_units")
                if not final:
                    if not battle.get("events"):
                        continue
                    units = {u["uid"]: dict(uid=u["uid"], hp=u["hp"], max_hp=u["max_hp"])
                             for u in battle["units"]}
                    for event in battle["events"]:
                        for change in [event, *event.get("hits", []), *event.get("changes", [])]:
                            target = change.get("target", change.get("uid"))
                            if target in units:
                                for field in ("hp", "max_hp"):
                                    if field in change:
                                        units[target][field] = change[field]
                    final = list(units.values())
                stars = evaluate_stars({**battle, "final_units": final})
            except (KeyError, TypeError, ValueError):
                continue
        key = str(by_local[local_id])
        recovered[key] = max(recovered.get(key, 0), stars)
    for local_id, wins in state.get("wins", {}).items():
        if wins > 0 and local_id.isdigit() and int(local_id) in by_local:
            # A recorded victory proves at least one star, never two or three.
            recovered.setdefault(str(by_local[int(local_id)]), 1)
    journey["legacy_stars"] = recovered
    journey["star_history_version"] = 1


def evaluate_stars(report):
    """newbie_content1 + fightUI.showAllHp: 70% / 40% total remaining HP.

    This evaluates the local report; it is not an imported server pass_star.
    Use integer comparisons so exact 70% and 40% boundaries are stable.
    """
    if not report["won"]:
        return 0
    ours = {u["uid"] for u in report["units"] if u["side"] == 0}
    final = [u for u in report["final_units"] if u["uid"] in ours]
    if len(final) != len(ours) or not final:
        raise ValueError("Journey report is missing final allied HP")
    maximum = sum(u["max_hp"] for u in final)
    remaining = sum(max(0, min(u["hp"], u["max_hp"])) for u in final)
    if maximum <= 0:
        raise ValueError("Journey report has invalid total HP")
    return 3 if remaining * 10 >= maximum * 7 else 2 if remaining * 10 >= maximum * 4 else 1


def grant_prizes(state, prizes, catalog, reason):
    """Grant already-selected entries, retaining original type/count/level."""
    awarded = []
    for prize in prizes:
        kind = prize["type"]
        if kind in (5, 6):
            key = ("i" if kind == 5 else "s") + str(prize["id"])
            inventory.grant(state, key, prize["count"], prize["level"], catalog["inventory"])
        elif kind in (11, 12):
            currency = "gold" if kind == 11 else "silver"
            state[currency] = state.get(currency, 0) + prize["count"]
        else:
            raise ValueError(f"Unsupported journey reward type: {kind}")
        awarded.append({**prize, "reason": reason})
    return awarded


def settle(game, state, stage, report, catalog, allies):
    journey = ensure(state)
    key = str(stage["original_id"])
    won = report["won"]
    first = won and str(stage["id"]) not in state["wins"]
    stars = evaluate_stars(report)
    first_three = stars == 3 and journey["stars"].get(key, 0) < 3
    silver = stage["silver"] * (2 if first_three else 1) if won else 0
    state["energy"] -= stage["energy"]
    state["silver"] += silver
    state["battle_count"] += 1
    journey["daily"][key] = journey["daily"].get(key, 0) + 1
    inferred = journey_rules.rewards(stage, first, first_three, won, report["seed"])
    from .role_progression import award_battle
    role_exp = award_battle(state, catalog["role_levels"], won)
    state["level"] = game.role_level(state)
    hero_exp = []
    for unit in allies:
        if inferred["hero_exp"]:
            level, cur, gained_levels, gained_exp, unused = game.apply_hero_exp(state, unit["id"], inferred["hero_exp"])
        else:
            ident = str(unit["id"])
            level, cur = state["heroes"][ident], state.get("hero_exp", {}).get(ident, 0)
            gained_levels = gained_exp = unused = 0
        hero_exp.append(dict(id=unit["id"], name=unit["name"], slot=unit["lineup_slot"],
                             base_exp=inferred["hero_exp"], gained=gained_exp, unused=unused,
                             level=level, cur_exp=cur, levels_gained=gained_levels))
    awards = grant_prizes(state, inferred["drops"], catalog, inferred["source"])
    if won:
        state["wins"][str(stage["id"])] = state["wins"].get(str(stage["id"]), 0) + 1
        state["unlocked"] = min(len(catalog["stages"]), max(state["unlocked"], stage["id"] + 1))
        journey["stars"][key] = max(stars, journey["stars"].get(key, 0))
        if first_three:
            awards += grant_prizes(state, stage["three_star"], catalog, "first_three_star")
        chapter = next(c for c in catalog["journey_chapters"] if c["id"] == stage["map_id"])
        if chapter["id"] not in journey["chapter_claimed"] and all(
                journey["stars"].get(str(s["original_id"]), 0) == 3
                for s in catalog["stages"] if s["map_id"] == chapter["id"]):
            awards += grant_prizes(state, chapter["prize"], catalog, "chapter_three_star")
            journey["chapter_claimed"].append(chapter["id"])
    receipt = dict(number=state["battle_count"], stage=stage["original_id"],
                   first_clear=first, first_three_star=first_three, stars=stars,
                   rules=journey_rules.VERSION, random_audit=inferred["audit"],
                   bonus_exp=inferred["bonus_exp"], role_exp=role_exp, hero_exp=hero_exp)
    journey["last_settlement"] = receipt
    return dict(silver=silver, experience=role_exp, hero_exp_base=stage["exp"],
                first_clear=first, first_three_star=first_three, stars=stars,
                awarded=awards, settlement=receipt, hero_exp=hero_exp,
                number=state["battle_count"], settlement_status="client_config_inferred_rules_v1")
