"""Reproducible original equipment-advance evidence, without touching saves."""
import hashlib
import json
import plistlib
import subprocess
import sys
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parents[1]))
from game_config import ROOT,load_config
from local_game.assets import Resources
from local_game.equip_advance import build_rules


def main():
    r=Resources(load_config()['game_root']);out=ROOT/'outputs/equip-advance-20261023';out.mkdir(exist_ok=True)
    names=['lua/ui/equipAdvanceUI.lua','lua/ui/packageUI.lua','lua/data.lua',
           'lua/common/common_def.lua','lua/common/msg_def.lua','lua/common/utils.lua','lua/ui/stoneUI.lua',
           'csv_config/equip_star_cost.csv','csv_config/equip_advance_cost.csv','csv_config/equip_advance_worth.csv',
           'csv_config/item_name.csv','v2/String.plist','v2/String2.plist']
    names += [n for n in r.names() if n.startswith(('v2/equipAdvanceUI/','shengjie/','shengjie02/'))]
    names += ['shengjie.ccbi','shengjie02.ccbi']
    sources=[]
    for name in names:
        filename=name.replace('/','_');f=out/filename;f.write_bytes(r.read(name))
        record={**r.source(name),'export':filename}
        if name.endswith('.lua'):
            target=f.with_suffix('.decompiled.lua')
            p=subprocess.run([sys.executable,'-c',
                'import sys,runpy;sys.setrecursionlimit(10000);p=sys.argv.pop(1);sys.path.insert(0,str(__import__("pathlib").Path(p).parent));runpy.run_path(p,run_name="__main__")',
                str(ROOT/'.runtime/research/ljd/main.py'),'-f',str(f),'-o',str(target)],capture_output=True)
            if p.returncode: raise RuntimeError(p.stderr.decode())
            record.update(decompiled=target.name,decompiled_sha256=hashlib.sha256(target.read_bytes()).hexdigest())
        sources.append(record)
    strings={}
    for name in ('v2/String.plist','v2/String2.plist'):strings.update(plistlib.loads(r.read(name)))
    text={k:v for k,v in strings.items() if k.startswith('advance') or k in ('choose_equip','jie_hz','numHZ')}
    (out/'evidence.json').write_text(json.dumps(dict(sources=sources,strings=text,rules=build_rules(r),
        unknown=['is_open','min_role_level','max_advance_level','max_star_level','pour_star_count',
                 'server spirit yield and one-key stop policy','extra character-stat settlement']),ensure_ascii=False,indent=2)+'\n')
    print('Exported',len(sources),'sources to',out)
if __name__=='__main__':main()
