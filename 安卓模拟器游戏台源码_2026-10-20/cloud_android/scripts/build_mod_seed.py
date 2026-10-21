"""Build a browser fixture from extracted original configs; never modify APK assets."""
import hashlib, json, shutil
from pathlib import Path
R = Path(__file__).resolve().parents[2]
S = R / 'mod_analysis'
D = R / 'cloud_android/web/mod'
def read(p): return json.loads(p.read_text())
c = read(S/'extracted/SettingJson__character_settings.json')['character_setting']
s = read(S/'extracted/SettingJson__skill_settings.json')['skill_setting']
files = ['character_config.json', 'skills.json', 'asset_relations.json', 'gacha_relations.json']
source = {n: read(S/'character_1001'/n) for n in files}
seed = dict(character=source[files[0]], skills=source[files[1]], assets=source[files[2]], gachaEvidence=source[files[3]], existingCharacterIds=list(c['pet_basic_info']), existingSkillIds=list(s['skill_base_info']), provenance={n: hashlib.sha256((S/'character_1001'/n).read_bytes()).hexdigest() for n in files})
D.mkdir(exist_ok=True)
(D/'seed.json').write_text(json.dumps(seed, ensure_ascii=False, separators=(',', ':')))
shutil.copyfile(S/'character_1001/icon.png', D/'icon.png')
print('Built browser seed from character 1001')
