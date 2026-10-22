import copy
import json
import random
import sqlite3
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

from game_config import load_config
from local_game.assets import catalog
from local_game.inventory import build_inventory,grant
from local_game.combat import resolve,Battle
from local_game.battle_rules import damage_formula
from local_game.service import Game,GameError


class CombatV4Tests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.c=catalog(load_config()['game_root']);cls.rules=cls.c['combat_rules']

    def unit(self,*traits,**kw):
        return dict(dict(self.c['heroes']['5022'],skill_id=1,spells=[],hp=20000,attack=100,defense=80,magic=100,
                         traits=[dict(id=i,level=5) for i in traits]),**kw)

    def battle(self,a,b,**kw):return Battle(a,b,self.c['skills'],12,self.rules,False,'pve',0,**kw)
    def run_report(self,a,b,seed=1):return resolve(a,b,self.c['skills'],seed=seed,rules=self.rules)

    def assert_replay(self,r):
        hp={u['uid']:u['hp'] for u in r['units']};maximum={u['uid']:u['max_hp'] for u in r['units']}
        for e in r['events']:
            if e['kind'] in ('attack','skill','heal'):self.assertGreater(hp[e['actor']],0)
            for h in e['hits']:
                ident=h['target']
                self.assertEqual(hp[ident]-h['damage'],h['hp'],(e['skill_name'],h))
                if h.get('revive'):self.assertEqual(hp[ident],0)
                elif h['damage']<0:self.assertGreater(hp[ident],0)
                hp[ident]=h['hp'];maximum[ident]=h.get('max_hp',maximum[ident])
                self.assertTrue(0<=hp[ident]<=maximum[ident])
                self.assertGreaterEqual(h.get('shield',0),0)
            for change in e['changes']:
                hp[change['target']]=change['hp'];maximum[change['target']]=change['max_hp']
        self.assertEqual(hp,{u['uid']:u['hp'] for u in r['final_units']})
        self.assertLess(len(r['events']),5000)

    def test_formula_is_monotone_positive_and_magic_is_not_mana(self):
        for attack in (1,100,10000):
            values=[damage_formula(attack,d) for d in (0,100,10000,1000000)]
            self.assertEqual(values,sorted(values,reverse=True));self.assertGreaterEqual(min(values),1)
        for defense in (0,100,10000):
            values=[damage_formula(a,defense,200,100,150,True) for a in (1,100,10000)]
            self.assertEqual(values,sorted(values))
        self.assertGreater(damage_formula(100,100,1000,0,150,True),damage_formula(100,100,100,0,150,True))
        self.assertLess(damage_formula(100,100,1000,1000,150,True),damage_formula(100,100,1000,0,150,True))

    def test_formation_action_order_attacker_back_front_top_bottom(self):
        allies=[self.unit(hp=1000000,attack=5,lineup_slot=s) for s in (1,2,3,4)]
        enemies=[self.unit(hp=1000000,attack=5,lineup_slot=s) for s in (1,2,3,4)]
        report=self.run_report(allies,enemies)
        first=[e['actor'] for e in report['events'] if e['turn']==1 and e['kind'] in ('attack','skill')]
        self.assertEqual(first,['0-0','1-1','0-1','1-0','0-2','1-3','0-3','1-2'])
        mirrored=resolve(allies,enemies,self.c['skills'],seed=1,rules=self.rules,first_side=1)
        first=[e['actor'] for e in mirrored['events'] if e['turn']==1 and e['kind'] in ('attack','skill')]
        self.assertEqual(first,['1-0','0-1','1-1','0-0','1-2','0-3','1-3','0-2'])

    def test_lanes_target_front_then_back_then_top_before_bottom(self):
        allies=[self.unit(hp=1000000,attack=100,lineup_slot=s) for s in (1,2,3,4)]
        enemies=[self.unit(hp=1000000,attack=1,lineup_slot=s) for s in (1,2,3,4)]
        b=self.battle(allies,enemies)
        by_slot={u['slot']:u for u in b.teams[0]}
        back,front,top,bottom=(by_slot[s] for s in (1,2,3,4))
        enemy={u['slot']:u for u in b.teams[1]}
        self.assertEqual([b.lane(u) for u in (back,front,top,bottom)],['back','front','top','bottom'])
        self.assertEqual([b.position(u) for u in (back,front,top,bottom)],[1,2,3,4])
        self.assertEqual([t['slot'] for t in b.select_targets(back)],[2])
        self.assertEqual([t['slot'] for t in b.select_targets(front)],[2])
        self.assertEqual([t['slot'] for t in b.select_targets(top)],[3])
        self.assertEqual([t['slot'] for t in b.select_targets(bottom)],[4])
        enemy[3]['hp']=0
        self.assertEqual([t['slot'] for t in b.select_targets(top)],[2])
        enemy[1]['hp']=enemy[2]['hp']=0
        self.assertEqual([t['slot'] for t in b.select_targets(top)],[4])
        self.assertEqual([t['slot'] for t in b.select_targets(back)],[4])
        enemy[3]['hp']=enemy[4]['hp']=100
        self.assertEqual([t['slot'] for t in b.select_targets(back)],[3])
        enemy[3]['hp']=0
        self.assertEqual([t['slot'] for t in b.select_targets(back)],[4])

    def test_front_and_its_reserve_shield_back_until_both_die(self):
        allies=[self.unit(hp=1000000,attack=100,lineup_slot=s) for s in (1,2,3,4)]
        enemies=[self.unit(hp=1000000,attack=1,lineup_slot=s) for s in range(1,7)]
        b=self.battle(allies,enemies)
        enemy={u['slot']:u for u in b.teams[1]}
        back=next(u for u in b.teams[0] if u['slot']==1)
        self.assertFalse(enemy[6]['in_field']);self.assertFalse(enemy[5]['in_field'])
        self.assertEqual([t['slot'] for t in b.select_targets(back)],[2])
        enemy[2]['hp']=0;enemy[2]['_dead']=True;b.enter()
        self.assertTrue(enemy[6]['in_field'])
        self.assertEqual([t['slot'] for t in b.select_targets(back)],[6])
        enemy[6]['hp']=0;enemy[6]['_dead']=True;b.enter()
        self.assertEqual([t['slot'] for t in b.select_targets(back)],[1])
        enemy[1]['hp']=0;enemy[1]['_dead']=True;b.enter()
        self.assertTrue(enemy[5]['in_field'])
        self.assertEqual([t['slot'] for t in b.select_targets(back)],[5])
        enemy[5]['hp']=0;enemy[5]['_dead']=True;b.enter()
        self.assertEqual([t['slot'] for t in b.select_targets(back)],[3])

    def test_group_spell_still_hits_every_living_enemy(self):
        caster=self.unit(hp=1000000,attack=10,lineup_slot=1)
        b=self.battle([caster],[self.unit(hp=1000000,lineup_slot=s) for s in (1,2,3,4)])
        self.assertEqual(len(b.select_targets(b.teams[0][0],multi=True)),4)

    def test_original_parameters_and_all_38_traits_are_live(self):
        self.assertEqual(len(self.rules['traits']),38)
        self.assertEqual(self.rules['traits']['10216']['levels'][1][-1],.125)
        self.assertEqual(self.rules['traits']['10219']['levels'][0][-1],.12)
        covered=set()
        with patch.object(Battle,'chance',lambda self,u,name,p:p>0):
            for ident in map(int,self.rules['traits']):
                a=self.unit(ident,hp=100 if ident%100==19 else 5000);b=self.unit(10203,10211,hp=100000,attack=110)
                report=self.run_report([a],[b]);self.assert_replay(report)
                covered.update(e['skill_name'] for e in report['events'])
        self.assertTrue({'反击','连击','破甲','威慑','毒伤','愈合','战意','祝福','强壮','复活','嗜血'}.issubset(covered),covered)

    def test_revive_limits_and_substitution_order(self):
        for ident,limit in ((10119,1),(10219,2)):
            with patch.object(Battle,'chance',lambda self,u,name,p:True):
                r=self.run_report([self.unit(ident,hp=10,attack=1),self.unit(hp=10,attack=1,lineup_slot=5)],
                                  [self.unit(attack=10000)])
            revived=[i for i,e in enumerate(r['events']) if e['skill_name']=='复活']
            entered=[i for i,e in enumerate(r['events']) if e['kind']=='enter']
            self.assertEqual(len(revived),limit);self.assertGreater(entered[0],revived[-1]);self.assert_replay(r)

    def test_poison_expiry_cap_and_cleanse_before_tick(self):
        b=self.battle([self.unit(10216)],[self.unit(hp=10000000)])
        with patch.object(Battle,'chance',lambda self,u,name,p:True):b.strike(b.teams[0][0],b.teams[1])
        for t in range(1,5):b.turn=t;b.round_start()
        ticks=[e for e in b.events if e['skill_name']=='毒伤']
        self.assertEqual(len(ticks),3);self.assertTrue(all(e['hits'][0]['damage']==200000 for e in ticks))
        b=self.battle([self.unit(10216)],[self.unit(10217)])
        with patch.object(Battle,'chance',lambda self,u,name,p:True):
            b.strike(b.teams[0][0],b.teams[1]);b.turn=2;b.round_start()
        self.assertIn('解毒',[e['skill_name'] for e in b.events]);self.assertNotIn('毒伤',[e['skill_name'] for e in b.events])

    def test_poison_damage_credited_even_after_caster_dies(self):
        b=self.battle([self.unit(10216)],[self.unit(hp=100000)])
        with patch.object(Battle,'chance',lambda self,u,name,p:p>0):b.strike(b.teams[0][0],b.teams[1])
        before=b.total_damage[0]
        b.teams[0][0]['hp']=0;b.turn=2;b.round_start()
        ticks=[e for e in b.events if e['skill_name']=='毒伤']
        self.assertEqual(b.total_damage[0]-before,sum(h['damage'] for e in ticks for h in e['hits']))
        self.assertGreater(b.total_damage[0],before)

    def test_shield_absorption_rulai_sharing_and_no_recursive_transfer(self):
        guard=self.unit(magic=800,spells=[dict(id=21,level=1,position=1)])
        b=self.battle([self.unit(attack=1000)],[self.unit(defense=0),guard,copy.deepcopy(guard)])
        source,target=b.teams[0][0],b.teams[1][0]
        self.assertAlmostEqual(b.rulai(b.teams[1][1])[0],.04)
        target['shield']=100
        hits=b.damage_hits(source,target,1000,'attack')
        self.assertEqual(sum(h['damage'] for h in hits)+sum(h['absorbed'] for h in hits),1000)
        self.assertEqual(len(hits),3);self.assertEqual(hits[0]['damage'],828)
        with patch.object(Battle,'chance',lambda self,u,name,p:True):
            for _ in range(100):b.shield_proc(b.teams[1][1])
        self.assertTrue(all(u['shield']<=u['max_hp']*.5 for u in b.units()))

    def test_lucky_execute_dodge_and_combo_execute_exclusion(self):
        b=self.battle([self.unit(10207,10215,attack=500)],[self.unit(10214,hp=10)])
        with patch.object(Battle,'chance',lambda self,u,name,p:True):
            b.strike(b.teams[0][0],b.teams[1],cause='execute',react=False)
        self.assertTrue(b.events[-1]['hits'][0]['dodged']);self.assertEqual(b.teams[1][0]['hp'],10)
        b=self.battle([self.unit(10207,10215)],[self.unit(hp=10000)])
        target=b.teams[1][0];target['hp']=1000
        with patch.object(Battle,'chance',lambda self,u,name,p:True):b.strike(b.teams[0][0],[target])
        causes=[e.get('cause') for e in b.events]
        self.assertIn('combo',causes);self.assertNotIn('execute',causes)

    def test_armor_floor_counter_parry_and_resistance_penetration(self):
        b=self.battle([self.unit(10202,10204)],[self.unit(10203,hp=100000)])
        with patch.object(Battle,'chance',lambda self,u,name,p:True):
            for _ in range(30):b.strike(b.teams[0][0],b.teams[1])
        self.assertGreaterEqual(b.teams[1][0]['defense'],8)
        self.assertIn('招架',[e['skill_name'] for e in b.events])
        self.assertNotIn('counter',[e.get('cause') for e in b.events])
        spell=dict(id=202,position=1,level=1);spec=self.c['skills']['202'];damages=[]
        for traits in ((),(10209,)):
            b=self.battle([self.unit(*traits)],[self.unit(10208)])
            b.strike(b.teams[0][0],b.teams[1],spell,spec,react=False)
            damages.append(b.events[0]['hits'][0]['damage'])
        self.assertGreater(damages[1],damages[0])

    def test_step_gated_entrances_cannot_produce_premature_victory(self):
        r=self.run_report([self.unit(attack=1000)],[self.unit(hp=1),self.unit(hp=1000,lineup_slot=5,step=10)])
        entry=next(e for e in r['events'] if e['kind']=='enter')
        self.assertEqual(entry['action_step'],10);self.assertTrue(r['won']);self.assert_replay(r)

    def test_critical_and_death_prevention_precede_revival(self):
        attacker=self.unit(attack=10000,crit_rate=1,crit_bonus=.45)
        target=self.unit(10219,hp=100,death_prevent_rate=1,death_prevent_limit=1)
        b=self.battle([attacker],[target])
        with patch.object(Battle,'chance',lambda self,u,name,p:p>0):
            b.strike(b.teams[0][0],b.teams[1],react=False)
            self.assertEqual(b.teams[1][0]['hp'],1)
            self.assertTrue(b.events[0]['hits'][0]['prevented']);self.assertIn('暴击',b.events[0]['tags'])
            self.assertFalse(any(e['skill_name']=='复活' for e in b.events))
            b.strike(b.teams[0][0],b.teams[1],react=False)
        self.assertTrue(any(e['skill_name']=='复活' for e in b.events))

    def test_seeded_interaction_fuzz_and_input_immutability(self):
        gen=random.Random(101);ids=list(map(int,self.rules['traits']))
        for seed in range(16):
            teams=[[self.unit(*gen.sample(ids,4),hp=gen.randint(300,4000),attack=gen.randint(30,900),
                              spells=[dict(id=21 if i==0 else 104,level=5,position=1)]) for i in range(8)] for _ in range(2)]
            saved=copy.deepcopy(teams);r=self.run_report(*teams,seed=seed);self.assert_replay(r)
            self.assertEqual(teams,saved);self.assertEqual(r,self.run_report(*teams,seed=seed))


class CombatProgressionTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        root=load_config()['game_root'];cls.c=catalog(root);cls.c['inventory']=build_inventory(root)
    def setUp(self):
        self.temp=tempfile.TemporaryDirectory();self.addCleanup(self.temp.cleanup)
        self.game=Game(Path(self.temp.name)/'game.db',self.c);self.player='combat-v4-tests';self.counter=0
        self.call('login');s=self.raw();s['silver']=1000000;s['heroes']['5022']=20;self.save(s)
    def call(self,op,**args):
        self.counter+=1;return self.game.request(self.player,'v4-request-'+str(self.counter),op,args)
    def raw(self):
        with self.game.connect() as c:return json.loads(c.execute('select state from players where id=?',(self.player,)).fetchone()[0])
    def save(self,s):
        with self.game.connect() as c:c.execute('update players set state=? where id=?',(json.dumps(s),self.player))
    def give(self,key,level=1,count=1):
        s=self.raw();grant(s,key,count=count,level=level,catalog=self.c['inventory']);self.save(s);return s['inventory']['entries'][-1]['uid']
    def test_traits_purchase_upgrade_equip_reject_duplicates_and_retry(self):
        self.call('bag_buy',key='i10103');uid=self.raw()['inventory']['entries'][-1]['uid']
        first=self.game.request(self.player,'same-trait','bag_equip',dict(uid=uid,hero=5022))
        self.assertEqual(first,self.game.request(self.player,'same-trait','bag_equip',dict(uid=uid,hero=5022)))
        self.call('bag_upgrade',uid=uid)
        hero=self.game.hero(5022,20,self.raw());self.assertEqual(hero['traits'],[dict(id=10103,level=2)])
        other=self.give('i10203');before=self.raw()
        with self.assertRaises(GameError):self.call('bag_equip',uid=other,hero=5022)
        self.assertEqual(before,self.raw())
        for ident in (10101,10102,10105):self.call('bag_equip',uid=self.give('i'+str(ident)),hero=5022)
        uid=self.give('i10106');before=self.raw()
        with self.assertRaises(GameError):self.call('bag_equip',uid=uid,hero=5022)
        self.assertEqual(before,self.raw())
    def test_native_level_awaken_materials_and_stats_only_once(self):
        for _ in range(9):self.call('battle_native_upgrade',hero=5022)
        before=self.raw()
        with self.assertRaises(GameError):self.call('battle_awaken',hero=5022,kind=1)
        self.assertEqual(before,self.raw())
        self.give('s42');self.give('s43');old=self.game.hero(5022,20,self.raw())
        self.call('battle_awaken',hero=5022,kind=1);new=self.game.hero(5022,20,self.raw())
        self.assertGreater(new['attack'],old['attack']+1500)
        report=self.call('battle',stage=1)['battle'];self.assertEqual(report['units'][0]['attack'],new['attack'])
        self.assertEqual(report['units'][0]['spells'][0]['awaken'],1)
        self.assertFalse(self.raw()['inventory']['entries'])
    def test_advance_consumes_spares_not_equipped_target(self):
        target=self.give('s43',10);self.call('bag_equip',uid=target,hero=5022,equip_pos=2)
        before=self.raw()
        with self.assertRaises(GameError):self.call('bag_advance',uid=target)
        self.assertEqual(before,self.raw())
        self.give('s43');self.give('s45');old=self.game.hero(5022,20,self.raw())
        self.call('bag_advance',uid=target);new=self.game.hero(5022,20,self.raw())
        self.assertGreater(new['hp'],old['hp']);self.assertEqual(len(self.raw()['inventory']['entries']),1)
    def test_modes_are_playable_persistent_idempotent_and_do_not_unlock_story(self):
        for mode in ('elite','arena','guild','story'):
            s=self.raw();s['energy']=60;self.save(s)
            first=self.game.request(self.player,'mode-'+mode,'battle_mode',dict(mode=mode))
            self.assertEqual(first,self.game.request(self.player,'mode-'+mode,'battle_mode',dict(mode=mode)))
            report=first['battle'];self.assertEqual(report['mode'],mode);self.assertTrue(report['events'])
            self.assertEqual(first['state']['unlocked'],s['unlocked'])
            self.assertEqual(first['state']['battle_count'],s['battle_count']+1)
            self.assertGreaterEqual(first['state']['battle_modes'][mode]['attempts'],1)
        before=self.raw()
        with self.assertRaises(GameError):self.call('battle_mode',mode='unknown')
        self.assertEqual(self.raw(),before)

    def test_awakening_stars_are_equippable_only_after_awaken_and_affect_combat(self):
        uid=self.give('i14311',10);before=self.raw()
        with self.assertRaises(GameError):self.call('bag_equip',uid=uid,hero=5022)
        self.assertEqual(before,self.raw())
        s=self.raw();s['battle_training']={'5022':dict(native_level=10,awaken=1)};self.save(s)
        self.call('bag_equip',uid=uid,hero=5022)
        hero=self.game.hero(5022,20,self.raw());self.assertEqual(hero['crit_rate'],.25)
        uid=self.give('i14315',10);self.call('bag_equip',uid=uid,hero=5022)
        hero=self.game.hero(5022,20,self.raw());self.assertEqual(hero['death_prevent_limit'],1)
        self.assertEqual(hero['death_prevent_rate'],.15)
        self.assertEqual(len(self.c['combat_rules']['stars']),75)

    def test_cheer_spell_upgrade_uses_original_material_count(self):
        s=self.raw();s['heroes']['5034']=1;s['support']={'slots':{'1':dict(hero=5034,level=1,target=1)}};self.save(s)
        self.call('bag_buy',key='i1206',count=600)
        uid=self.give('s43',10);self.call('bag_equip',uid=uid,hero=5034,equip_pos=2)
        before=self.game.hero(5034,1,self.raw());self.call('battle_cheer_upgrade',hero=5034)
        after=self.game.hero(5034,1,self.raw());self.assertGreaterEqual(after['attack'],before['attack'])
        self.assertEqual(after['battle_training']['cheer_level'],1)
        self.assertFalse(any(e['key']=='i1206' for e in self.raw()['inventory']['entries']))
        before=self.raw()
        with self.assertRaises(GameError):self.call('battle_cheer_upgrade',hero=5034)
        self.assertEqual(before,self.raw())
