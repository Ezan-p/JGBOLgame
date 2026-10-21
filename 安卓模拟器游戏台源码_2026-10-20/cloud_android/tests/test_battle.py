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
        self.assertTrue(any(e['skill_name'] == '蓄力一击' for e in report['events']))

    def test_healing_caps_at_max_and_does_not_revive(self):
        hero = dict(self.catalog['heroes']['5022'], skill_id=6, hp=1000, attack=30)
        foe = dict(hero, skill_id=1, attack=20)
        report = resolve([hero], [foe], self.catalog['skills'])
        healing = [h for e in report['events'] if e['kind']=='heal' for h in e['hits']]
        self.assertTrue(healing)
        self.assertTrue(all(h['damage'] < 0 and h['hp'] <= 1000 for h in healing))
        self.assertLessEqual(report['turns'], 30)
