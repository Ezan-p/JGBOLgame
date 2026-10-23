"""Export original essence evidence without changing APK resources or saves."""
import hashlib
import json
import sys
import subprocess
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from game_config import ROOT, load_config
from local_game.assets import Resources
from local_game.essence import build_rules


def main():
    r = Resources(load_config()['game_root'])
    out = ROOT / 'outputs/essence-20261023'
    out.mkdir(parents=True, exist_ok=True)
    paths = ['csv_config/' + x + '.csv' for x in (
        'ext_skill', 'ext_skill_lock_cost', 'jingpo_transform', 'material_transform',
        'hunt_ball_config', 'hunt_soul_config', 'hunt_day_prize', 'hunt_week_prize',
        'item_base', 'item_name', 'skill_ext_base', 'skill_ext_name')]
    paths += ['lua/ui/' + x + '.lua' for x in ('jpUI', 'jpmkUI', 'lineupUI', 'smithUI', 'packageUI', 'formationUI')]
    paths += ['lua/common/msg_def.lua', 'lua/skill/skillExt.lua', 'v2/String.plist']
    manifest=[]
    for path in paths:
        target=path.replace('/', '_')
        (out / target).write_bytes(r.read(path))
        manifest.append({**r.source(path), 'export': target})
        if path.endswith('.lua'):
            name=target.replace('.lua', '.decompiled.lua')
            result=subprocess.run([sys.executable, '-c',
                'import sys,runpy;sys.setrecursionlimit(10000);p=sys.argv.pop(1);sys.path.insert(0,str(__import__("pathlib").Path(p).parent));runpy.run_path(p,run_name="__main__")',
                str(ROOT / '.runtime/research/ljd/main.py'), '-f', str(out/target), '-o', str(out/name)],
                capture_output=True)
            if result.returncode == 0 and (out/name).exists():
                manifest.append(dict(resource=path, export=name, sha256=hashlib.sha256((out/name).read_bytes()).hexdigest(),
                    provenance='Decompiled from resolved original bytes exported alongside'))
            else:
                manifest.append(dict(resource=path, decompile_error=result.stderr.decode(errors='replace')[-500:]))
    rules=build_rules(r)
    (out/'evidence.json').write_text(json.dumps(dict(sources=manifest, rules=rules), ensure_ascii=False, indent=2)+'\n')
    names={int(x['Ftype_id']): x['name'] for x in r.rows('csv_config/item_name.csv')}
    lines=['# 原版精魄逐级说明', '', '| ID | 名称 | 等级 | 原始说明 |', '|---|---|---|---|']
    for row in r.rows('csv_config/ext_skill.csv'):
        for level in range(5):
            desc=row['introduction']
            for group in row['parameter'].split('/'):
                desc=desc.replace('%s',group.split('|')[level],1)
            lines.append(f"| {row['id']} | {names[int(row['id'])]} | {level+1} | {desc} |")
    (out/'精魄逐级参数.md').write_text('\n'.join(lines)+'\n')
    print(f'Exported {len(manifest)} evidence records and 190 descriptions: {out}')

if __name__ == '__main__': main()
