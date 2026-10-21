"""Snapshot character evidence from the installed channel client's update cache.

Read-only on Android. Store only resource data, never accounts or save files.
Unchanged resources continue to resolve from the original unpacked APK.
"""
import hashlib
import io
import json
import subprocess
import sys
import tarfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from game_config import ROOT, load_config
from local_game.assets import decode_index


def main():
    config = load_config()
    adb = [str(config["adb_path"]), "-s", config["serial"]]
    remote = "/data/data/com.sygame.jingubang.lenovo/release_w"
    data = subprocess.check_output(adb + ["exec-out", "cat", remote + "/index.txt"])
    header, updated = decode_index(data)
    directory = config["game_root"] / "assets/release_"
    _, original = decode_index((directory / "index.txt").read_bytes())
    selected = {
        name: value for name, value in updated.items()
        if (name.startswith("csv_config/") or name.startswith("chars/")
            or name in ("items/all_items2.png", "skill/skill_icons.png")
            or name in ("lua/common/common_def.lua", "lua/ui/handbookUI.lua",
                        "lua/ui/lineupUI.lua"))
        and original.get(name) != value
    }
    available = set(subprocess.check_output(adb + ["shell", "ls", remote]).decode().split())
    missing = [name for name, (filename, _) in selected.items() if filename not in available]
    if any(not name.startswith("chars/") for name in missing):
        raise RuntimeError("Update cache is incomplete: " + repr(missing))
    selected = {name: value for name, value in selected.items() if name not in missing}
    filenames = sorted({value[0] for value in selected.values()})
    raw = subprocess.check_output(adb + ["exec-out", "tar", "-cf", "-", "-C", remote, *filenames])
    output = ROOT / "local_game/character_resources"
    output.mkdir(parents=True, exist_ok=True)
    with tarfile.open(fileobj=io.BytesIO(raw)) as archive:
        for member in archive:
            if member.name not in filenames or not member.isfile():
                raise ValueError("Unexpected archive member")
            (output / member.name).write_bytes(archive.extractfile(member).read())
    entries = {}
    for name, (filename, size) in sorted(selected.items()):
        content = (output / filename).read_bytes()
        if len(content) != size and name.startswith("csv_config/"):
            raise ValueError("Resource size mismatch: " + name)
        entries[name] = dict(filename=filename, size=len(content), index_size=size,
                             sha256=hashlib.sha256(content).hexdigest())
    manifest = dict(version=header.decode(), source="installed channel release_w",
                    index_sha256=hashlib.sha256(data).hexdigest(), entries=entries,
                    unavailable=missing)
    (output / "manifest.json").write_text(json.dumps(manifest, ensure_ascii=False, indent=2))
    print(f"Saved {len(entries)} updated resources ({sum(r['size'] for r in entries.values())} bytes)")


if __name__ == "__main__":
    main()
