"""Evidence-backed ext_skill operations. Unknown server rolls never spend assets."""
from .battle_rules import normalized

OPEN_LEVEL = 38
LEVEL_GATE_ENABLED = False  # Temporary UI integration override requested by user.
UPGRADE_PROGRESS = (500, 1000, 1500, 3000)


def build_rules(resources):
    def rows(name):
        return [normalized(r) for r in resources.rows('csv_config/' + name + '.csv')]
    return dict(open_level=OPEN_LEVEL if LEVEL_GATE_ENABLED else 0, original_open_level=OPEN_LEVEL, max_level=5, upgrade_progress=list(UPGRADE_PROGRESS),
                lock_cost={r['lock_count']: int(r['cost']) for r in rows('ext_skill_lock_cost')},
                decompose={r['category']: r for r in rows('material_transform') if r['category'] in ('102', '103')},
                transforms={r['category']: r for r in rows('jingpo_transform')})


def describe(item, entry, catalog):
    rule = catalog['combat_rules']['traits'][str(item['id'])]
    level = max(1, min(5, int(entry['level'])))
    text = rule['description']
    for group in rule['levels']:
        text = text.replace('%s', format(group[level - 1] * 100, '.8g') + '%', 1)
    progress = int(entry.get('prob_compen', 0))
    target = UPGRADE_PROGRESS[level - 1] if level < 5 else 0
    transform = catalog['essence']['transforms'].get(str(item['id']), {})
    spec = transform.get('des_material', '')
    candidates = [int(part.split('|')[1]) for part in spec.split('/') if part]
    return dict(description=text, progress=progress, progress_target=target,
                upgrade_batch_limit=min(500, max(0, target-progress)),
                transform_targets=candidates, transform_available=len(candidates) == 1 and level == 1,
                decompose_stones=(20 if item['quality'] == 4 else 100) if level == 1 else 0)


def apply(state, op, args, catalog, error):
    from .inventory import grant
    entries = state['inventory']['entries']
    uid = args.get('uid')
    if type(uid) is not int:
        raise error('请选择精魄实例')
    entry = next((e for e in entries if e['uid'] == uid), None)
    item = catalog['items'].get(entry['key']) if entry else None
    if not item or item['main_type'] != 15:
        raise error('精魄不存在')
    if op in ('bag_essence_inscribe', 'bag_essence_upgrade'):
        if LEVEL_GATE_ENABLED and int(state.get('level', 1)) < OPEN_LEVEL:
            raise error('等级达到38级才能开启精魄铭刻')
        raise error('原版服务端结算规则尚缺失，未消耗精魄或精魄石')
    if entry['hero']:
        raise error('已铭刻的精魄不能用于转化或分解')
    # Source recipes explicitly use attach_level=1. Do not guess return or carryover.
    if entry['level'] != 1 or int(entry.get('prob_compen', 0)):
        raise error('仅已核实无升级进度的1级精魄配方；未消耗')
    if op == 'bag_essence_decompose':
        recipe = catalog['essence']['decompose']['102' if item['id'] < 10200 else '103']
        cost = int(recipe['cost_material'].split('|')[3])
        output = int(recipe['des_material'].split('|')[3])
        if state['silver'] < cost:
            raise error('分解需要1000银两')
        state['silver'] -= cost
        entry['count'] -= 1
        entries[:] = [e for e in entries if e['count'] > 0]
        grant(state, 'i10000', output, catalog=catalog)
        return '精魄分解成功，获得%d颗精魄石' % output
    if op == 'bag_essence_transform':
        rule = catalog['essence']['transforms'].get(str(item['id']))
        if not rule or (LEVEL_GATE_ENABLED and int(state.get('level', 1)) < int(rule['min_role_level'])):
            raise error('精魄转换需要38级及紫色精魄')
        targets = rule['des_material'].split('/')
        if len(targets) != 1:
            raise error('此组转换概率未包含在客户端中，未消耗')
        from .battle_training import consume_materials
        consume_materials(state, rule['cost_material'], error, exclude_uid=uid)
        entry['count'] -= 1
        entries[:] = [e for e in entries if e['count'] > 0]
        target = targets[0].split('|')
        grant(state, 'i' + target[1], int(target[3]), int(target[2]), catalog=catalog)
        return '精魄转换成功'
    raise error('未知精魄操作')
