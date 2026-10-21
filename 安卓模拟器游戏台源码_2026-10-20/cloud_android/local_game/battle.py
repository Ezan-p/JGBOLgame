"""Original battle assets and provenance, packaged without runtime research tools."""
from .assets import Resources, catalog
from .combat import resolve

# CCBI names traced from skill/skill_<id>.lua. Pair = caster / target effect.
EFFECTS = {
    6: ('jiaxue.ccbi', 'jiaxue.ccbi'),
    101: ('101_1_2.ccbi', '101_5.ccbi'), 102: ('113_1.ccbi', '208_1.ccbi'),
    103: ('114_1.ccbi', '114_2.ccbi'), 104: ('123_1.ccbi', '123_2.ccbi'),
    105: ('128_1.ccbi', '244_1.ccbi'), 106: ('101_1_2.ccbi', '135_2.ccbi'),
    107: ('131_1.ccbi', '131_2.ccbi'), 108: ('128_1.ccbi', '214_1.ccbi'),
    110: ('113_1.ccbi', '232_1.ccbi'), 112: ('113_1.ccbi', '211_1.ccbi'),
    202: ('112_11.ccbi', '112_2.ccbi'), 203: ('113_1.ccbi', '113_2.ccbi'),
    204: ('111_1.ccbi', '245_1.ccbi'), 205: ('110_11.ccbi', '110_1.ccbi'),
    206: ('201_4.ccbi', '201_5.ccbi'), 207: ('113_1.ccbi', '221_1.ccbi'),
    208: ('116_1.ccbi', '116_2.ccbi'), 209: ('1171_1.ccbi', '1171_2.ccbi'),
    210: ('118_1.ccbi', '118_1.ccbi'), 211: ('220_1.ccbi', '220_2.ccbi'),
    212: ('122_1.ccbi', '122_1.ccbi'), 213: ('243_1.ccbi', '212_1.ccbi'),
    214: ('133_1.ccbi', '133_2.ccbi'), 215: ('117_1.ccbi', '218_2.ccbi'),
    216: ('134_1.ccbi', '134_2.ccbi'), 217: ('136_1.ccbi', '136_2.ccbi'),
    218: ('242_2.ccbi', '242_1.ccbi'), 220: ('128_1.ccbi', '241_2.ccbi'),
    221: ('215_1.ccbi', '215_1.ccbi'), 222: ('209_1.ccbi', '209_1.ccbi'),
    223: ('210_1.ccbi', '210_5.ccbi'), 226: ('206_1.ccbi', '206_1.ccbi'),
}


def build_battle(game_root):
    r = Resources(game_root)
    c = catalog(game_root)
    names = set(r.names())
    dependencies = {
        'map/special/xmz.jpg', 'map/special/xmz.png', 'map/special/pty.jpg',
        'map/special/pty.png', 'blood_5.ccbi', 'blood_5_inv.ccbi', 'splash_eye.ccbi',
        'splash_light.ccbi', '127_2.ccbi', '128_2.ccbi', '130_2.ccbi', '105_1.ccbi', 'v2/enterSence.png', '123_2_1.ccbi', '204_1.ccbi', '204_2.ccbi', '106_1.ccbi',
        'number/all_number_white.fnt', 'number/all_number_white.png', 'music/fight.mp3',
        'v2/skip_fight.png', 'v2/speed_1.png', 'v2/speed_2.png',
    }
    dependencies.update(n for n in names if n.startswith('v2/fightUI/'))
    status_effects={
        '威慑':'weisheshu_001.ccbi','破甲':'pojia001.ccbi','中毒':'zhongdushu_001.ccbi',
        '毒伤':'zhongdushu_001.ccbi','愈合':'jiaxue.ccbi','嗜血':'xixue001.ccbi',
        '复活':'fuhuo001.ccbi','大乘经护盾':'dachengjinghudun.ccbi',
        '祝福':'127_2.ccbi','强壮':'130_2.ccbi','战意':'zhanyi.ccbi','招架':'gedang001.ccbi',
        '解毒':'jiaxue.ccbi'}
    status_effects={k:v for k,v in status_effects.items() if v in names}
    dependencies.update(status_effects.values())
    dependencies.update(n for n in names if 'dacheng' in n and n.endswith(('.png','.plist','.ccbi')))
    skills = {}
    for ident, row in c['skills'].items():
        sid = int(ident)
        item = {k: v for k, v in row.items() if k != 'original'}
        title = f'skill/name/{sid}.png'
        if title in names:
            item['title'] = title
            dependencies.add(title)
        if row['active'] and sid != 1:
            animation = sid if sid in EFFECTS else 101 if row['multi'] else 202
            item['animation_skill'] = animation
            item['cast'], item['impact'] = EFFECTS[animation]
            dependencies.update(EFFECTS[animation])
        if not row['active']:
            item['passive_effect'] = '130_2.ccbi' if 42<=sid<=49 else '128_2.ccbi' if 31<=sid<=39 else '127_2.ccbi'
        skills[sid] = item
    stages = {}
    for stage in c['stages']:
        original = stage['original_id']; chapter, slot = divmod(original, 100)
        def find(extension, prefix=''):
            return next((f'map/{chapter}/{prefix}{i}.{extension}' for i in range(slot, 0, -1)
                         if f'map/{chapter}/{prefix}{i}.{extension}' in names), f'map/1/{prefix}1.{extension}')
        stages[stage['id']] = {'background': find('jpg'), 'title': find('png', 'name')}
        dependencies.update(stages[stage['id']].values())
    sounds = {}
    for row in r.rows('csv_config/effect_sound.csv'):
        key = row['name'] + ('.ccbi' if row['event'] == 'ccbi' else '')
        entries = []
        for token in row['sound'].split('/'):
            ms, sep, sound = token.partition('=')
            path = f'music/{sound}.mp3'
            if sep and not sound.startswith('none') and path in names:
                entries.append({'time': int(ms)/1000, 'file': path})
                dependencies.add(path)
        if entries:
            sounds[key] = entries
    def demo(ids, background, title, opening):
        def unit(i):
            h = dict(c['heroes'][str(i)])
            h['hp'] *= 10
            if opening and i == 4020:
                h.update(skill_id=104, skill_name='龙腾滔天')  # Screenshot equipment fixture, not saved roster.
            dependencies.add(h['sprite'])
            return h
        report = resolve([unit(i) for i in ids], [unit(i) for i in [5020, 5013, 5019, 5014]], c['skills'], opening, rules=c['combat_rules'])
        return {**report, 'stage': {'id': 0, 'name': '仙盟战场', 'background': background, 'title': title},
                'preview': True, 'silver': 0, 'experience': 0, 'first_clear': False}
    reference = demo([5022, 5034, 5013, 5023], 'map/special/xmz.jpg', 'map/special/xmz.png', False)
    skill_demo = demo([4020, 5022, 5034, 5023], 'map/special/pty.jpg', 'map/special/pty.png', True)
    sources = [r.source(n) for n in ['lua/common/constants.lua', 'lua/unit/charecter.lua',
               'lua/ui/fightUI.lua', 'lua/skill/skill.lua', 'lua/skill/skill_mgr.lua',
               'csv_config/skill_base.csv', 'csv_config/skill_name.csv', 'csv_config/effect_sound.csv',
               'lua/common/msg_def.lua', 'lua/skill/skill_1_new.lua']]
    for sid in EFFECTS:
        sources.append(r.source(f'lua/skill/skill_{sid}.lua'))
    for n in dependencies:
        r.read(n)  # Fail the build on missing or corrupted dependencies.
    return {'schema': 2, 'statusEffects': status_effects, 'skills': skills, 'sounds': sounds, 'stages': stages,
            'demo': reference, 'skill_demo': skill_demo, 'resources': sorted(dependencies), 'sources': sources}
