"""Export reproducible original-client power evidence, without touching saves."""
import hashlib
import json
from pathlib import Path
import re
import subprocess
import sys
import tempfile

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))
from game_config import load_config
from local_game.assets import Resources


def main():
    resources = Resources(load_config()['game_root'])
    output = ROOT / 'outputs/power-20261023'
    output.mkdir(parents=True, exist_ok=True)
    sources, evidence = [], {}
    names = ['common/common_def', 'common/msg_def', 'ui/mainUI', 'ui/charPositionUI',
             'ui/checkLineupUI', 'ui/playerInfoUI', 'ui/lineupUI', 'ui/fightrecordUI', 'event_mgr', 'ui/runeUI', 'ui/landUI']
    pattern = re.compile(r'combat_power|sumCombat|g_oldCombat|function showCombat|function showCortegeCombat|function getNumList|function updateCharacter|function update.*Property')
    with tempfile.TemporaryDirectory() as directory:
        for name in names:
            resource = 'lua/' + name + '.lua'
            bytecode = Path(directory) / 'input.luac'
            decompiled = Path(directory) / 'output.lua'
            bytecode.write_bytes(resources.read(resource))
            result = subprocess.run([sys.executable, '-c',
                            'import sys,runpy;sys.setrecursionlimit(30000);'
                            'p=sys.argv.pop(1);sys.path.insert(0,str(__import__("pathlib").Path(p).parent));'
                            'runpy.run_path(p,run_name="__main__")',
                            str(ROOT / '.runtime/research/ljd/main.py'),
                            '-f', str(bytecode), '-o', str(decompiled)], check=False,
                           stdout=subprocess.DEVNULL, stderr=subprocess.PIPE)
            source = resources.source(resource)
            if result.returncode:
                source['decompile_error'] = result.stderr.decode(errors='replace').splitlines()[-1]
                sources.append(source)
                evidence[resource] = {'error': source['decompile_error']}
                continue
            source['decompiled_sha256'] = hashlib.sha256(decompiled.read_bytes()).hexdigest()
            sources.append(source)
            lines = decompiled.read_text().splitlines()
            selected = set()
            for i, line in enumerate(lines):
                if pattern.search(line):
                    selected.update(range(max(0, i-4), min(len(lines), i+16)))
            evidence[resource] = [{'line': i+1, 'text': lines[i]} for i in sorted(selected)]
    # Search the resolved original/update resources, not just old decompiler output.
    matches = []
    counts = {'lua': 0, 'csv': 0}
    for name in resources.names():
        kind = 'lua' if name.endswith('.lua') else 'csv' if name.endswith('.csv') else None
        if kind is None:
            continue
        counts[kind] += 1
        raw = resources.read(name)
        terms = [term for term in ('combat_power', 'fight_power', 'fightpower') if term.encode() in raw]
        if terms:
            matches.append({'resource': name, 'terms': terms})
    (output / 'sources.json').write_text(json.dumps(sources, ensure_ascii=False, indent=2)+'\n')
    (output / 'evidence.json').write_text(json.dumps(evidence, ensure_ascii=False, indent=2)+'\n')
    (output / 'scan.json').write_text(json.dumps({'counts': counts, 'matches': matches}, ensure_ascii=False, indent=2)+'\n')
    print(json.dumps(counts))


if __name__ == '__main__':
    main()
