"""Re-export original rank badges, ambient CCBIs and their client call sites."""
import hashlib,json,subprocess,sys
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parents[1]))
from game_config import ROOT,load_config
from local_game.assets import Resources

def main():
 r=Resources(load_config()['game_root']);out=ROOT/'outputs/equip-visuals-20261023';out.mkdir(exist_ok=True)
 names=['lua/data.lua','lua/common/createCell.lua','lua/ui/charPositionUI.lua','lua/ui/packageUI.lua','lua/common/utils.lua']
 names += [f'v2/equipAdvanceUI/ad{i}.png' for i in range(1,11)]
 for effect in ('01','02','03','04'):names += [effect+'.ccbi',f'{effect}/{effect}.plist',f'{effect}/{effect}.png']
 sources=[]
 for name in names:
  target=out/name.replace('/','_');target.write_bytes(r.read(name));record={**r.source(name),'export':target.name}
  if name.endswith('.lua'):
   dest=target.with_suffix('.decompiled.lua')
   cmd=[sys.executable,'-c','import sys,runpy;sys.setrecursionlimit(10000);p=sys.argv.pop(1);sys.path.insert(0,str(__import__("pathlib").Path(p).parent));runpy.run_path(p,run_name="__main__")',str(ROOT/'.runtime/research/ljd/main.py'),'-f',str(target),'-o',str(dest)]
   subprocess.run(cmd,check=True,capture_output=True);record.update(decompiled=dest.name,decompiled_sha256=hashlib.sha256(dest.read_bytes()).hexdigest())
  sources.append(record)
 evidence=dict(sources=sources,rules=dict(ranks=[dict(first=0,last=2,animation=None),dict(first=3,last=5,animation='01.ccbi',anchor=[.5,.56]),dict(first=6,last=8,animation='02.ccbi',anchor=[.5,.45]),dict(first=9,last=9,animation='03.ccbi',anchor=[.5,.56]),dict(first=10,last=10,animation='04.ccbi',anchor=[.5,.56])],corner=dict(anchor=[1,0],position=[.93,.07],badge_pixels=[35,35]),name=dict(anchor=[-.1,.5],position='after measured name width'),effect_scale='icon content width / 120',equipment_level=dict(anchor=[0,.5],position=[.1,.8],font_size=22,color=[255,255,255])),references=['素材图/IMG_3412.JPG','素材图/IMG_3438.JPG'])
 (out/'evidence.json').write_text(json.dumps(evidence,ensure_ascii=False,indent=2)+'\n');print('Exported',len(sources),'original sources.')
if __name__=='__main__':main()
