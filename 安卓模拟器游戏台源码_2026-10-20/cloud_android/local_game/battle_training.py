"""Transactional spell development. Original costs; local access gates are documented."""
from .battle_rules import rounded


def training(state, ident):
    return state.get('battle_training',{}).get(str(ident),{})


def consume_materials(state, spec, error, exclude_uid=None):
    entries=state.get('inventory',{}).get('entries',[]);planned={}
    for token in spec.split('/'):
        kind,ident,level,count=map(int,token.split('|'))
        key=('s' if kind==6 else 'i')+str(ident)
        for e in sorted(entries,key=lambda e:(e['level'],e['uid'])):
            if e['key']!=key or e['hero'] or e['uid']==exclude_uid or e['level']<level:continue
            amount=min(count,e['count']-planned.get(e['uid'],0))
            planned[e['uid']]=planned.get(e['uid'],0)+amount;count-=amount
            if not count:break
        if count:raise error('材料不足，需要未装备材料：'+spec)
    for e in entries:
        e['count']-=planned.get(e['uid'],0)
    entries[:]=[e for e in entries if e['count']>0]


def apply(state, op, args, catalog, error):
    def check(ok,msg):
        if not ok:raise error(msg)
    ident=args.get('hero');check(type(ident) is int and str(ident) in state['heroes'],'请选择已拥有的神仙')
    rules=catalog['combat_rules'];hero=catalog['heroes'][str(ident)]
    stored=state.setdefault('battle_training',{}).setdefault(str(ident),{})
    sid=hero['skill_id'];level=stored.get('native_level',1)
    if op=='battle_native_upgrade':
        skill=catalog['skills'][str(sid)]
        top=int(skill['original']['top_level']);cost=100*max(1,hero['quality'])*level
        check(sid!=1 and level<top,'原生法术已到等级上限')
        check(state['silver']>=cost,'银两不足，需要 '+str(cost))
        state['silver']-=cost;stored['native_level']=level+1
        return '原生法术已升级'
    if op=='battle_awaken':
        kind=args.get('kind');check(type(kind) is int and kind in (1,2,3),'请选择攻、守或法力觉醒')
        row=rules['awaken'][str(kind)]
        check(not stored.get('awaken'),'原生法术已觉醒')
        check(str(sid) in rules['awaken_rates'],'该原生法术没有觉醒配置')
        check(level>=int(row['min_level']) and state['heroes'][str(ident)]>=20,'觉醒需要神仙20级、原生法术10级')
        consume_materials(state,row['material_list'],error)
        stored['awaken']=kind
        return '原生法术觉醒成功'
    if op=='battle_cheer_upgrade':
        from .synergy import support_ids
        check(ident in support_ids(state),'请选择正在助阵的神仙')
        current=stored.get('cheer_level',0)
        check(str(current+1) in rules['cheer'],'助阵法术已到上限')
        consume_materials(state,rules['cheer'][str(current)]['consume_list'],error)
        stored['cheer_level']=current+1
        return '助阵法术效能已提升'
    raise error('未知修炼操作')
