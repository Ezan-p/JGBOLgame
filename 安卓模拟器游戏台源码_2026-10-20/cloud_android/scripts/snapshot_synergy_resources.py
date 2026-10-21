"""Snapshot only synergy UI/config from the installed original channel, read-only."""
import hashlib,json,subprocess,sys
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parents[1]))
from game_config import ROOT,load_config
from local_game.assets import decode_index
c=load_config();adb=[str(c['adb_path']),'-s',c['serial']];remote='/data/data/com.sygame.jingubang.lenovo/release_w/'
raw=subprocess.check_output(adb+['exec-out','cat',remote+'index.txt']);header,index=decode_index(raw)
_,base=decode_index((c['game_root']/'assets/release_/index.txt').read_bytes())
available=set(subprocess.check_output(adb+['shell','ls',remote]).decode().split())
out=ROOT/'local_game/synergy_resources';out.mkdir(exist_ok=True);entries={};missing=[]
for name,(filename,size) in index.items():
 if not (name.startswith('v2/cheerUI/') or name in ['lua/ui/cheerSquadUI.lua','lua/ui/charPositionUI.lua','lua/common/common_def.lua','lua/common/hz.lua','csv_config/cortege_cheer_config.csv','csv_config/fate_config.csv']):continue
 if base.get(name)==(filename,size):continue
 if filename not in available:missing.append(name);continue
 content=subprocess.check_output(adb+['exec-out','cat',remote+filename]);(out/filename).write_bytes(content)
 entries[name]=dict(filename=filename,size=len(content),index_size=size,sha256=hashlib.sha256(content).hexdigest())
(out/'manifest.json').write_text(json.dumps(dict(version=header.decode(),source='installed original-channel release_w, read only',index_sha256=hashlib.sha256(raw).hexdigest(),entries=entries,unavailable=missing),ensure_ascii=False,indent=2))
print('Synergy snapshot:',len(entries),'available;',len(missing),'unavailable')
