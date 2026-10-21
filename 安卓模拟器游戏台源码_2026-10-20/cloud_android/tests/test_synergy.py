import copy
import json
import tempfile
import unittest
from pathlib import Path
from game_config import load_config
from local_game.assets import catalog
from local_game.inventory import build_inventory, grant
from local_game.synergy import build_synergy
from local_game.service import Game, GameError


class SynergyTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        root=load_config()['game_root'];cls.catalog=catalog(root)
        cls.catalog['inventory']=build_inventory(root);cls.catalog['synergy']=build_synergy(root)

    def setUp(self):
        self.tmp=tempfile.TemporaryDirectory();self.addCleanup(self.tmp.cleanup)
        self.game=Game(Path(self.tmp.name)/'save.db',self.catalog);self.player='synergy-test-player';self.n=0
        self.call('login');s=self.raw();s['heroes'].update({str(i):1 for i in [5018,5023,5034,5013,5002,4061]});self.save(s)

    def call(self,op,**args):
        self.n+=1;return self.game.request(self.player,'synergy-request-%04d'%self.n,op,args)

    def raw(self):
        with self.game.connect() as db:return json.loads(db.execute('select state from players where id=?',(self.player,)).fetchone()[0])

    def save(self,s):
        with self.game.connect() as db:db.execute('update players set state=? where id=?',(json.dumps(s),self.player))

    def hero(self,i=5022):return next(h for h in self.call('state')['state']['heroes'] if h['id']==i)

    def give(self,key,count=1):
        s=self.raw();grant(s,key,count,catalog=self.catalog['inventory']);self.save(s)
        return next(e['uid'] for e in reversed(s['inventory']['entries']) if e['key']==key)

    def test_original_tables_and_empty_migration(self):
        s=self.catalog['synergy'];self.assertEqual(sum(map(len,s['fates'].values())),690)
        self.assertEqual(len(s['slots']),8)
        self.assertEqual(s['slots']['1']['levels']['1']['ratios']['hp'],'0.04')
        self.assertEqual(s['slots']['1']['levels']['10']['ratios']['attack'],'0.175')
        self.assertEqual(s['slots']['1']['levels']['2']['cost'],25)
        before=self.raw();v=self.call('state')['state'];self.assertEqual(len(v['support']['slots']),8)
        self.assertNotIn('support',self.raw())
        for k in ['heroes','silver','lineup','wins','inventory']:self.assertEqual(before.get(k),self.raw().get(k))

    def test_equipment_and_spell_fates_recalculate_and_do_not_use_others_items(self):
        base=self.hero();armor=self.give('i3002');cloud=self.give('i4002');spell=self.give('s43')
        self.call('bag_equip',uid=armor,hero=5004);self.assertEqual(self.hero()['defense'],base['defense'])
        self.call('bag_equip',uid=armor,hero=5022);self.call('bag_equip',uid=cloud,hero=5022)
        h=self.hero();self.assertEqual(h['fate_percent']['defense'],24)
        self.assertEqual(h['defense'],(base['defense']+101)+round((base['defense']+101)*.24))
        self.call('bag_equip',uid=spell,hero=5022);h=self.hero()
        self.assertEqual(h['fate_percent']['attack'],15)
        self.assertTrue(next(f for f in h['fates'] if f['name']=='火眼金睛')['active'])
        self.call('bag_equip',uid=armor,hero=0);self.assertEqual(self.hero()['fate_percent']['defense'],12)
        self.call('bag_equip',uid=cloud,hero=0);self.assertEqual(self.hero()['defense'],base['defense'])
        self.call('bag_equip',uid=spell,hero=0);self.assertEqual(self.hero()['attack'],base['attack'])

    def test_roster_fate_requires_every_member_and_counts_support(self):
        s=self.raw();s['lineup']=[5022,5004,5018];self.save(s)
        self.assertEqual(self.hero()['fate_percent']['defense'],0) # owning Tang is insufficient
        self.call('support_assign',slot=1,hero=5023)
        h=self.hero();self.assertEqual(h['fate_percent']['defense'],30)
        self.assertEqual(h['defense'],99) # original Sun base 76, round-half-up 22.8 =>23
        self.call('support_assign',slot=1,hero=0)
        self.assertEqual(self.hero()['fate_percent']['defense'],0)

    def test_additive_fates_and_nonrecursive_support_reach_battle(self):
        self.call('support_assign',slot=1,hero=5034)
        self.call('support_assign',slot=2,hero=5013)
        h=self.hero();self.assertEqual(h['fate_percent']['attack'],40)
        before=h['attack'];source=self.hero(5034)
        self.call('support_target',slot=1,target=1)
        h=self.hero();self.assertEqual(h['attack'],before+int(source['attack']*.026))
        self.assertEqual(h['hp'],h['pre_fate_stats']['hp']+h['fate_bonus']['hp']+int(source['hp']*.04))
        report=self.call('battle',stage=1)['battle']
        for key in ['hp','attack','defense','magic','fate_bonus','support_bonus']:
            self.assertEqual(report['units'][0][key],h[key])
        self.assertEqual(len([u for u in report['units'] if u['side']==0]),2)
        self.assertEqual(self.hero(5034)['support_bonus']['attack'],0)

    def test_support_restrictions_atomic_failures_and_single_target_transfer(self):
        self.call('support_assign',slot=1,hero=4061)
        for op,args in [('support_target',dict(slot=1,target=1)),('support_assign',dict(slot=2,hero=4061)),
                        ('lineup',dict(hero=4061)),('lineup_replace',dict(slot=1,hero=4061)),
                        ('support_assign',dict(slot=3,hero=5022)),('support_assign',dict(slot=True,hero=5002)),
                        ('support_assign',dict(slot=9,hero=5002)),('support_target',dict(slot=1,target=-1)),
                        ('support_upgrade',dict(slot=1)),('support_buy_material',dict(slot=1,count=-1))]:
            before=self.raw()
            with self.assertRaises(GameError):self.call(op,**args)
            self.assertEqual(self.raw(),before)
        self.call('support_assign',slot=1,hero=5002);self.call('support_assign',slot=2,hero=5034)
        self.call('support_target',slot=1,target=1);self.call('support_target',slot=2,target=1)
        self.assertEqual(self.raw()['support']['slots']['1']['target'],0)
        self.assertEqual(len(self.hero()['support_sources']),1)

    def test_support_upgrade_purchase_idempotency_and_persistence(self):
        self.call('support_buy_material',slot=1,count=25)
        self.assertEqual(self.raw()['silver'],200)
        self.call('support_assign',slot=1,hero=5002);self.call('support_target',slot=1,target=1)
        args=dict(slot=1);first=self.game.request(self.player,'unique-upgrade-request','support_upgrade',args)
        again=self.game.request(self.player,'unique-upgrade-request','support_upgrade',args);self.assertEqual(first,again)
        s=first['state']['support'];self.assertEqual(s['material'],0);self.assertEqual(s['slots'][0]['level'],2)
        self.assertEqual(s['slots'][0]['ratios']['hp'],.051)
        resumed=Game(self.game.db,self.catalog).view(self.raw());self.assertEqual(resumed['support'],s)
        for _ in range(8):
            self.give('i1015',500);self.call('support_upgrade',slot=1)
        self.assertEqual(self.raw()['support']['slots']['1']['level'],10)
        before=self.raw()
        with self.assertRaises(GameError):self.call('support_upgrade',slot=1)
        self.assertEqual(self.raw(),before)

    def test_target_is_combat_slot_and_cleans_up_removed_slot(self):
        self.call('support_assign',slot=1,hero=5002);self.call('support_target',slot=1,target=2)
        self.assertGreater(self.hero(5004)['support_bonus']['hp'],0)
        self.call('lineup_swap',source=1,target=2)
        self.assertGreater(self.hero(5022)['support_bonus']['hp'],0)
        self.assertEqual(self.hero(5004)['support_bonus']['hp'],0)
        self.call('lineup',hero=5022)
        self.assertEqual(self.raw()['support']['slots']['1']['target'],0)

    def test_magic_fate_is_visible_and_equipped_source_upgrade_updates_transfer(self):
        s=self.raw();s['heroes']['3035']=1;self.save(s)
        self.call('support_assign',slot=1,hero=5002);self.call('support_assign',slot=2,hero=3035)
        cow=self.hero(5002);self.assertEqual(cow['fate_percent']['magic'],15)
        self.assertGreater(cow['magic'],cow['pre_fate_stats']['magic'])
        self.call('support_target',slot=1,target=1);before=self.hero()['support_bonus']['attack']
        uid=self.give('i2006');self.call('bag_equip',uid=uid,hero=5002)
        self.assertGreater(self.hero()['support_bonus']['attack'],before)
        armor=self.give('i3002');self.call('bag_equip',uid=armor,hero=5002)
        armor_fate=next(f for f in self.hero(5002)['fates'] if f['name']=='黄金甲')
        self.assertFalse(armor_fate['active'])
        self.assertFalse(armor_fate['applicable'])
