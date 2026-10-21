"""Original-client inspired 培养 (training) rules.

The 2015 client (`lua/ui/trainingUI.lua`) only contains the presentation layer;
the authoritative random roll lived on the retired game server.  Everything that
*is* present in the APK is reproduced here verbatim:

* four options: 培养 / 培养10次 / 精心培养 / 精心培养10次;
* ordinary training costs 5 蟠桃 (50 for ten), intensive training costs 1 元宝
  (10 for ten) and does not consume 蟠桃;
* the ten-times guard in `trainingUI.checkTenTimeTraining`: 10 potential for the
  ordinary batch and 30 for the intensive batch (or two trained stats when the
  potential pool is empty);
* potential is consumed by the roll.  When the pool is empty the client shows a
  different stat going down and the trained stat going up (reference result:
  HP -40 / 攻击 +40), so training becomes a redistribution.

The reference screenshots give two exact growth checkpoints for the potential
pool (Lv.15 = 146, Lv.95 = 1,370).  The local save has no server history, so the
pool is reconstructed by linear interpolation through those checkpoints:

    potential(level) = max(30, 146 + floor((level - 15) * 153 / 10))

This is the only inferred value; it is documented in TRAINING.md and isolated
in `potential_total` so it can be replaced if a server capture appears.
"""
import random

STATS = ("hp", "attack", "defense", "magic")
STAT_NAMES = {"hp": "生命", "attack": "攻击", "defense": "防御", "magic": "法力"}
PEACH_KEY = "i1001"
PEACH_SEED = 169
STARTER_PEACHES = 169

# kind: (peaches, gold, rolls, intensive)
OPTIONS = {
    1: (5, 0, 1, False),
    2: (50, 0, 10, False),
    3: (0, 1, 1, True),
    4: (0, 10, 10, True),
}


def potential_total(level):
    """Reference checkpoints: Lv.15 -> 146, Lv.95 -> 1370."""
    level = max(1, int(level))
    return max(30, 146 + (level - 15) * 153 // 10)


def _blank():
    return {"bonus": {stat: 0 for stat in STATS}, "level": 1, "pending": None}


def read(state, ident, level):
    """Read-only view; never creates save data during rendering."""
    data = (state.get("training") or {}).get(str(ident)) or _blank()
    result = {"bonus": {stat: int((data.get("bonus") or {}).get(stat, 0))
                        for stat in STATS},
              "potential": int(data.get("potential", 0)),
              "level": int(data.get("level", level)), "pending": data.get("pending")}
    # Older saves (or a level-up performed before this module existed) are
    # normalised on read so the UI still sees a coherent pool.
    if result["level"] < int(level):
        result["level"] = int(level)
        result["potential"] = potential_total(level)
    return result


def ensure(state, catalog):
    """Initialise per-hero potential and grant the reference peach allowance."""
    state.setdefault("training", {})
    for ident, level in state.get("heroes", {}).items():
        data = state["training"].setdefault(str(ident), _blank())
        data.setdefault("bonus", {stat: 0 for stat in STATS})
        for stat in STATS:
            data["bonus"].setdefault(stat, 0)
        old_level = int(data.get("level", 1))
        if not data.get("potential_init_ok"):
            if (int(data.get("potential", 0)) == 0
                    and not any(int(data["bonus"].get(stat, 0)) for stat in STATS)
                    and not data.get("pending")):
                data["potential"] = potential_total(old_level)
            data["potential_init_ok"] = True
        if "potential" not in data:
            data["potential"] = potential_total(old_level)
        if int(level) > old_level:
            data["potential"] += potential_total(level) - potential_total(old_level)
            data["level"] = int(level)
        elif int(level) < old_level:
            data["level"] = int(level)
    # The reference training screen starts with 169 蟠桃.  Existing saves keep
    # their inventory untouched apart from this one-time grant.
    bag = state.get("inventory")
    if bag and bag.get("entries") and not state.get("training_peach_seed"):
        count = sum(int(e.get("count", 0)) for e in bag["entries"]
                    if e.get("key") == PEACH_KEY)
        if count == 0 and int(state.get("battle_count", 0)) > 0:
            from .inventory import grant
            grant(state, PEACH_KEY, PEACH_SEED, catalog=catalog)
        state["training_peach_seed"] = True
        state["training_seed"] = True


def item_count(state, key):
    return sum(int(e.get("count", 0)) for e in
               (state.get("inventory") or {}).get("entries", [])
               if e.get("key") == key)


def _consume_item(state, key, count, error):
    bag = state.get("inventory") or {"entries": []}
    left = count
    for entry in list(bag.get("entries", [])):
        if entry.get("key") != key:
            continue
        used = min(left, int(entry.get("count", 0)))
        entry["count"] = int(entry.get("count", 0)) - used
        left -= used
        if entry["count"] <= 0:
            bag["entries"].remove(entry)
        if left == 0:
            return
    if left:
        raise error("蟠桃不足")


def _can_ten(data, intensive):
    """Exact guard from trainingUI.checkTenTimeTraining."""
    minimum = 30 if intensive else 10
    bonus = data["bonus"]
    nonzero = [value for value in bonus.values() if value > 0]
    if len(nonzero) == 1:
        return True
    if data["potential"] == 0:
        return sum(1 for value in bonus.values() if value >= minimum) >= 2
    return data["potential"] >= minimum


def _roll(data, target, kind, error):
    _, _, rolls, intensive = OPTIONS[kind]
    value = 0
    for _ in range(rolls):
        # 精心培养 costs 元宝 instead of 蟠桃 and gives three times the points;
        # this is why its 10x guard is 30 instead of the ordinary 10.
        value += random.randint(1, 5) * (3 if intensive else 1)
    # The client guard only checks that a source exists; never let a batch ask
    # for more points than potential plus the best other stat can supply.
    available = data["potential"] + max(
        (data["bonus"].get(stat, 0) for stat in STATS if stat != target), default=0)
    value = min(value, available)
    if value < (3 if intensive else 1):
        raise error("潜能点不足")
    used = min(value, data["potential"])
    need = value - used
    source = None
    if need > 0:
        candidates = sorted(((stat, data["bonus"].get(stat, 0))
                             for stat in STATS if stat != target), key=lambda x: -x[1])
        for stat, available in candidates:
            if available >= need:
                source = stat
                break
        if source is None:
            raise error("潜能点不足")
    return {"kind": kind, "rolls": rolls, "value": value, "increase": target,
            "potential_used": used, "decrease": source or "culture_point",
            "decrease_value": need}


def apply(state, op, args, catalog, error):
    training = state.setdefault("training", {})

    def integer(name):
        value = args.get(name)
        if type(value) is not int:
            raise error("参数必须是整数：" + name)
        return value

    ident = integer("hero")
    if str(ident) not in state.get("heroes", {}):
        raise error("尚未拥有该神仙")
    data = training.get(str(ident))
    if data is None:
        ensure(state, catalog)
        data = training[str(ident)]
    level = state["heroes"][str(ident)]
    data.setdefault("bonus", {stat: 0 for stat in STATS})
    for stat in STATS:
        data["bonus"].setdefault(stat, 0)

    if op == "train":
        if data.get("pending"):
            raise error("请先接受或放弃上次培养结果")
        kind = integer("kind")
        if kind not in OPTIONS:
            raise error("培养方式无效")
        peaches, gold, rolls, intensive = OPTIONS[kind]
        if rolls == 10 and not _can_ten(data, intensive):
            raise error("潜能点不足")
        if peaches > item_count(state, PEACH_KEY):
            raise error("蟠桃不足")
        if gold > int(state.get("gold", 0)):
            raise error("元宝不足")
        if peaches:
            _consume_item(state, PEACH_KEY, peaches, error)
        if gold:
            state["gold"] = int(state.get("gold", 0)) - gold
        target = random.choice(STATS)
        pending = _roll(data, target, kind, error)
        pending["cost"] = {"peaches": peaches, "gold": gold}
        data["pending"] = pending
        return "培养完成，请选择接受或放弃"

    if op in ("train_accept", "train_giveup"):
        pending = data.get("pending")
        if not pending:
            raise error("没有待确认的培养结果")
        if op == "train_accept":
            target = pending["increase"]
            data["bonus"][target] = int(data["bonus"].get(target, 0)) + int(pending["value"])
            if pending.get("potential_used"):
                data["potential"] = max(0, int(data.get("potential", 0)) -
                                        int(pending["potential_used"]))
            source = pending.get("decrease")
            if source in STATS and pending.get("decrease_value"):
                data["bonus"][source] = max(0, int(data["bonus"].get(source, 0)) -
                                            int(pending["decrease_value"]))
            data["pending"] = None
            return "培养成功"
        data["pending"] = None
        return "放弃培养"

    raise error("未知培养操作")


def view(state):
    """Compact training payload used by tooling and tests."""
    result = {}
    for ident, level in state.get("heroes", {}).items():
        data = read(state, ident, level)
        data["hero"] = int(ident)
        result[str(ident)] = data
    return result

