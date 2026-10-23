"""Export exact original role values and traceable client evidence."""
import hashlib
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from game_config import ROOT, load_config
from local_game.assets import Resources
from local_game.role_progression import read_levels


def main():
    resources = Resources(load_config()['game_root'])
    output = ROOT / 'outputs/role-progression-20261023'
    output.mkdir(parents=True, exist_ok=True)
    paths = ['csv_config/role_level_config.csv', 'lua/ui/mainUI.lua',
             'lua/ui/playerInfoUI.lua', 'lua/ui/fightUI.lua', 'lua/ui/saodangUI.lua',
             'lua/ui/snowmanUI.lua', 'lua/ui/levelUpBuffUI.lua', 'lua/common/msg_def.lua',
             'v2/String2.plist']
    sources = []
    for path in paths:
        data = resources.read(path)
        name = path.replace('/', '_')
        (output / name).write_bytes(data)
        sources.append({**resources.source(path), 'export': name})
    levels = read_levels(resources)
    data = dict(levels=levels, sources=sources, settlement='Original table values; local selection of reward columns; server formula unavailable')
    (output / 'role_progression.json').write_text(json.dumps(data, ensure_ascii=False, indent=2)+'\n')
    cumulative = 0
    lines = ['| 等级 | 升级修为 | 普通胜 | 普通负 | 神仙经验字段 | 阵位 | 精力胜 | 精力负 | 到达本级累计修为 |',
             '|---:|---:|---:|---:|---:|---:|---:|---:|---:|']
    for row in levels.values():
        lines.append('| '+' | '.join(str(row[k]) for k in ['level','upgrade_exp','win_exp','lose_exp','cortege_exp','cortege_count','energy_win_exp','energy_lose_exp'])+f' | {cumulative} |')
        cumulative += row['upgrade_exp']
    (output / '原版逐级数值.md').write_text('# 主角修为逐级原值\n\n前八列为原表整数，最后一列为前置等级门槛之和。99 级的门槛仍保留，不据此虚构 100 级配置。\n\n'+'\n'.join(lines)+'\n')
    print(f'Exported {len(levels)} levels and {len(sources)} source files to {output}')


if __name__ == '__main__':
    main()
