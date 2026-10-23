"""Original role-level thresholds; explicit conversion of old local saves."""


def info(state, levels):
    if not state.get("role_exp_schema"):
        exp = int(state.get("experience", 0))
        return 1 + exp // 200, exp % 200, 200
    remaining = max(0, int(state.get("experience", 0)))
    ordered = sorted(levels, key=int)
    for key in ordered:
        threshold = levels[key]["upgrade_exp"]
        if remaining < threshold or key == ordered[-1]:
            return int(key), remaining, threshold
        remaining -= threshold
    raise ValueError("Missing original role experience table")


def migrate(state, levels):
    if state.get("role_exp_schema"):
        return
    old_exp = max(0, int(state.get("experience", 0)))
    old_level, old_cur = 1 + old_exp // 200, old_exp % 200
    level = min(old_level, max(map(int, levels)))
    threshold = levels[str(level)]["upgrade_exp"]
    state["experience"] = sum(v["upgrade_exp"] for k, v in levels.items() if int(k) < level)
    state["experience"] += old_cur * threshold // 200
    state["role_exp_schema"] = 1
    state["role_exp_migration"] = dict(old_experience=old_exp, old_level=old_level,
                                       converted_experience=state["experience"])


def read_levels(resources):
    return {row["level"]: {key: int(value) for key, value in row.items()}
            for row in resources.rows("csv_config/role_level_config.csv")}


def award_battle(state, levels, won, *, resource="strength"):
    """Apply an unmodified CSV reward at the pre-battle level.

    Resource selection is a local settlement policy, not recovered server code.
    Original strength (体力) and energy (精力) are separate reward columns.
    """
    if resource not in ("strength", "energy"):
        raise ValueError("Unknown original battle resource")
    migrate(state, levels)
    level = info(state, levels)[0]
    field = ("energy_" if resource == "energy" else "") + ("win_exp" if won else "lose_exp")
    amount = levels[str(level)][field]
    state["experience"] += amount
    return amount
