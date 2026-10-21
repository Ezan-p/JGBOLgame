"""Original parameters plus explicitly reconstructed policies, version local-v4."""
import math

VERSION = 'local-v4'
STATS = {1:'attack', 2:'defense', 3:'magic', 5:'hp'}


def rounded(value):
    return max(0, int(math.floor(value+.5)))


def normalized(row):
    return {k.strip().split('(')[0]: v for k,v in row.items() if k}


def build_rules(resources):
    def rows(name): return [normalized(r) for r in resources.rows('csv_config/'+name+'.csv')]
    items = {int(r['Ftype_id']):r for r in rows('item_name')}
    traits = {}
    for row in rows('ext_skill'):
        ident=int(row['id'])
        traits[str(ident)] = dict(id=ident, family=ident%100, name=items[ident]['name'],
            description=row['introduction'], levels=[[float(n.rstrip('%'))/100 for n in group.split('|')]
                                                     for group in row['parameter'].split('/')], max_level=5)
    stars={}
    for raw in resources.rows('csv_config/ext_star_config.csv'):
        ident=int(raw['ext_skill_type']);values=[]
        for value in raw['show_num'].split('|'):
            values.append(float(value.rstrip('%'))/(100 if value.endswith('%') else 1))
        parameters=raw['spell_rate|spell_rate/spell_rate|spell_rate/spell_rate|spell_rate']
        stars[str(ident)]=dict(id=ident,family=ident%100,name=items[ident]['name'],description=raw['desc'],
                               values=values,max_level=int(raw['top_level']),parameters=parameters)
    return dict(version=VERSION, traits=traits, stars=stars,
        rulai={r['level']:r for r in rows('rulai_skill_base')},
        awaken={r['awaken_type']:r for r in rows('awaken_skill_conf')},
        awaken_rates={r['skill_type']:float(r['plus_rate']) for r in rows('awaken_skill_rate')},
        advance={r['type_id']:r for r in rows('skill_advaced_conf')},
        cheer={r['level']:r for r in rows('cheer_skill_config')},
        policy=dict(trait_slots=4, max_rounds=30, defense_magic_weight=.25, armor_floor=.1,
                    shield_fraction=.15, shield_cap=.5, rulai_absorb_cap=.6,
                    penetration_proc_basic=1, penetration_proc_rare=2,
                    multi_spell='mutually exclusive weighted draw; normalized if sum exceeds 100',
                    damage='P²/(P+effectiveDefense); P=attack or attack+magic*intensity/100',
                    provenance='local reconstruction; rates and trait descriptions from original CSV'))


def trait_parameters(trait, rules):
    definition=rules.get('traits',{}).get(str(trait['id']))
    if not definition: return None
    level=max(1,min(definition['max_level'],int(trait.get('level',1))))
    return {**definition,'level':level,'params':[group[level-1] for group in definition['levels']]}


def damage_formula(attack, defense, magic=0, target_magic=0, intensity=0, magical=False):
    """Reconstructed monotone, bounded mitigation; no claim of official expression."""
    power=max(0,float(attack))+(max(0,float(magic))*max(0,float(intensity))/100 if magical else 0)
    mitigation=max(0,float(defense))+(max(0,float(target_magic))*.25 if magical else 0)
    return max(1,rounded(power*power/max(1,power+mitigation)))
