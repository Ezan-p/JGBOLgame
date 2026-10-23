"""Explicit, replaceable inferences where the original server is unavailable.

Authorized by the user on 2026-10-23. Numeric inputs come from original CSVs;
the sampling/distribution semantics below are reconstructions, not recovered code.
"""
import random

VERSION = "journey-inferred-v1"
ASSUMPTIONS = {
    "random_prize": "Each entry independently rolls an integer 1..100; hit if roll <= rate. Multiple drops are possible.",
    "first_random_prize": "On the first victory, a nonempty first-drop list replaces the ordinary random list.",
    "first_win_prize": "On the first victory, exp_count is bonus hero experience with rate percent chance; added after the three-star multiplier.",
    "hero_exp": "Every deployed hero, including defeated/reserve heroes, receives base exp; first three-star victory doubles base exp. Reuse the original exp-book level caps and efficiency bands for battle experience.",
    "role_exp": "Use the pre-battle role level win_exp or lose_exp; first three-star does not double role experience. Do not add cortege_exp to stage exp.",
    "attempt": "Every completed local battle, including loss/draw, consumes the listed strength and one daily attempt; no refunds. Draw uses lose_exp.",
    "stars": "Apply client 70%/40% total HP markers to the local battle final HP, including reserves and changed max HP; highest star count persists.",
    "legacy_save": "Preserve old cleared flags and unlock IDs; old star counts were never stored, so old victories do not imply three stars.",
    "daily_timezone": "Reset at 00:00 Asia/Shanghai. Client midnight reset is confirmed; original server timezone is not.",
}


def rewards(stage, first, first_three, won, seed):
    rng = random.Random(f"{VERSION}:{seed}:{stage['original_id']}")
    audit = []

    def hit(rate, source, ident):
        if not 0 <= rate <= 100:
            raise ValueError("Rate outside the inferred percentage range")
        roll = rng.randint(1, 100)
        passed = roll <= rate
        audit.append(dict(source=source, id=ident, rate=rate, roll=roll, hit=passed))
        return passed

    drops = []
    bonus = 0
    if won:
        source = "first_drops" if first and stage["first_drops"] else "drops"
        for prize in stage[source]:
            if hit(prize["rate"], source, prize["id"]):
                drops.append(prize)
        if first and stage["first_win"]:
            entry = stage["first_win"]
            if hit(entry["rate"], "first_win_prize", stage["original_id"]):
                bonus = entry["exp_count"]
    return dict(drops=drops, source=source if won else "none", bonus_exp=bonus,
                hero_exp=stage["exp"] * (2 if first_three else 1) + bonus if won else 0,
                audit=audit, rules=VERSION)
