"""Eight-position battle reports. Server-only formulas/arbitration remain local rules."""
import copy
import random


def spell_value(skill, level=1):
    row = {k.split('(')[0]: v for k, v in skill.get('original', {}).items()}
    field = {1: 'gongji_plus', 2: 'fangyu_plus', 3: 'magic_plus', 5: 'hp_plus'}.get(int(row.get('effect_field', 4)), 'intensity')
    level = max(1, min(int(level), max(1, int(row.get('top_level', 10)))))
    return float(row.get(field, 0)) + float(row.get('upgrade_plus', 0)) * (level-1)


def spell_loadout(unit):
    return unit.get('spells', [{'id': unit.get('skill_id', 1), 'level': 1, 'position': 1}])


def apply_passives(unit, skills):
    """Only for raw catalog units; equipped roster stats are already finalized."""
    if unit.get('battle_stats_ready'):
        return unit
    percent = {}
    for spell in spell_loadout(unit):
        skill = skills.get(str(spell['id']), {})
        if not skill or skill.get('active'):
            continue
        row = {k.split('(')[0]: v for k, v in skill.get('original', {}).items()}
        stat = {1: 'attack', 2: 'defense', 3: 'magic', 5: 'hp'}.get(int(row.get('effect_field', 0)))
        if stat:
            percent[stat] = percent.get(stat, 0) + spell_value(skill, spell['level'])/100
    for stat, amount in percent.items():
        unit[stat] = round(unit.get(stat, 0)*(1+amount))
    unit['battle_stats_ready'] = True
    return unit


def resolve(allies, enemies, skills, opening_skill=False, seed=0):
    rng = random.Random(seed)
    teams = copy.deepcopy((allies, enemies))
    for side, team in enumerate(teams):
        occupied = set()
        for index, unit in enumerate(team):
            slot = unit.get('lineup_slot', index+1)
            if not 1 <= slot <= 8 or slot in occupied:
                raise ValueError('Battle positions must be unique and between 1 and 8')
            occupied.add(slot)
            apply_passives(unit, skills)
            unit['passives'] = [dict(id=s['id'], name=skills[str(s['id'])]['name'], level=s['level'])
                                for s in spell_loadout(unit) if str(s['id']) in skills
                                and not skills[str(s['id'])].get('active')
                                and spell_value(skills[str(s['id'])], s['level']) > 0]
            unit.update(uid=f'{side}-{slot-1}', side=side, slot=slot, max_hp=unit['hp'], in_field=slot<=4)
        team.sort(key=lambda u: u['slot'])
    initial = copy.deepcopy(teams[0] + teams[1])
    events = []
    action_step = 0

    def living(side):
        return [u for u in teams[side] if u['hp'] > 0 and u['in_field']]

    def enter_reserves(turn):
        for side, team in enumerate(teams):
            slots = {u['slot']: u for u in team}
            for slot in range(5, 9):
                reserve, front = slots.get(slot), slots.get(slot-4)
                if reserve and not reserve['in_field'] and reserve['hp'] > 0 and (not front or front['hp'] <= 0):
                    if reserve.get('step', 0) > action_step:
                        continue
                    reserve['in_field'] = True
                    events.append(dict(kind='enter', turn=turn, actor=reserve['uid'], slot=slot,
                                       replaces=front['uid'] if front else '', hits=[], skill_id=1,
                                       skill=False, skill_name='援军入阵', text=reserve['name']+' · 援军入阵'))

    enter_reserves(0)
    for turn in range(1, 31):
        # Snapshot initiative: reinforcements act starting next round, never twice in a round.
        order = living(0) + living(1)
        for actor in order:
            side = actor['side']
            opponents = living(1-side)
            if actor['hp'] <= 0 or not opponents:
                continue
            candidates = []
            for spell in sorted(spell_loadout(actor), key=lambda s: s['position']):
                spec = skills.get(str(spell['id']), {})
                row = {k.split('(')[0]: v for k, v in spec.get('original', {}).items()}
                if spec.get('active') and spell['id'] != 1:
                    candidates.append((spell, spec, max(0, min(100, float(row.get('use_probability', 0))))))
            roll = rng.random()*100
            chosen = None
            cumulative = 0
            for spell, spec, probability in candidates:
                cumulative += probability
                if roll < min(100, cumulative):
                    chosen = (spell, spec)
                    break
            if opening_skill and turn == 1 and candidates:
                chosen = candidates[0][:2]  # Explicit preview fixture, never used by service.
            spell, spec = chosen if chosen else ({'id': 1, 'level': 1, 'position': 0}, {})
            sid, healing = spell['id'], spell['id'] == 6
            targets = ([u for u in living(side) if u['hp'] < u['max_hp']] if healing
                       else opponents if spec.get('multi') else opponents[:1])
            if not targets:
                targets, sid, healing, spec = opponents[:1], 1, False, {}
            strength = spell_value(spec, spell['level']) if sid != 1 else 0
            hits = []
            for target in targets:
                if healing:
                    amount = min(target['max_hp']-target['hp'], max(1, round(actor['attack']*.8)))
                    damage = -amount
                else:
                    # Original formula/party_formula are opaque server IDs, not expressions.
                    power = actor['attack'] + (actor.get('magic', 0)*strength/100 if sid != 1 else 0)
                    damage = min(target['hp'], max(1, round(power-target['defense']*.45)))
                target['hp'] -= damage
                hits.append(dict(target=target['uid'], damage=damage, hp=target['hp']))
            name = spec.get('name', '普通攻击')
            events.append(dict(turn=turn, actor=actor['uid'], skill=sid!=1, skill_id=sid,
                               skill_name=name, skill_level=spell['level'], spell_position=spell['position'],
                               strength=strength, roll=round(roll, 6),
                               chances=[dict(id=s['id'], position=s['position'], probability=p) for s, _, p in candidates],
                               hits=hits, kind='heal' if healing else 'skill' if sid!=1 else 'attack',
                               **hits[0], text=f"{actor['name']} · {name}"))
            action_step += 1
            enter_reserves(turn)
        if not all(living(side) for side in (0, 1)):
            break
    won = bool(living(0)) and not living(1)
    return dict(units=initial, events=events, won=won, turns=turn, seed=seed,
                rules='local-v3', report_version=3)
