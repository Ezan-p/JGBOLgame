import copy
import csv
import io
import json
import tempfile
import unittest
from pathlib import Path
from concurrent.futures import ThreadPoolExecutor
from game_config import load_config
from local_game.assets import Resources, catalog
from local_game.inventory import grant
from local_game.service import Game, GameError


class AdvanceTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.catalog=catalog(load_config()['game_root'])
        cls.inv=cls.catalog['inventory']

    def setUp(self):
        self.tmp=tempfile.TemporaryDirectory();self.addCleanup(self.tmp.cleanup)
        self.game=Game(Path(self.tmp.name)/'save.sqlite3', self.catalog)
        self.game.request('advance-test','advance-login','login',{})
        self.n=0

    def raw(self):
        with self.game.connect() as con:return json.loads(con.execute('SELECT state FROM players WHERE id=?',('advance-test',)).fetchone()[0])

    def save(self,state):
        with self.game.connect() as con:con.execute('UPDATE players SET state=? WHERE id=?',(json.dumps(state),'advance-test'))

    def call(self,op,**args):
        self.n+=1;return self.game.request('advance-test',f'request-{self.n:05}',op,args)

    def fixture(self,kind=1,quality=5,materials=210,rank=0,stars=0):
        state=self.raw()
        item=next(x for x in self.inv['items'].values() if x['category']==kind and x['quality']==quality)
        grant(state,item['key'],catalog=self.inv)
        e=state['inventory']['entries'][-1];e.update(advance_level=rank,star_count=stars,cur_spirit_count=0)
        if materials:grant(state,'i'+str(1309+kind),materials,catalog=self.inv)
        self.save(state);return e['uid']

    def test_all_486_worth_states_and_420_star_costs(self):
        r=Resources(load_config()['game_root'])
        rows=list(csv.reader(io.StringIO(r.read('csv_config/equip_advance_worth.csv').decode('utf-8-sig'))))
        values=self.inv['equip_advance']['worth']
        self.assertEqual(sum(len(x) for x in values.values()),486)
        for row in rows[1:]:
            for index,cell in enumerate(row[2:],1):
                fields=cell.split('|');v=values[f'{row[1]}:{row[0]}'][f'{index//8}:{index%8}']
                self.assertEqual((v['percent'],v['plus']), (float(fields[0]),int(fields[1])))
        self.assertEqual(len(self.inv['equip_advance']['stars']),420)
        for quality in (4,5):
            for kind in (1,2,3):
                for rank,amount in enumerate((30,30,55,55,55,115,115,115,170,260),1):
                    for star in range(1,8):self.assertEqual(self.inv['equip_advance']['stars'][f'{quality}:{kind}:{rank}:{star}'],amount)

    def test_single_pour_and_concurrent_idempotency(self):
        uid=self.fixture(materials=35);before=self.raw()
        with ThreadPoolExecutor(4) as p:
            result=list(p.map(lambda _: self.game.request('advance-test','same-request','bag_equip_pour',{'uid':uid}),range(4)))
        self.assertTrue(all(x==result[0] for x in result));state=self.raw();e=state['inventory']['entries'][0]
        self.assertEqual(e['cur_spirit_count'],5);self.assertEqual(state['silver'],before['silver'])
        self.call('bag_equip_pour',uid=uid,one_key=True);e=self.raw()['inventory']['entries'][0]
        self.assertEqual((e['star_count'],e['cur_spirit_count']),(1,5))
        self.assertEqual(Game(self.game.db,self.catalog).view(self.raw())['inventory']['entries'][0]['advance']['spirit'],5)

    def test_full_tier_and_advance_preserve_equipment_and_stones(self):
        uid=self.fixture();state=self.raw();e=state['inventory']['entries'][0]
        e.update(hero=5022,drill=1,level=8)
        from local_game.inventory import new_stone_entry
        stone=copy.deepcopy(new_stone_entry(state['inventory'],'i1090',4,23,uid,1))
        for key,count in [('i1313',8),('i1320',10)]:grant(state,key,count,catalog=self.inv)
        self.save(state);self.call('bag_equip_pour',uid=uid,one_key=True)
        self.assertTrue(self.game.view(self.raw())['inventory']['entries'][0]['advance']['ready'])
        with self.assertRaises(GameError):self.call('bag_equip_pour',uid=uid)
        self.call('bag_equip_advance',uid=uid);after=self.raw();e=after['inventory']['entries'][0]
        self.assertEqual((e['advance_level'],e['star_count'],e['cur_spirit_count']),(1,0,0))
        self.assertEqual((e['hero'],e['level'],e['drill']),(5022,8,1))
        self.assertIn(stone,after['inventory']['entries']);self.assertEqual(after['silver'],state['silver'])
        shown=self.game.view(after)['inventory']['entries'][0]
        self.assertEqual(shown['advance_bonus'],int(shown['base_value']*.04+42))
        clean=copy.deepcopy(after);clean['inventory']['entries'][0].update(advance_level=0,star_count=0)
        h1=next(h for h in self.game.view(after)['heroes'] if h['id']==5022)
        h0=next(h for h in self.game.view(clean)['heroes'] if h['id']==5022)
        self.assertGreater(h1['attack'],h0['attack'])

    def test_invalid_or_missing_materials_leave_state_unchanged(self):
        uid=self.fixture(materials=4)
        for op,args in [('bag_equip_pour',{'uid':uid}),('bag_equip_advance',{'uid':uid}),
                        ('bag_equip_pour',{'uid':True}),('bag_equip_pour',{'uid':uid,'one_key':'true'})]:
            before=self.raw()
            with self.assertRaises(GameError):self.call(op,**args)
            self.assertEqual(self.raw(),before)
        state=self.raw();state['inventory']['entries'][0]['star_count']=7
        grant(state,'i1313',8,catalog=self.inv);self.save(state);before=self.raw()
        with self.assertRaisesRegex(GameError,'近古水晶'):self.call('bag_equip_advance',uid=uid)
        self.assertEqual(self.raw(),before)

    def test_max_rank_and_quality_restriction(self):
        uid=self.fixture(rank=10,materials=20);before=self.raw()
        for op in ('bag_equip_pour','bag_equip_advance'):
            with self.assertRaisesRegex(GameError,'最高阶'):self.call(op,uid=uid)
        self.assertEqual(self.raw(),before)
        uid=self.fixture(quality=3)
        with self.assertRaisesRegex(GameError,'四星'):self.call('bag_equip_pour',uid=uid)

    def test_all_ten_ranks_all_types_and_qualities(self):
        for quality in (4,5):
            for kind in (1,2,3):
                uid=self.fixture(kind,quality,materials=10000)
                for rank in range(1,11):
                    self.call('bag_equip_pour',uid=uid,one_key=True)
                    state=self.raw()
                    costs=self.inv['equip_advance']['costs'][f'{quality}:{kind}:{rank}']
                    for c in costs:grant(state,c['key'],c['count'],catalog=self.inv)
                    self.save(state);self.call('bag_equip_advance',uid=uid)
                    e=next(e for e in self.raw()['inventory']['entries'] if e['uid']==uid)
                    self.assertEqual((e['advance_level'],e['star_count']),(rank,0))
