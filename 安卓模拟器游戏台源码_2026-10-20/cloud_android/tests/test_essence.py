import copy
import json
import tempfile
import unittest
from pathlib import Path
from game_config import load_config
from local_game.assets import catalog
from local_game.inventory import build_inventory, grant
from local_game.service import Game, GameError


class EssenceTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        root=load_config()['game_root']
        cls.c=catalog(root); cls.c['inventory']=build_inventory(root)

    def setUp(self):
        self.temp=tempfile.TemporaryDirectory(); self.addCleanup(self.temp.cleanup)
        self.game=Game(Path(self.temp.name)/'save.db',self.c); self.n=0
        self.call('login')
        s=self.raw();s['silver']=1000000;s['level']=38;s['experience']=sum(v['upgrade_exp'] for k,v in self.c['role_levels'].items() if int(k)<38)
        self.save(s)

    def call(self,op,**args):
        self.n+=1
        return self.game.request('essence-test','essence-request-'+str(self.n),op,args)

    def raw(self):
        with self.game.connect() as c:
            return json.loads(c.execute('select state from players where id=?',('essence-test',)).fetchone()[0])

    def save(self,s):
        with self.game.connect() as c:
            c.execute('update players set state=? where id=?',(json.dumps(s),'essence-test'))

    def give(self,key,count=1,level=1):
        s=self.raw();grant(s,key,count,level,catalog=self.c['inventory']);self.save(s)
        return s['inventory']['entries'][-1]['uid']

    def test_exact_costs_description_and_recipe(self):
        rules=self.c['inventory']['essence']
        self.assertEqual(rules['open_level'],0)
        self.assertEqual(rules['original_open_level'],38)
        self.assertEqual(rules['upgrade_progress'],[500,1000,1500,3000])
        self.assertEqual(rules['lock_cost'],{'1':100,'2':300,'3':700,'4':1000})
        self.assertEqual(len(rules['transforms']),19)
        from local_game.essence import describe
        item=self.c['inventory']['items']['i10216']
        self.assertIn('12.5%',describe(item,dict(level=5),self.c['inventory'])['description'])

    def test_decompose_exact_payout_retry_and_restart(self):
        for key,stones in [('i10101',20),('i10201',100)]:
            uid=self.give(key);before=self.raw()['silver']
            req='decompose-'+key
            first=self.game.request('essence-test',req,'bag_essence_decompose',dict(uid=uid))
            self.assertEqual(first,self.game.request('essence-test',req,'bag_essence_decompose',dict(uid=uid)))
            self.assertEqual(self.raw()['silver'],before-1000)
        self.assertEqual(next(e for e in self.raw()['inventory']['entries'] if e['key']=='i10000')['count'],120)
        reopened=Game(Path(self.temp.name)/'save.db',self.c)
        self.assertEqual(first,reopened.request('essence-test',req,'bag_essence_decompose',dict(uid=uid)))

    def test_transform_consumes_one_drug_and_preserves_other_instances(self):
        uid=self.give('i10215');other=self.give('i10215');self.give('i1342',2)
        self.call('bag_essence_transform',uid=uid)
        entries=self.raw()['inventory']['entries']
        self.assertTrue(any(e['uid']==other for e in entries))
        self.assertTrue(any(e['key']=='i10202' for e in entries))
        self.assertEqual(next(e['count'] for e in entries if e['key']=='i1342'),1)

    def test_rejections_are_atomic(self):
        uid=self.give('i10207');self.give('i1342')
        before=self.raw()
        for op in ['bag_essence_transform','bag_essence_inscribe','bag_essence_upgrade']:
            with self.assertRaises(GameError):self.call(op,uid=uid)
            self.assertEqual(before,self.raw())
        for change in [dict(hero=5022),dict(level=2),dict(prob_compen=1)]:
            s=copy.deepcopy(before);next(e for e in s['inventory']['entries'] if e['uid']==uid).update(change);self.save(s)
            with self.assertRaises(GameError):self.call('bag_essence_decompose',uid=uid)
            self.assertEqual(s,self.raw())

    def test_temporary_level_waiver_materials_and_decompose_money(self):
        uid=self.give('i10215');before=self.raw()
        with self.assertRaises(GameError):self.call('bag_essence_transform',uid=uid)
        self.assertEqual(before,self.raw())
        self.give('i1342');s=self.raw();s['level']=1;s['experience']=0;self.save(s)
        self.call('bag_essence_transform',uid=uid)
        self.assertTrue(any(e['key']=='i10202' for e in self.raw()['inventory']['entries']))
        uid=self.give('i10101');s=self.raw();s['silver']=999;self.save(s)
        with self.assertRaises(GameError):self.call('bag_essence_decompose',uid=uid)
        self.assertEqual(s,self.raw())
