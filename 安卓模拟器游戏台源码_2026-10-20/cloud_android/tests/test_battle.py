import copy
import unittest
from game_config import load_config
from local_game.assets import catalog, Resources
from local_game.battle import build_battle, EFFECTS
from local_game.combat import resolve


class BattleTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.root = load_config()['game_root']
        cls.catalog = catalog(cls.root)
        cls.data = build_battle(cls.root)

    def test_reference_art_and_native_effects(self):
        self.assertEqual(self.data['demo']['stage']['background'], 'map/special/xmz.jpg')
        self.assertEqual(self.data['skills'][104]['name'], '龙腾滔天')
        self.assertEqual(self.data['skills'][104]['title'], 'skill/name/104.png')
        self.assertEqual(self.data['skills'][104]['impact'], '123_2.ccbi')
        r = Resources(self.root)
        for pair in EFFECTS.values():
            for path in pair:
                self.assertTrue(r.read(path).startswith(b'ibcc'), path)
        for path in self.data['resources']:
            self.assertTrue(r.read(path), path)
        self.assertEqual(len(self.data['demo']['units']), 8)
        self.assertEqual(self.data['skill_demo']['events'][0]['skill_id'], 104)
        self.assertEqual(len(self.data['skill_demo']['events'][0]['hits']), 4)

    def test_reports_conserve_hp_and_never_act_after_death(self):
        for name in ('demo', 'skill_demo'):
            report = self.data[name]
            hp = {u['uid']: u['hp'] for u in report['units']}
            maximum = hp.copy()
            for event in report['events']:
                self.assertGreater(hp[event['actor']], 0)
                for hit in event['hits']:
                    uid = hit['target']
                    self.assertGreater(hp[uid], 0)
                    self.assertEqual(hp[uid] - hit['damage'], hit['hp'])
                    hp[uid] = hit['hp']
                    self.assertTrue(0 <= hp[uid] <= maximum[uid])
            won = any(v > 0 for k, v in hp.items() if k.startswith('0-')) and not any(v > 0 for k, v in hp.items() if k.startswith('1-'))
            self.assertEqual(report['won'], won)

    def test_deterministic_replay_does_not_mutate_inputs(self):
        units = self.data['demo']['units']
        a, b = units[:4], units[4:]
        snapshot = copy.deepcopy((a, b))
        one = resolve(a, b, self.catalog['skills'])
        two = resolve(a, b, self.catalog['skills'])
        self.assertEqual(one, two)
        self.assertEqual((a, b), snapshot)

    def test_passive_native_skill_is_not_cast_as_active(self):
        report = self.data['demo']
        for event in report['events']:
            if event['skill_id'] != 1:
                self.assertTrue(self.catalog['skills'][str(event['skill_id'])]['active'])
        self.assertFalse(any(e['skill_name'] == '蓄力一击' for e in report['events']))

    def test_healing_caps_at_max_and_does_not_revive(self):
        hero = dict(self.catalog['heroes']['5022'], skill_id=6, hp=1000, attack=30)
        foe = dict(hero, skill_id=1, attack=20)
        skills = copy.deepcopy(self.catalog['skills'])
        skills['6']['original']['use_probability'] = '100'  # Scripted heal fixture; original tutorial value is zero.
        report = resolve([hero], [foe], skills)
        healing = [h for e in report['events'] if e['kind']=='heal' for h in e['hits']]
        self.assertTrue(healing)
        self.assertTrue(all(h['damage'] < 0 and h['hp'] <= 1000 for h in healing))
        self.assertLessEqual(report['turns'], 30)

    def test_reserves_are_untargetable_and_replace_only_paired_position(self):
        def unit(slot, hp, attack=1):
            return dict(self.catalog['heroes']['5022'], skill_id=1, lineup_slot=slot,
                        hp=hp, attack=attack, defense=0)
        report = resolve([unit(1, 10), unit(2, 1000), unit(5, 1000), unit(6, 1000)],
                         [unit(1, 100000, 30)], self.catalog['skills'])
        field = {u['uid'] for u in report['units'] if u['in_field']}
        deaths = set()
        for e in report['events']:
            if e['kind'] == 'enter':
                self.assertIn(e['replaces'], deaths)
                self.assertEqual(int(e['actor'][2:]), int(e['replaces'][2:])+4)
                field.add(e['actor'])
            else:
                self.assertIn(e['actor'], field-deaths)
                for h in e['hits']:
                    self.assertIn(h['target'], field-deaths)
                    if not h['hp']: deaths.add(h['target'])
        entries = [e['actor'] for e in report['events'] if e['kind']=='enter']
        self.assertIn('0-4', entries)
        self.assertNotIn('0-5', entries)

    def test_group_kill_enters_all_four_reserves_before_next_attack(self):
        skills = copy.deepcopy(self.catalog['skills'])
        skills['104']['original']['use_probability'] = '100'
        front = [dict(self.catalog['heroes']['5022'], skill_id=1, hp=10, attack=1, defense=0) for _ in range(8)]
        for u in front[4:]: u['hp'] = 10000
        foe = dict(front[0], hp=100000, skill_id=104, magic=100, attack=100)
        report = resolve(front, [foe], skills)
        start = next(i for i,e in enumerate(report['events']) if e['actor']=='1-0')
        hit = report['events'][start]
        self.assertEqual(len(hit['hits']),4)
        self.assertTrue(all(h['hp']==0 for h in hit['hits']))
        self.assertEqual([e['actor'] for e in report['events'][start+1:start+5]], ['0-4','0-5','0-6','0-7'])
        self.assertTrue(all(e['kind']=='enter' for e in report['events'][start+1:start+5]))

    def test_equipped_spells_both_cast_and_levels_increase_damage(self):
        hero = dict(self.catalog['heroes']['5022'], hp=100000, attack=10, magic=100,
                    spells=[dict(id=45, level=1, position=1), dict(id=202, level=1, position=2), dict(id=104, level=1, position=3)])
        foe = dict(hero, skill_id=1, spells=[], defense=0, attack=1)
        casts = set()
        for seed in range(10):
            report = resolve([hero], [foe], self.catalog['skills'], seed=seed)
            casts.update(e['skill_id'] for e in report['events'] if e['actor']=='0-0')
        self.assertTrue({1,202,104}.issubset(casts))
        low = resolve([hero], [foe], self.catalog['skills'], opening_skill=True)
        higher = copy.deepcopy(hero);higher['spells'][1]['level']=10
        high = resolve([higher], [foe], self.catalog['skills'], opening_skill=True)
        self.assertGreater(high['events'][0]['damage'],low['events'][0]['damage'])

    def test_zero_probability_never_auto_casts_and_seed_changes_replay(self):
        hero = dict(self.catalog['heroes']['5022'], skill_id=6, hp=100000)
        foe = dict(hero, skill_id=202)
        one = resolve([hero], [foe], self.catalog['skills'], seed=21)
        two = resolve([hero], [foe], self.catalog['skills'], seed=22)
        self.assertTrue(all(e['skill_id']==1 for e in one['events'] if e['actor']=='0-0'))
        self.assertNotEqual(one['events'], two['events'])

    def test_reserve_in_empty_pair_enters_at_start_and_can_win(self):
        hero = dict(self.catalog['heroes']['5022'], lineup_slot=8, attack=99999)
        foe = dict(self.catalog['heroes']['5004'], hp=1)
        report = resolve([hero], [foe], self.catalog['skills'])
        self.assertEqual(report['events'][0]['kind'], 'enter')
        self.assertEqual(report['events'][0]['actor'], '0-7')
        self.assertTrue(report['won'])
