import copy
import tempfile
import unittest
from pathlib import Path

from game_config import load_config
from local_game.assets import catalog
from local_game.power import received_power, inspected_lineup_power
from local_game.service import Game


class OriginalPowerTests(unittest.TestCase):
    def test_protocol_zero_missing_and_invalid(self):
        self.assertIsNone(received_power({}))
        self.assertEqual(received_power({'combat_power': 0}), 0)
        self.assertEqual(received_power({'role_combat_power': 4294967295}, 'role_combat_power'), 4294967295)
        for bad in (-1, 4294967296, True, 1.5, '100'):
            with self.assertRaises(ValueError):
                received_power({'combat_power': bad})

    def test_other_player_list_sum_is_not_homepage_power(self):
        # Original checkLineupUI sums every received entry, not just four front slots.
        records = [{'combat_power': 10 * i} for i in range(1, 9)] + [{}]
        self.assertEqual(inspected_lineup_power(records), 360)
        self.assertEqual(inspected_lineup_power([]), 0)
        self.assertEqual(received_power({'role_combat_power': 987}, 'role_combat_power'), 987)

    def test_local_view_never_fabricates_or_reuses_server_power(self):
        with tempfile.TemporaryDirectory() as directory:
            game = Game(Path(directory)/'save.sqlite3', catalog(load_config()['game_root']))
            state = game.initial()
            state['role_combat_power'] = 999999
            before = copy.deepcopy(state)
            view = game.view(state)
            self.assertNotIn('role_combat_power', view)
            self.assertEqual(view['power']['status'], 'unavailable')
            self.assertEqual(view['power']['lineup_ids'], state['lineup'])
            for hero in view['heroes']:
                self.assertNotIn('combat_power', hero)
                self.assertEqual(hero['combat_power_status'], 'unavailable')
            self.assertEqual(state, before)
            state['heroes'][str(state['lineup'][0])] += 1
            upgraded = game.view(state)
            self.assertNotEqual(view['power']['heroes'], upgraded['power']['heroes'])
            self.assertEqual(upgraded['power']['status'], 'unavailable')
