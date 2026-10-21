"""Read only original-channel inventory art and bytecode from this emulator."""
import hashlib
import json
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from game_config import ROOT, load_config
from local_game.assets import decode_index


def main():
    config = load_config()
    adb = [str(config["adb_path"]), "-s", config["serial"]]
    remote = "/data/data/com.sygame.jingubang.lenovo/release_w/"
    raw = subprocess.check_output(adb + ["exec-out", "cat", remote + "index.txt"])
    header, index = decode_index(raw)
    _, original = decode_index((config["game_root"] / "assets/release_/index.txt").read_bytes())
    available = set(subprocess.check_output(adb + ["shell", "ls", remote]).decode().split())
    out = ROOT / "local_game/inventory_resources"
    out.mkdir(exist_ok=True)
    previous = json.loads((out/"manifest.json").read_text())["entries"] if (out/"manifest.json").exists() else {}
    entries, missing = {}, []
    for name, (filename, size) in index.items():
        if not (name.startswith(("items/", "v2/packageUI/", "v2/stoneUI/", "v2/smithUI/",
                                 "v2/wakeUI/icon/"))
                or name in ("lua/ui/packageUI.lua", "lua/ui/stoneUI.lua", "lua/data.lua",
                            "lua/ui/wakeUI.lua", "lua/ui/destinyUI.lua", "v2/summerUI/cbkg3.png",
                            "v2/destinyUI/card.png")):
            continue
        if original.get(name) == (filename, size):
            continue
        if filename not in available:
            missing.append(name)
            continue
        content = subprocess.check_output(adb + ["exec-out", "cat", remote + filename])
        (out / filename).write_bytes(content)
        entries[name] = dict(filename=filename, size=len(content), index_size=size,
                             sha256=hashlib.sha256(content).hexdigest())
    (out / "manifest.json").write_text(json.dumps(dict(version=header.decode(),
        source="installed channel release_w (read only)",
        index_sha256=hashlib.sha256(raw).hexdigest(), entries=entries, unavailable=missing),
        ensure_ascii=False, indent=2))
    retained = {x["filename"] for x in entries.values()}
    for old in previous.values():
        if old["filename"] not in retained:
            (out/old["filename"]).unlink(missing_ok=True)
    print(f"Inventory snapshot: {len(entries)} resources, {len(missing)} unavailable")


if __name__ == "__main__":
    main()
