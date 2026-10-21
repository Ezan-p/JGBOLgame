"""Export all discovered battle tables with resource hashes; no guessed server formulas."""
from .assets import Resources

TABLES = ('skill_base', 'skill_name', 'ext_skill', 'skill_ext_base', 'skill_ext_name',
          'rulai_skill_base', 'awaken_skill_conf', 'awaken_skill_rate', 'skill_advaced_conf',
          'skill_value', 'cheer_skill_config', 'effect_sound')
EXT_EVENTS = {11:'威慑',12:'威慑减伤',13:'威慑解除',21:'破甲',31:'反击',41:'反击无效',
              51:'吸血',61:'格挡',71:'连击',81:'法抗',91:'法穿',101:'恢复',111:'强袭',
              121:'战意',131:'强壮（入场被动）',141:'幸运（属性）',142:'幸运（触发）',
              151:'不倒',161:'中毒',162:'毒伤',163:'毒结束',171:'解毒',181:'祝福',191:'复活'}


def build_research(game_root):
    r = Resources(game_root)
    paths = ['csv_config/'+n+'.csv' for n in TABLES]
    scripts = ['common/msg_def', 'common/constants', 'ui/fightUI', 'ui/charPositionUI',
               'unit/charecter', 'skill/skill', 'skill/skill_mgr', 'skill/skillExt', 'skill/skill_22']
    return dict(schema=1,
                tables={name:[{k.split('(')[0]:v for k,v in row.items() if k} for row in r.rows(path)]
                        for name,path in zip(TABLES,paths)},
                extension_event_routes=EXT_EVENTS,
                paired_replacements={1:5,2:6,3:7,4:8},
                message_ids=dict(request=1026,result=1027,lineup=1028),
                implemented=['paired reserves','single/multi active spells','native and two equipped spells',
                             'configured base proc rates','level growth','stat passives','original CCBI player'],
                server_unknown=['formula expressions','multi-spell arbitration','initiative and target selection',
                                'prob_compen semantics','awaken/advance stacking','shield amount and event ordering'],
                not_enabled=['extension equipment/proc engine','rulai absorption/shield','awakening/advancement',
                             'original PVP matchmaking/rewards','scripted stage step/revival events'],
                sources=[r.source(p) for p in paths+['lua/'+s+'.lua' for s in scripts]])
