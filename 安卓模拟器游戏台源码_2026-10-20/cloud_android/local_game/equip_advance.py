"""Original positional advance tables; explicit offline settlement policy.

Server-only settings are not recovered: local unlock=1, pour batch=5 (client
fallback), one essence=one spirit, one-key stops at seven stars of this tier.
The `extra` milestone is exposed as original preview metadata, not guessed as
an additional character multiplier on top of the confirmed equipment bonus.
"""
import csv
import io
import math


def build_rules(resources):
    worth, stars, costs = {}, {}, {}
    records = list(csv.reader(io.StringIO(resources.read(
        'csv_config/equip_advance_worth.csv').decode('utf-8-sig'))))
    for row in records[1:]:
        kind, quality = map(int, row[:2])
        values = {'0:0': dict(percent=0, plus=0, extra=0)}
        for index, cell in enumerate(row[2:], 1):
            parts = list(map(float, cell.split('|')))
            values[f'{index//8}:{index%8}'] = dict(
                percent=parts[0], plus=int(parts[1]), extra=parts[2] if len(parts)>2 else 0)
        worth[f'{quality}:{kind}'] = values
    for row in resources.rows('csv_config/equip_star_cost.csv'):
        quality, star = int(row['equip_quality']), int(row['star_level'])
        for key, cell in row.items():
            if not key.startswith('advance'): continue
            rank = int(key.split('(')[0].removeprefix('advance'))
            for kind, amount in enumerate(cell.split('|'), 1):
                stars[f'{quality}:{kind}:{rank}:{star}'] = int(amount)
    for row in resources.rows('csv_config/equip_advance_cost.csv'):
        for kind, field in enumerate(('wuqi_cost','fangyu_cost','fabao_cost'), 1):
            costs[f'{row["equip_quality"]}:{kind}:{row["advance_level"]}'] = [
                dict(key='i'+cell.split('|')[0], count=int(cell.split('|')[1]))
                for cell in row[field].split('/')]
    return dict(worth=worth, stars=stars, costs=costs, max_rank=10, max_stars=7,
                pour_count=5, min_role_level=1, policy='offline-v1')


def effect(item, entry, catalog):
    values = catalog['equip_advance']['worth'].get(f'{item["quality"]}:{item["category"]}', {})
    return values.get(f'{entry.get("advance_level",0)}:{entry.get("star_count",0)}',
                      dict(percent=0, plus=0, extra=0))


def bonus(item, entry, catalog, base):
    e = effect(item, entry, catalog)
    return math.floor(base * e['percent'] + e['plus'] + 1e-9)


def describe(item, entry, catalog, bag):
    rules = catalog['equip_advance']
    if f'{item["quality"]}:{item["category"]}' not in rules['worth']: return None
    rank, star = int(entry.get('advance_level',0)), int(entry.get('star_count',0))
    def stock(key):
        return sum(e['count'] for e in bag['entries'] if e['key']==key and e.get('level',1)==1)
    material = 'i'+str(1309+item['category'])
    costs = rules['costs'].get(f'{item["quality"]}:{item["category"]}:{rank+1}', [])
    need = rules['stars'].get(f'{item["quality"]}:{item["category"]}:{rank+1}:{star+1}', 0)
    return dict(rank=rank, stars=star, spirit=int(entry.get('cur_spirit_count',0)),
                max_rank=rules['max_rank'], max_stars=rules['max_stars'],
                full=rank>=rules['max_rank'], ready=star==rules['max_stars'] and rank<rules['max_rank'],
                effect=effect(item,entry,catalog), need=need,
                next_effect=rules['worth'][f'{item["quality"]}:{item["category"]}'].get(f'{rank+1}:0'),
                material=material, own=stock(material), pour_count=rules['pour_count'],
                costs=[dict(**c, own=stock(c['key'])) for c in costs])


def apply(state, op, args, catalog, error):
    def check(test, message):
        if not test: raise error(message)
    check(type(args.get('uid')) is int, '装备编号无效')
    bag=state['inventory']
    entry=next((e for e in bag['entries'] if e['uid']==args['uid']), None)
    check(entry is not None, '物品已不存在，请刷新包裹')
    item=catalog['items'][entry['key']]
    check(item['category'] in (1,2,3) and item['quality'] in (4,5), '只有四星、五星装备可以升阶')
    rules=catalog['equip_advance']; info=describe(item,entry,catalog,bag)
    check(int(state.get('level',1))>=rules['min_role_level'], '行者等级不足')
    check(not info['full'], '该装备已经是最高阶')
    rank,star,spirit=info['rank'],info['stars'],info['spirit']
    check(0<=rank<10 and 0<=star<=7 and spirit>=0, '装备升阶数据无效')
    if op=='bag_equip_pour':
        one_key=args.get('one_key',False)
        check(type(one_key) is bool, '一键注灵参数无效')
        check(not info['ready'], '装备注灵已满七星，请升阶')
        count=info['pour_count']
        check(info['own']>=count, '缺少'+catalog['items'][info['material']]['name'])
        spent=0
        while star<7 and info['own']-spent>=count:
            spirit+=count;spent+=count
            while star<7:
                need=rules['stars'][f'{item["quality"]}:{item["category"]}:{rank+1}:{star+1}']
                if spirit<need: break
                spirit-=need;star+=1
            if not one_key: break
        deductions=[dict(key=info['material'], count=spent)]
        result='注灵成功'
    elif op=='bag_equip_advance':
        check(info['ready'], '装备注灵达到七星后即可升阶')
        for cost in info['costs']:
            check(cost['own']>=cost['count'], '缺少'+catalog['items'][cost['key']]['name'])
        deductions=info['costs'];rank+=1;star=0;spirit=0;result='进阶成功'
    else:
        raise error('未知装备升阶操作')
    # All eligibility and material checks finish before mutating any stack.
    for cost in deductions:
        remaining=cost['count']
        for stack in list(bag['entries']):
            if stack['key']!=cost['key'] or stack.get('level',1)!=1: continue
            n=min(remaining,stack['count']);stack['count']-=n;remaining-=n
            if stack['count']==0:bag['entries'].remove(stack)
            if remaining==0:break
    entry.update(advance_level=rank, star_count=star, cur_spirit_count=spirit)
    return result
