"""Eight-position battle reports. Server-only formulas/arbitration remain local rules."""
import copy
import random

# Formation slots: 1 后 / 2 前 / 3 上 / 4 下; 5-8 are the paired reserves.
LANES = {1: 'back', 2: 'front', 3: 'top', 4: 'bottom',
         5: 'back', 6: 'front', 7: 'top', 8: 'bottom'}
# Target chain per attacker position. Front(2) and its reserve(6) must both be
# gone before back(1)/back reserve(5) can be hit; a cleared side lane falls back
# to the middle, and a cleared middle sweeps the top lane before the bottom lane.
TARGET_PRIORITY = {
    'back': (2, 6, 1, 5, 3, 7, 4, 8),
    'front': (2, 6, 1, 5, 3, 7, 4, 8),
    'top': (3, 7, 2, 6, 1, 5, 4, 8),
    'bottom': (4, 8, 2, 6, 1, 5, 3, 7),
}
# Attacker acts 后→前→上→下, defender acts 前→后→下→上, paired alternately.
ACTOR_ORDER = (1, 2, 3, 4)
DEFENDER_ORDER = (2, 1, 4, 3)


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


from .battle_rules import damage_formula, rounded, trait_parameters, normalized, VERSION


class Battle:
    """Bounded event engine. Additional attacks never recursively generate attacks."""
    def __init__(self, allies, enemies, skills, seed, rules, opening, mode, first_side):
        self.teams=copy.deepcopy((allies,enemies));self.skills=skills;self.rules=rules or {}
        self.rng=random.Random(seed);self.seed=seed;self.opening=opening;self.mode=mode
        self.events=[];self.rolls=[];self.turn=0;self.step=0;self.first_side=first_side
        self.total_damage=[0,0]
        for side,team in enumerate(self.teams):
            occupied=set()
            for index,u in enumerate(team):
                slot=u.get('lineup_slot',index+1)
                if type(slot) is not int or not 1<=slot<=8 or slot in occupied:
                    raise ValueError('Battle positions must be unique and between 1 and 8')
                occupied.add(slot);apply_passives(u,skills)
                for stat in ('hp','attack','defense','magic'): u[stat]=max(0,int(u.get(stat,0)))
                u['hp']=max(1,u['hp'])
                u.update(uid=f'{side}-{slot-1}',side=side,slot=slot,max_hp=u['hp'],
                         in_field=slot<=4 and u.get('step',0)<=0,shield=0)
                u['passives']=[dict(id=s['id'],name=skills[str(s['id'])]['name'],level=s['level'])
                               for s in sorted(spell_loadout(u),key=lambda x:x.get('position',1)) if str(s['id']) in skills
                               and not skills[str(s['id'])].get('active')
                               and (s['id']==21 or spell_value(skills[str(s['id'])],s['level'])>0)]
            team.sort(key=lambda u:u['slot'])
        self.initial=copy.deepcopy(self.teams[0]+self.teams[1])
        for u in self.units():
            u['_base']={k:u[k] for k in ('hp','attack','defense','magic')}
            u['_traits']={}
            for t in u.get('traits',[]):
                parsed=trait_parameters(t,self.rules)
                if parsed: u['_traits'][parsed['family']]=parsed
            u.update(_poisons=[],_intimidate=0,_armor=0,_war=0,_revives=0,_actions=0,_dead=False,_entered=False,_prevented=0)
        for u in self.units():
            if u['in_field']: self.on_entry(u)
        self.enter()

    def units(self): return self.teams[0]+self.teams[1]
    def living(self, side): return [u for u in self.teams[side] if u['in_field'] and u['hp']>0]
    def position(self, u):
        """1 后 / 2 前 / 3 上 / 4 下; reserves 5-8 inherit their paired position."""
        return (u['slot']-1)%4+1
    def lane(self, u): return LANES[u['slot']]
    def action_order(self):
        """Attacker 后→前→上→下 interleaved with defender 前→后→下→上.

        The list is fixed at round start: a reserve that fills a slot during the
        round joins the order from the next round.
        """
        sequences={self.first_side:ACTOR_ORDER,1-self.first_side:DEFENDER_ORDER}
        living={side:{self.position(u):u for u in self.living(side)} for side in (0,1)}
        order=[]
        for i in range(4):
            for side in (self.first_side,1-self.first_side):
                u=living[side].get(sequences[side][i])
                if u:order.append(u)
        return order
    def select_targets(self, u, multi=False):
        """Walk the explicit slot chain: front(2,6) → back(1,5) → top → bottom.

        No lowest-slot tie-break: each step names one exact enemy slot, so the
        back position can only be hit after the front position and its reserve
        are both gone.
        """
        targets=self.living(1-u['side'])
        if multi:return targets
        by_slot={t['slot']:t for t in targets}
        for slot in TARGET_PRIORITY[self.lane(u)]:
            if slot in by_slot:return [by_slot[slot]]
        return targets[:1]
    def trait(self,u,family): return u['_traits'].get(family)
    def params(self,u,family):
        t=self.trait(u,family);return t['params'] if t else []
    def chance(self,u,name,p):
        roll=self.rng.random();ok=roll<max(0,min(1,p))
        self.rolls.append(dict(step=self.step,turn=self.turn,actor=u['uid'],reason=name,chance=p,roll=round(roll,8),success=ok))
        return ok
    def emit(self,actor,name,kind='effect',hits=None,changes=None,**extra):
        hits=hits or []
        e=dict(turn=self.turn,action_step=self.step,actor=actor['uid'],skill_id=1,skill=False,
               skill_name=name,text=actor['name']+' · '+name,kind=kind,hits=hits,changes=changes or [])
        if hits:e.update(hits[0])
        e.update(extra);self.events.append(e);return e
    def snapshot(self,u):
        return {k:u[k] for k in ('hp','max_hp','attack','defense','magic','shield','in_field')} | {'target':u['uid'],'poison_stacks':len(u['_poisons']),'armor_loss':u['_armor']}
    def status(self,u,name,**extra): return self.emit(u,name,changes=[self.snapshot(u)],**extra)
    def heal(self,u,amount,name,source=None):
        if u['hp']<=0:return
        actual=min(u['max_hp']-u['hp'],rounded(amount))
        if actual:
            u['hp']+=actual
            self.emit(source or u,name,hits=[dict(target=u['uid'],damage=-actual,hp=u['hp'],max_hp=u['max_hp'],shield=u['shield'])])
    def change_stats(self,u,percent,name,fields=('hp','attack','defense','magic')):
        for k in fields:
            addition=rounded(u['_base'][k]*percent)
            u[k]+=addition
            if k=='hp':u['max_hp']+=addition
        self.status(u,name)
    def on_entry(self,u):
        if u['_entered']:return
        u['_entered']=True
        strong=self.params(u,13)
        if strong:self.change_stats(u,strong[0],'强壮',('hp',))
        bless=self.params(u,18)
        if bless and self.chance(u,'祝福',bless[0]):
            targets=self.living(u['side'])
            if targets:self.change_stats(self.rng.choice(targets),bless[1],'祝福')
    def enter(self):
        for side,team in enumerate(self.teams):
            slots={u['slot']:u for u in team}
            for u in team:
                if u['in_field'] or u['hp']<=0 or u.get('step',0)>self.step:continue
                front=slots.get(u['slot']-4) if u['slot']>4 else None
                if front and (front['hp']>0 or not front['_dead']):continue
                u['in_field']=True
                self.emit(u,'援军入阵',kind='enter',slot=u['slot'],replaces=front['uid'] if front else '')
                self.on_entry(u)
    def settle_deaths(self):
        # Revive before substitution. Only original unit may revive, never its dead predecessor later.
        for u in self.units():
            if u['hp']>0 or u['_dead']:continue
            p=self.params(u,19);limit=2 if self.trait(u,19) and self.trait(u,19)['id']//100==102 else 1
            scripted=u.get('revive_charges',0)>0
            if scripted or (p and u['_revives']<limit and self.chance(u,'复活',p[0])):
                if scripted:u['revive_charges']-=1
                u['_revives']+=1;u['_poisons']=[];u['_intimidate']=0
                u['defense']+=rounded(u['_base']['defense']*u['_armor']);u['_armor']=0;u['shield']=0
                u['hp']=max(1,rounded(u['max_hp']*(u.get('revive_fraction',.2) if scripted else p[1])))
                self.emit(u,'复活',hits=[dict(target=u['uid'],damage=-u['hp'],hp=u['hp'],revive=True,max_hp=u['max_hp'],shield=0)],changes=[self.snapshot(u)])
            else:
                u['_dead']=True;u['_poisons']=[];u['shield']=0
        self.enter()
    def future(self,side):
        return [u for u in self.teams[side] if u['hp']>0 and not u['in_field']]
    def wait_for_entrance(self):
        if any(not self.living(s) and self.future(s) for s in (0,1)):
            steps=[u.get('step',0) for u in self.units() if u['hp']>0 and not u['in_field'] and u.get('step',0)>self.step]
            if steps:self.step=min(steps);self.enter()
    def rulai(self,u):
        spell=next((s for s in spell_loadout(u) if s['id']==21),None)
        if not spell:return None
        row=self.rules.get('rulai',{}).get(str(min(10,max(1,spell['level']))))
        if not row:return None
        awake=bool(spell.get('awaken'))
        absorb=float(row['absorb_rate'])*(1.1 if awake else 1)+u['magic']/800
        shield=float(row['shield_rate'])*(1+self.rules.get('awaken_rates',{}).get('21',10)/100 if awake else 1)
        return min(.6,absorb/100),min(1,shield/100)
    def hit(self,u,amount,**extra):
        shield=min(u['shield'],max(0,rounded(amount)));u['shield']-=shield
        actual=min(u['hp'],max(0,rounded(amount)-shield));prevented=False
        if actual>=u['hp'] and u['hp']>0 and u.get('death_prevent_rate',0)>0 and u['_prevented']<u.get('death_prevent_limit',1):
            if self.chance(u,'免死',u['death_prevent_rate']):
                actual=u['hp']-1;u['_prevented']+=1;prevented=True
        u['hp']-=actual
        return dict(target=u['uid'],damage=actual,hp=u['hp'],max_hp=u['max_hp'],shield=u['shield'],absorbed=shield,prevented=prevented,**extra)
    def damage_hits(self,actor,target,amount,cause):
        # Shield first, then share remaining damage among living guardians, total share <= 60%.
        protected=min(target['shield'],amount);target['shield']-=protected;remaining=max(0,amount-protected)
        hits=[];guardians=[]
        if cause!='poison':
            for guardian in self.living(target['side']):
                rate=self.rulai(guardian)
                if guardian is not target and rate:guardians.append((guardian,rate[0]))
        total=sum(p for _,p in guardians);scale=min(1,.6/total) if total else 1
        diverted=0
        for guardian,rate in guardians:
            share=min(remaining-diverted,rounded(remaining*rate*scale))
            if share:
                diverted+=share;hits.append(self.hit(guardian,share,redirected=True,cause='分摊'))
        primary=self.hit(target,remaining-diverted,cause=cause);primary['absorbed']+=protected
        hits.insert(0,primary)
        self.total_damage[actor['side']]+=sum(h['damage'] for h in hits if h['damage']>0 and actor['side']!=target['side'])
        return hits
    def round_start(self):
        for u in list(self.units()):
            if not u['in_field'] or u['hp']<=0:continue
            antidote=self.params(u,17)
            if u['_poisons'] and antidote and self.chance(u,'解毒',antidote[0]):
                u['_poisons']=[];self.status(u,'解毒')
            for poison in list(u['_poisons']):
                if u['hp']<=0:break
                hit=self.hit(u,min(200000,rounded(u['_base']['hp']*poison['rate'])),cause='毒伤')
                self.emit(u,'毒伤',hits=[hit]);poison['left']-=1
                if poison.get('side') in (0,1) and poison['side']!=u['side']:
                    self.total_damage[poison['side']]+=hit['damage']
            expired=any(p['left']<=0 for p in u['_poisons'])
            u['_poisons']=[p for p in u['_poisons'] if p['left']>0]
            if expired:self.status(u,'毒结束')
            self.settle_deaths()
            recovery=self.params(u,10)
            if self.turn>=2 and u['hp']>0 and recovery and self.chance(u,'愈合',recovery[0]):
                luck=self.params(u,14)
                self.heal(u,u['_base']['hp']*recovery[1]*(1+luck[0] if luck else 1),'愈合')
    def select_spell(self,u):
        candidates=[]
        pen=self.trait(u,9)
        for s in sorted(spell_loadout(u),key=lambda x:x['position']):
            spec=self.skills.get(str(s['id']),{});row=normalized(spec.get('original',{}))
            if spec.get('active') and s['id']!=1:
                probability=float(row.get('use_probability',0))
                if probability>0 and pen:probability+=2 if pen['id']//100==102 else 1
                candidates.append((s,spec,probability))
        total=sum(p for _,_,p in candidates);scale=min(1,100/total) if total else 1
        roll=self.rng.random()*100;cumulative=0;chosen=None
        for s,spec,p in candidates:
            cumulative+=p*scale
            if roll<cumulative:chosen=(s,spec);break
        if self.opening and self.turn==1 and candidates:chosen=candidates[0][:2]
        return chosen,roll,[dict(id=s['id'],position=s['position'],probability=p*scale) for s,_,p in candidates]
    def strength(self,s,spec):
        value=spell_value(spec,s.get('level',1))
        if s.get('awaken'):value*=1+self.rules.get('awaken_rates',{}).get(str(s['id']),0)/100
        return value
    def shield_proc(self,u):
        rulai=self.rulai(u)
        if u['hp']<=0 or not rulai or not self.chance(u,'大乘经护盾',rulai[1]):return
        target=min(self.living(u['side']),key=lambda t:(t['hp']/t['max_hp'],t['slot']))
        target['shield']=min(rounded(target['max_hp']*.5),target['shield']+max(1,rounded(u['magic']*.15)))
        self.status(target,'大乘经护盾')
    def strike(self,u,targets,s=None,spec=None,factor=1,cause='attack',react=True,roll=None,chances=None):
        s=s or dict(id=1,level=1,position=0);spec=spec or {};sid=s['id'];magic=sid!=1
        if not targets or u['hp']<=0:return
        strength=self.strength(s,spec)*(1+u.get('spell_power_percent',0))+u.get('spell_power_flat',0);hits=[];damaged=[];tags=[]
        attack=u['attack']*(1-u['_intimidate'])
        for target in targets:
            if target['hp']<=0 or not target['in_field']:continue
            raw=damage_formula(attack,target['defense'],u['magic'],target['magic'],strength,magic)
            amount=raw*factor
            crit=max(0,u.get('crit_rate',0)-target.get('crit_resist',0))
            if not magic and crit>0 and self.chance(u,'暴击',crit):
                amount*=max(1,1.5+u.get('crit_bonus',0)-target.get('crit_reduction',0));tags.append('暴击')
            reduction=0
            resist=self.params(target,8);penetration=self.params(u,9)
            if magic and resist:
                reduction=resist[0]*(1-penetration[0] if penetration else 1);tags.append('法抗' if not penetration else '法穿')
            block=self.params(target,6)
            if not magic and block and self.chance(target,'格挡',block[0]):reduction=block[1];tags.append('格挡')
            amount*=1-reduction
            strong=self.params(u,11)
            if react and not magic and strong and self.chance(u,'强袭',strong[0]):
                intimidate=self.params(target,1);parry=self.params(u,4)
                extra=raw*strong[1]*(1-intimidate[2] if intimidate else 1)
                if parry and self.trait(target,3):extra*=1+parry[1]
                amount+=extra;tags.append('强袭')
            amount=max(1,rounded(amount))
            luck=self.params(target,14)
            if cause=='execute' and amount>=target['hp']+target['shield'] and luck and self.chance(target,'幸运',luck[1]):
                hits.append(dict(target=target['uid'],damage=0,hp=target['hp'],shield=target['shield'],max_hp=target['max_hp'],dodged=True));tags.append('幸运');continue
            result=self.damage_hits(u,target,amount,cause)
            result[0]['formula']=dict(power_attack=round(attack,6),defense=target['defense'],magic=u['magic'],target_magic=target['magic'],intensity=strength,original_id=int(normalized(spec.get('original',{})).get('party_formula' if self.mode=='guild' else 'formula',1)),base=raw,factor=factor,reduction=reduction,final=amount)
            hits.extend(result);damaged.append(target)
        if not hits:return
        label={'counter':'反击','combo':'连击','execute':'斩杀'}.get(cause,spec.get('name','普通攻击'))
        self.emit(u,label,kind='skill' if magic else 'attack',hits=hits,skill_id=sid,skill=magic,
                  skill_level=s.get('level',1),spell_position=s.get('position',0),strength=strength,
                  roll=roll,chances=chances or [],tags=tags,cause=cause)
        if u['_intimidate']:
            u['_intimidate']=0;self.status(u,'威慑解除')
        self.settle_deaths()
        stolen=sum(h['damage'] for h in hits if not h.get('redirected'))
        vampire=self.params(u,5)
        if vampire and cause!='counter':self.heal(u,stolen*vampire[0],'嗜血')
        for target in damaged:
            if target['hp']>0:self.shield_proc(target)
        if not react or u['hp']<=0:return
        for target in damaged:
            if target['hp']<=0:continue
            for family,name in ((1,'威慑'),(2,'破甲'),(16,'中毒')):
                p=self.params(u,family)
                if p and self.chance(u,name,p[0]):
                    if family==1:target['_intimidate']=max(target['_intimidate'],p[1])
                    elif family==2:
                        old=rounded(target['_base']['defense']*target['_armor']);target['_armor']=min(.9,target['_armor']+p[1]);target['defense']=max(0,target['defense']+old-rounded(target['_base']['defense']*target['_armor']))
                    else:target['_poisons'].append(dict(rate=p[1],left=3,side=u['side']))
                    self.status(target,name)
            counter=self.params(target,3);parry=self.params(u,4)
            if counter and self.chance(target,'反击',counter[0]):
                if parry and self.chance(u,'招架',parry[0]):self.status(u,'招架')
                else:self.strike(target,[u],factor=counter[1],cause='counter',react=False)
            if u['hp']<=0:break
        if u['hp']<=0:return
        targets=[t for t in damaged if t['hp']>0]
        if not targets:return
        combo=self.params(u,7);execute=self.params(u,15)
        if combo and self.chance(u,'连击',combo[0]):self.strike(u,targets[:1],factor=combo[1],cause='combo',react=False)
        elif execute and targets[0]['hp']/targets[0]['max_hp']<execute[0] and self.chance(u,'斩杀',execute[1]):
            self.strike(u,targets[:1],cause='execute',react=False)
    def act(self,u):
        u['_actions']+=1
        war=self.params(u,12)
        if war and u['_actions']%2==0:
            self.change_stats(u,war[0],'战意',('attack',))
        selected,roll,chances=self.select_spell(u)
        s,spec=selected if selected else (dict(id=1,level=1,position=0),{})
        if s['id']==6:
            targets=[t for t in self.living(u['side']) if t['hp']<t['max_hp']]
            if targets:
                hits=[]
                for t in targets:
                    value=min(t['max_hp']-t['hp'],max(1,rounded(u['attack']*.8+u['magic']*self.strength(s,spec)/100)))
                    t['hp']+=value;hits.append(dict(target=t['uid'],damage=-value,hp=t['hp'],max_hp=t['max_hp'],shield=t['shield']))
                self.emit(u,spec.get('name','治疗'),kind='heal',hits=hits,skill_id=6,skill=True);return
            s,spec=dict(id=1,level=1,position=0),{}
        targets=self.select_targets(u,bool(spec.get('multi')))
        self.strike(u,targets,s,spec,roll=round(roll,6),chances=chances)
    def run(self):
        for self.turn in range(1,31):
            self.wait_for_entrance();self.round_start();self.wait_for_entrance()
            # Fixed formation order keeps the opening round from being a full team sweep.
            for u in self.action_order():
                self.enter()
                if u['hp']>0 and self.living(1-u['side']):self.act(u);self.step+=1
            self.wait_for_entrance()
            if not all(self.living(side) for side in (0,1)):break
        alive=[bool(self.living(side) or self.future(side)) for side in (0,1)]
        won=alive[0] and not alive[1]
        result='win' if won else 'loss' if not alive[0] and alive[1] else 'draw'
        return dict(units=self.initial,events=self.events,won=won,result=result,turns=self.turn,seed=self.seed,
                    rules=VERSION,report_version=4,mode=self.mode,first_side=self.first_side,
                    total_damage=self.total_damage,proc_audit=self.rolls,
                    final_units=[dict(uid=u['uid'],**self.snapshot(u)) for u in self.units()])


def resolve(allies,enemies,skills,opening_skill=False,seed=0,rules=None,mode='pve',first_side=0):
    return Battle(allies,enemies,skills,seed,rules,opening_skill,mode,first_side).run()
