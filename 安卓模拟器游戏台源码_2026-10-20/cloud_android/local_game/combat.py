"""Deterministic local battle reports; not the unavailable official server formula."""
import copy


def resolve(allies, enemies, skills, opening_skill=False):
    teams = copy.deepcopy((allies, enemies))
    for side, team in enumerate(teams):
        for slot, unit in enumerate(team):
            unit.update(uid=f"{side}-{slot}", side=side, slot=slot + 1, max_hp=unit['hp'])
    initial = copy.deepcopy(teams[0] + teams[1])
    events = []
    for turn in range(1, 31):
        for side, team in enumerate(teams):
            for actor in team:
                opponents = [u for u in teams[1-side] if u['hp'] > 0]
                if actor['hp'] <= 0 or not opponents:
                    continue
                native = skills.get(str(actor.get('skill_id')), {})
                powered = turn % 3 == 0 or opening_skill and turn == 1
                active = powered and native.get('active', False)
                skill_id = actor['skill_id'] if active else 1
                healing = skill_id == 6
                targets = ([u for u in team if u['hp'] > 0 and u['hp'] < u['max_hp']]
                           if healing else opponents if active and native.get('multi') else opponents[:1])
                if not targets:  # Do not spend a healing action on an undamaged team.
                    targets, skill_id, healing, active = opponents[:1], 1, False, False
                hits = []
                for index, target in enumerate(targets):
                    if healing:
                        amount = min(target['max_hp']-target['hp'], max(1, round(actor['attack']*.8)))
                        target['hp'] += amount
                        damage = -amount
                    else:
                        factor = (actor.get("skill_factor", 1.45) if active else 1.45 if powered else 1) * (.55 if index else 1)
                        damage = min(target['hp'], max(1, round(actor['attack']*factor-target['defense']*.45)))
                        target['hp'] -= damage
                    hits.append({'target': target['uid'], 'damage': damage, 'hp': target['hp']})
                name = native.get('name', '普通攻击') if active else '蓄力一击' if powered else '普通攻击'
                events.append({'turn': turn, 'actor': actor['uid'], 'skill': powered,
                               'skill_id': skill_id, 'skill_name': name, 'hits': hits,
                               'kind': 'heal' if healing else 'skill' if active else 'attack',
                               **hits[0], 'text': f"{actor['name']} · {name}"})
        if not all(any(u['hp'] > 0 for u in t) for t in teams):
            break
    won = any(u['hp'] > 0 for u in teams[0]) and not any(u['hp'] > 0 for u in teams[1])
    return {'units': initial, 'events': events, 'won': won, 'turns': turn,
            'rules': 'local-v2', 'report_version': 2}
