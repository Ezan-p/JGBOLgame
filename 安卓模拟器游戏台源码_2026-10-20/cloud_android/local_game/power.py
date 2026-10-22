"""Original client power semantics; the original server formula is unavailable.

Never infer combat_power from local stats. A received record is authoritative
only for the snapshot it describes, not for a subsequently modified local hero.
See outputs/power-20261023/evidence.json and 逆向结果/战力机制.md.
"""


def received_power(record, field='combat_power'):
    """Read a protocol I value, preserving zero and rejecting malformed data."""
    value = record.get(field)
    if value is None:
        return None
    if type(value) is not int or not 0 <= value <= 0xffffffff:
        raise ValueError('Invalid original power field: ' + field)
    return value


def inspected_lineup_power(cortege_list):
    """checkLineupUI.sortCharacters: sum received list, missing field => zero.

    This is the inspected-player screen rule, NOT a proven homepage formula.
    cheer_cortege is a separate list and must not be passed here.
    """
    return sum(received_power(hero) or 0 for hero in cortege_list)


def local_view(heroes, lineup):
    """Describe the local snapshot without fabricating server-owned values."""
    return {
        'status': 'unavailable',
        'reason': 'original_server_formula_missing',
        'source': 'original_server',
        'lineup_ids': list(lineup),
        'heroes': [
            {'id': hero['id'], 'status': 'unavailable',
             'stats': {key: hero.get(key, 0) for key in ('hp', 'attack', 'defense', 'magic')}}
            for hero in heroes
        ],
    }
