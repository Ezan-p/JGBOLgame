"""Original fate requirements / cheer ratios, with explicit local composition rules."""
import copy
import random
from decimal import Decimal, ROUND_FLOOR, ROUND_HALF_UP
from local_game.assets import Resources

STATS = ('hp', 'attack', 'defense', 'magic')
FIELDS = {1: 'hp', 2: 'magic', 3: 'attack', 4: 'defense'}
NAMES = ['乾', '坤', '震', '巽', '坎', '离', '艮', '兑']
STAT_COLUMNS = ('maxhp_plus', 'gongji_plus', 'fangyu_plus', 'maxmagic_plus')
RECOVER_COLUMNS = ('maxhp_recover', 'gongji_recover', 'fangyu_recover', 'maxmagic_recover')
# 1263 cheerSquadUI stat_req result maps server indexes 1..4 to hp/attack/defense/magic.
# The cost is not in the client CSV: the reference level-10 panel shows 20 charms + 10 gold.
REFINE_COST = dict(material=20, gold=10)
MAX_DYNAMIC = 7500  # cumulative *_recover in the original table: 0.5+0.7+0.9*7 = 7.5%


def build_synergy(root):
    r = Resources(root)
    fates = {}
    for row in r.rows('csv_config/fate_config.csv'):
        def get(prefix): return next(v for k, v in row.items() if k.startswith(prefix))
        hero = get('cortege_type')
        fates.setdefault(hero, []).append(dict(id=int(row['fate_type']), name=row['fate_name'],
            description=row['fate_desc'], stat=FIELDS[int(get('effect_field'))],
            percent=int(row['effect_value']), target_type=int(get('tartege_type')),
            targets=[int(i) for i in get('target_object_type').split('/') if i]))
    slots = {}
    raw = r.rows('csv_config/cortege_cheer_config.csv')
    for row in raw:
        order, level = row['cheer_order'], int(row['level'])
        s = slots.setdefault(order, dict(name=NAMES[int(order)-1], levels={}))
        s['levels'][str(level)] = dict(cost=int(row['upgrade_cost']),
            increments={stat: row[key] for stat, key in zip(STATS, STAT_COLUMNS)},
            recover={stat: row[key] for stat, key in zip(STATS, RECOVER_COLUMNS)})
    for s in slots.values():
        totals = dict.fromkeys(STATS, Decimal(0))
        recovered = dict.fromkeys(STATS, Decimal(0))
        for level in sorted(s['levels'], key=int):
            row = s['levels'][level]
            for stat in STATS:
                totals[stat] += Decimal(row['increments'][stat])
                recovered[stat] += Decimal(row['recover'][stat])
            row['ratios'] = {stat: str(totals[stat]) for stat in STATS}
            row['recover_caps'] = {stat: str(recovered[stat]) for stat in STATS}
    sources = ['csv_config/fate_config.csv','csv_config/cortege_cheer_config.csv',
               'lua/ui/cheerSquadUI.lua','lua/ui/charPositionUI.lua','lua/common/common_def.lua','lua/data.lua']
    resources = [n for n in r.names() if n.startswith('v2/cheerUI/') and n.endswith('.png')]
    for name in resources: r.read(name)
    return dict(schema=2, fates=fates, slots=slots, material='i1015',
                refine=dict(REFINE_COST), max_dynamic=MAX_DYNAMIC,
                sources=[r.source(n) for n in sources], resources=resources,
                rules='local: eight normal cheer slots; level ratios + refine dynamic; equipment/passive -> additive fates -> nonrecursive cheer; one cheer per combat slot')


def _dynamic(slot):
    saved = slot.get('dynamic') or {}
    return {stat: int(saved.get(stat, 0)) for stat in STATS}


def _pending(slot):
    row = slot.get('refine')
    if not isinstance(row, dict):
        return None
    gain, lose, rate = row.get('gain'), row.get('lose'), row.get('rate')
    if gain not in STATS or lose not in STATS or gain == lose or type(rate) is not int or rate <= 0:
        return None
    return dict(gain=gain, lose=lose, rate=rate)


def _slot(saved):
    return dict(hero=int(saved.get('hero', 0)), target=int(saved.get('target', 0)),
                level=int(saved.get('level', 1)), dynamic=_dynamic(saved),
                refine=_pending(saved))


def slots(state):
    saved = state.get('support', {}).get('slots', {})
    return {str(i): _slot(saved.get(str(i), {})) for i in range(1, 9)}


def slot_ratios(slot, config):
    row = config['levels'][str(slot['level'])]
    dynamic = _dynamic(slot)
    return {stat: Decimal(row['ratios'][stat]) + Decimal(dynamic[stat]) / 100000 for stat in STATS}


def support_ids(state):
    return {s['hero'] for s in slots(state).values() if s['hero']}


def fate_status(hero, state, data, inventory):
    assigned = set(state['lineup']) | support_ids(state)
    equips, spells = set(), {hero['skill_id']}
    for e in state.get('inventory', {}).get('entries', []):
        if e['hero'] != hero['id']: continue
        item = inventory['items'][e['key']]
        (spells if item['category'] == 4 else equips).add(item['id'])
    result = []
    for f in data['fates'].get(str(hero['id']), []):
        available = {4: assigned, 5: equips, 6: spells}[f['target_type']]
        missing = [i for i in f['targets'] if i not in available]
        # Idle owned heroes cannot trigger roster effects merely by being owned.
        # Updated cheerSquadUI.getFateStatus checks only character and spell bonds.
        applicable = not (hero['id'] in support_ids(state) and f['target_type'] == 5)
        result.append({**f, 'active': hero['id'] in assigned and applicable and not missing,
                       'missing': missing, 'applicable': applicable})
    return result


def round_value(value):
    return int(value.quantize(Decimal('1'), rounding=ROUND_HALF_UP))


def evaluate(base_heroes, state, data, inventory):
    """Two passes prevent support recursion and keep UI and battle values identical."""
    heroes = {h['id']: copy.deepcopy(h) for h in base_heroes}
    for h in heroes.values():
        h['supporting'] = h['id'] in support_ids(state)
        h['fates'] = fate_status(h, state, data, inventory)
        percent = {stat: sum(f['percent'] for f in h['fates'] if f['active'] and f['stat']==stat) for stat in STATS}
        h['pre_fate_stats'] = {stat:h.get(stat,0) for stat in STATS}
        h['fate_percent'] = percent
        h['fate_bonus'] = {stat:round_value(Decimal(h.get(stat,0))*Decimal(percent[stat])/100) for stat in STATS}
        for stat in STATS: h[stat] = h.get(stat,0)+h['fate_bonus'][stat]
        h['support_bonus'] = dict.fromkeys(STATS, 0)
        h['support_sources'] = []
    snapshot = {i:{s:h[s] for s in STATS} for i,h in heroes.items()}
    views = []
    for order, slot in slots(state).items():
        config = data['slots'][order]; row = config['levels'][str(slot['level'])]
        ratios = slot_ratios(slot, config)
        source = heroes.get(slot['hero'])
        target = state['lineup'][slot['target']-1] if 1 <= slot['target'] <= len(state['lineup']) else 0
        bonus = dict.fromkeys(STATS, 0)
        if source and source['quality'] >= 5 and target:
            bonus = {stat:int((Decimal(snapshot[source['id']][stat])*ratios[stat]).to_integral_value(rounding=ROUND_FLOOR)) for stat in STATS}
            for stat in STATS:
                heroes[target][stat] += bonus[stat]
                heroes[target]['support_bonus'][stat] += bonus[stat]
            heroes[target]['support_sources'].append(dict(slot=int(order), hero=source['id'], bonus=bonus))
        next_row = config['levels'].get(str(slot['level']+1))
        max_level = max(map(int,config['levels']))
        views.append(dict(slot=int(order), name=config['name'], **slot, target_hero=target, bonus=bonus,
            ratios={s:float(v) for s,v in ratios.items()},
            base_ratios={s:float(v) for s,v in row['ratios'].items()},
            dynamic_pct={s:slot['dynamic'][s]/1000 for s in STATS},
            recover={s:float(v) for s,v in row['recover'].items()},
            next_increments=({s:float(v) for s,v in next_row['increments'].items()} if next_row
                              else dict.fromkeys(STATS, 0.0)),
            next_cost=next_row['cost'] if next_row else 0, max_level=max_level,
            can_refine=slot['level']==max_level, refine_cost=dict(data['refine'])))
    material = sum(e['count'] for e in state.get('inventory',{}).get('entries',[]) if e['key']==data['material'])
    return heroes, dict(slots=views, material=material, refine=dict(data['refine']))


def apply(state, op, args, catalog, error):
    def check(test, message):
        if not test: raise error(message)
    def integer(key):
        check(type(args.get(key)) is int, '参数必须是整数：'+key)
        return args[key]
    order = integer('slot')
    check(1 <= order <= 8, '助阵位无效')
    all_slots = slots(state); s = all_slots[str(order)]
    if op == 'support_assign':
        hero = integer('hero')
        check(hero == 0 or str(hero) in state['heroes'], '尚未拥有该神仙')
        check(hero not in state['lineup'], '请先让该神仙退出出战阵容')
        check(not hero or not any(v['hero']==hero for k,v in all_slots.items() if k!=str(order)), '该神仙已在其他助阵位')
        s['hero'] = hero
        if not hero:
            s['target'] = 0
            s['refine'] = None
        elif catalog['heroes'][str(hero)]['quality'] < 5:
            s['target'] = 0
        notice = '助阵伙伴已保存；仙缘与属性已刷新'
    elif op == 'support_target':
        target = integer('target')
        check(0 <= target <= len(state['lineup']) and (target == 0 or state['lineup'][target-1]), '请选择当前出战阵位')
        check(s['hero'] and catalog['heroes'][str(s['hero'])]['quality'] >= 5, '五星助阵神仙才能传递属性')
        # Assigning an already supported combat slot transfers its one support link.
        for other in all_slots.values():
            if other['target'] == target: other['target'] = 0
        s['target'] = target
        notice = '受助阵位已保存'
    elif op == 'support_buy_material':
        from local_game.inventory import grant
        count = integer('count')
        check(1 <= count <= 100, '每次兑换1至100张')
        key = catalog['synergy']['material']
        cost = catalog['inventory']['items'][key]['price'] * count
        check(state['silver'] >= cost, '银两不足')
        state['silver'] -= cost
        grant(state, key, count, catalog=catalog['inventory'])
        notice = '乾坤符箓已放入包裹'
    elif op == 'support_upgrade':
        data = catalog['synergy']; row = data['slots'][str(order)]['levels'].get(str(s['level']+1))
        check(row is not None, '助阵位已达到最高阶')
        entries = state.get('inventory',{}).get('entries',[])
        materials = [e for e in entries if e['key']==data['material']]
        check(sum(e['count'] for e in materials)>=row['cost'], '进阶材料不足')
        remaining = row['cost']
        for e in materials:
            amount = min(remaining,e['count']); e['count']-=amount;remaining-=amount
            if not e['count']: entries.remove(e)
        s['level']+=1
        notice='助阵位进阶成功'
    elif op == 'support_refine':
        data = catalog['synergy']; config = data['slots'][str(order)]
        check(s['level'] == max(map(int, config['levels'])), '阵法达到10阶后即可进行洗练')
        check(not s['refine'], '已有待确认的洗练结果')
        row = config['levels'][str(s['level'])]
        caps = {stat: int(Decimal(row['recover_caps'][stat]) * 100000) for stat in STATS}
        steps = {stat: int(Decimal(row['recover'][stat]) * 100000) for stat in STATS}
        choices = []
        for gain in STATS:
            for lose in STATS:
                if gain == lose: continue
                rate = min(steps[gain], steps[lose])
                if (rate > 0 and s['dynamic'][gain] + rate <= caps[gain]
                        and s['dynamic'][lose] - rate >= -caps[lose]):
                    choices.append((gain, lose, rate))
        check(choices, '该阵位已无可洗练属性')
        cost = data['refine']
        entries = state.get('inventory',{}).get('entries',[])
        materials = [e for e in entries if e['key']==data['material']]
        check(sum(e['count'] for e in materials) >= cost['material'],
              '洗练所需乾坤符箓不足')
        check(state.get('gold', 0) >= cost['gold'], '元宝不足')
        remaining = cost['material']
        for e in materials:
            amount = min(remaining, e['count'])
            e['count'] -= amount
            remaining -= amount
            if not e['count']:
                entries.remove(e)
        state['gold'] = state.get('gold', 0) - cost['gold']
        gain, lose, rate = random.SystemRandom().choice(choices)
        s['refine'] = dict(gain=gain, lose=lose, rate=rate)
        notice = '洗练结果已生成，请选择接受或放弃'
    elif op == 'support_refine_accept':
        check(s['refine'], '没有待确认的洗练结果')
        pending = s['refine']
        s['dynamic'][pending['gain']] += pending['rate']
        s['dynamic'][pending['lose']] -= pending['rate']
        s['refine'] = None
        notice = '洗练属性已生效'
    elif op == 'support_refine_cancel':
        check(s['refine'], '没有待确认的洗练结果')
        s['refine'] = None
        notice = '已放弃本次洗练结果'
    else: raise error('未知助阵操作')
    state['support'] = dict(version=2, slots=all_slots)
    return notice


def tidy_targets(state):
    if 'support' in state:
        for s in state['support']['slots'].values():
            if s['target'] > len(state['lineup']) or (s['target'] and not state['lineup'][s['target']-1]): s['target'] = 0
