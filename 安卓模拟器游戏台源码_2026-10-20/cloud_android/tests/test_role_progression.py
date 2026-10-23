import copy
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

from game_config import load_config
from local_game.assets import Resources, catalog
from local_game import role_progression as role, battle_modes
from local_game.service import Game, GameError


class RoleProgressionTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.resources = Resources(load_config()['game_root'])
        cls.catalog = catalog(load_config()['game_root'])
        cls.levels = cls.catalog['role_levels']

    def test_original_99_rows_and_every_boundary(self):
        rows = self.resources.rows('csv_config/role_level_config.csv')
        self.assertEqual(len(rows), 99)
        total = 0
        for row in rows:
            level, threshold = int(row['level']), int(row['upgrade_exp'])
            self.assertEqual(self.levels[str(level)], {k:int(v) for k,v in row.items()})
            self.assertEqual(role.info(dict(role_exp_schema=1, experience=total), self.levels), (level,0,threshold))
            self.assertEqual(role.info(dict(role_exp_schema=1, experience=total+threshold-1), self.levels), (level,threshold-1,threshold))
            for resource, prefix in [('strength',''), ('energy','energy_')]:
                for won, suffix in [(True,'win_exp'), (False,'lose_exp')]:
                    state = dict(role_exp_schema=1, experience=total)
                    self.assertEqual(role.award_battle(state,self.levels,won,resource=resource),int(row[prefix+suffix]))
                    self.assertEqual(state['experience'], total+int(row[prefix+suffix]))
            total += threshold
        self.assertEqual(total-int(rows[-1]['upgrade_exp']), 226271000)
        self.assertEqual(role.info(dict(role_exp_schema=1,experience=total+1),self.levels), (99,22453201,22453200))

    def test_crossing_uses_level_before_reward_and_preserves_remainder(self):
        state = dict(role_exp_schema=1, experience=39)
        self.assertEqual(role.award_battle(state,self.levels,True),5)
        self.assertEqual(role.info(state,self.levels),(2,4,110))
        self.assertEqual(role.info(dict(role_exp_schema=1,experience=271),self.levels),(4,1,270))

    def test_legacy_conversion_is_idempotent(self):
        for old in [0,199,200,1850,999999]:
            state = dict(experience=old)
            role.migrate(state,self.levels)
            level,cur,threshold = role.info(state,self.levels)
            self.assertEqual(level,min(99,1+old//200))
            self.assertEqual(cur,(old%200)*threshold//200)
            snapshot = copy.deepcopy(state)
            role.migrate(state,self.levels)
            self.assertEqual(state,snapshot)

    def test_every_local_mode_uses_table_for_victory_and_defeat(self):
        with tempfile.TemporaryDirectory() as tmp:
            game = Game(Path(tmp)/'save.db',self.catalog)
            for mode in ['elite','arena','guild','story']:
                for won,expected in [(True,5),(False,2)]:
                    state = game.initial()
                    role.migrate(state,self.levels)
                    with patch('local_game.combat.resolve', return_value=dict(won=won,total_damage=[100,100])):
                        result = battle_modes.fight(game,state,mode,GameError)
                    self.assertEqual(result['experience'],expected)
                    self.assertEqual(state['experience'],expected)
                    self.assertEqual(state['hero_exp'],{})
