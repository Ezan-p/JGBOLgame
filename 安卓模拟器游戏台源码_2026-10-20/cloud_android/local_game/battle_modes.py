"""Playable local counterparts of original PvE, elite, arena, guild and story battles."""
from .battle_rules import normalized,rounded
from .assets import character_sprite,CATEGORIES


def build_modes(r):
    bases={};names={};available=set(r.names())
    for path in r.names():
        if (path.startswith('csv_config/cortege/cortege_base_') or path=='csv_config/elite/elite_cortege_base.csv') and path.endswith('.csv'):
            bases.update({int(x['type_id']):normalized(x) for x in r.rows(path)})
        if (path.startswith('csv_config/cortege/cortege_name_') or path=='csv_config/elite/elite_cortege_name.csv') and path.endswith('.csv'):
            names.update({int(x['type_id']):x for x in r.rows(path)})
    skillnames={int(x['type_id']):x['name'] for x in r.rows('csv_config/skill_name.csv')}
    def encounters(path,key):
        result={}
        for raw in r.rows(path):
            row=normalized(raw);units=[]
            for slot,token in enumerate(row['cortege_list'].split('/'),1):
                if not token:continue
                parts=token.split('|');ident=int(parts[0]);level=int(parts[1]);b=bases[ident]
                picture=character_sprite(b)
                if picture not in available:
                    raise ValueError(f"Missing encounter sprite: {path}:{row[key]}:{ident}")
                native=int(b['chushijineng']);extra=[int(s) for s in parts[2].split('+') if s] if len(parts)>2 else []
                spell_ids=list(dict.fromkeys([native]+extra))
                if len(spell_ids)>3:
                    raise ValueError(f"Encounter has more than three spells: {row[key]}:{ident}")
                u=dict(id=ident,name=names.get(ident,names.get(int(b.get('base_type_id',0)),{})).get('name',b['name']),
                       sprite=picture,quality=int(b['quality']),category=CATEGORIES[int(b['category'])],
                       level=level,lineup_slot=slot,skill_id=native,skill_name=skillnames.get(native,'普通攻击'),
                       spells=[dict(id=s,position=i+1,level=int(row.get('skill_level',1))) for i,s in enumerate(spell_ids)])
                for stat,base,growth in [('hp','base_max_hp','base_maxhp_plus'),('attack','base_gongji','base_gongji_plus'),('defense','base_fangyu','base_fangyu_plus'),('magic','base_max_magic','base_maxmagic_plus')]:
                    u[stat]=rounded(float(b[base])+float(b.get(growth,0))*(level-1))
                units.append(u)
            if not units or len(units)>8:
                raise ValueError(f"Invalid encounter: {path}:{row[key]}")
            result[row[key]]=units
        return result
    return dict(pve=encounters('csv_config/tollgate_config.csv','id'),
                elite=encounters('csv_config/elite/elite_tollgate_config.csv','tollgate_id'))


MODES=[dict(id='elite',name='精英挑战',description='原版精英阵容，获得银两与修炼经验。',energy=4),
       dict(id='arena',name='竞技切磋',description='与本地镜像阵容对战，胜场累积积分。',energy=2),
       dict(id='guild',name='仙盟试炼',description='挑战高生命首领，按造成伤害结算。',energy=3),
       dict(id='story',name='剧情演武',description='分步援军、复活和八阵位对战。',energy=2)]


def fight(game,state,mode,error):
    import copy,time
    from .combat import resolve
    rule=next((m for m in MODES if m['id']==mode),None)
    if not rule:raise error('未知战斗模式')
    if state['energy']<rule['energy']:raise error('体力不足')
    roster,_=game.roster(state)
    allies=[dict(roster[i],lineup_slot=slot) for slot,i in enumerate(state['lineup'],1) if i]
    if not allies:raise error('请先安排出战神仙')
    counters=state.setdefault('battle_modes',{});day=int((time.time()+8*3600)//86400)
    record=counters.setdefault(mode,dict(day=day,attempts=0,wins=0,score=0))
    if record['day']!=day:record['day']=day;record['attempts']=0
    if record['attempts']>=20:raise error('本模式今日已完成20次挑战')
    rules=game.catalog['combat_rules'];modes=game.catalog['battle_modes']
    if mode=='elite':
        keys=sorted(modes['elite'],key=int);idx=min(len(keys)-1,record['wins'])
        enemies=copy.deepcopy(modes['elite'][keys[idx]])
    elif mode=='arena':
        enemies=copy.deepcopy(allies)
    elif mode=='guild':
        boss=copy.deepcopy(game.hero(5013,max(state['heroes'].values())))
        boss.update(hp=max(10000,sum(u['hp'] for u in allies)*12),attack=max(1,rounded(sum(u['attack'] for u in allies)/max(1,len(allies))*.7)),
                    skill_id=104,spells=[dict(id=104,level=3,position=1)],traits=[dict(id=10108,level=2)])
        enemies=[boss]
    else:
        ids=[5022,5004,5013,5023,4020,5048,5018,5034]
        enemies=[game.hero(i,max(1,min(10,1+record['wins']))) for i in ids]
        for i,u in enumerate(enemies):
            u.update(lineup_slot=i+1,step=0 if i<4 else 6)
        enemies[0].update(revive_charges=1,revive_fraction=.2)
    first=0 if mode!='arena' or sum(u['magic'] for u in allies)>=sum(u['magic'] for u in enemies) else 1
    report=resolve(allies,enemies,game.catalog['skills'],seed=state['battle_count']*1009+sum(map(ord,mode)),rules=rules,mode=mode,first_side=first)
    reward=(min(600,20+report['total_damage'][0]//50) if mode=='guild' else (300 if report['won'] else 20))
    from .role_progression import award_battle
    # All current local modes spend the shared stamina (体力) pool.
    exp=award_battle(state,game.catalog['role_levels'],report['won'])
    state['silver']+=reward;state['energy']-=rule['energy'];state['battle_count']+=1
    record['attempts']+=1;record['wins']+=int(report['won']);record['score']+=report['total_damage'][0] if mode=='guild' else 20 if report['won'] else 0
    return {**report,'stage':dict(id=0,name=rule['name'],background='map/special/xmz.jpg' if mode in ('arena','guild') else 'map/special/pty.jpg'),
            'silver':reward,'experience':exp,'first_clear':False,'number':state['battle_count'],'score':record['score']}
