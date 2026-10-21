"""Build a separate local APK from original assets; no edits to the channel APK."""
import hashlib
import json
import os
import secrets
import subprocess
import sys
import zipfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from game_config import ROOT, RUNTIME, SDK, load_config
from local_game.assets import Resources, catalog, decode_index, encode_index
from local_game.manifest import build_manifest, PACKAGE, ACTIVITY
from local_game.dex_patch import patch_dex
from local_game.handbook import build_handbook
from local_game.battle import build_battle
from local_game.battle_research import build_research
from local_game.lineup import build_lineup
from local_game.inventory import build_inventory
from local_game.synergy import build_synergy
from local_game.journey import build_journey, lua_literal
from scripts.prepare_apk import ROOTS, java_home, validate_source


def main():
    game = load_config()["game_root"]
    validate_source(game)
    output = RUNTIME / "local_game"
    output.mkdir(parents=True, exist_ok=True)
    output.chmod(0o700)
    keyfile = output / "client-key"
    if not keyfile.exists():
        keyfile.write_text(secrets.token_hex(32))
        keyfile.chmod(0o600)
    key = keyfile.read_text().strip()
    assets = catalog(game)
    inventory = build_inventory(game)
    assets["inventory"] = inventory
    synergy = build_synergy(game)
    assets["synergy"] = synergy
    (output / "synergy.json").write_text(json.dumps(synergy, ensure_ascii=False, indent=2))
    (output / "inventory.json").write_text(json.dumps(inventory, ensure_ascii=False, indent=2))
    (output / "catalog.json").write_text(json.dumps(assets, ensure_ascii=False, indent=2))
    header, entries = decode_index((game / "assets/release_/index.txt").read_bytes())
    script = (ROOT / "local_game/client.lua").read_text().replace("__LOCAL_KEY__", key).encode()
    filename = hashlib.md5(script).hexdigest() + ".data"
    entries["lua/mg_update.lua"] = (filename, len(script))
    handbook = build_handbook(game)
    journey = build_journey(game)
    battle = build_battle(game)
    (output / "battle-mechanics.json").write_text(json.dumps(build_research(game), ensure_ascii=False, indent=2))
    lineup = build_lineup(game)
    (output / "lineup.json").write_text(json.dumps(lineup, ensure_ascii=False, indent=2))
    (output / "battle.json").write_text(json.dumps(battle, ensure_ascii=False, indent=2))
    (output / "journey.json").write_text(json.dumps(journey, ensure_ascii=False, indent=2))
    extra = {
        "lua/local_battle_hall.lua": (ROOT / "local_game/battle_hall.lua").read_bytes(),
        "lua/local_combat_rules.lua": ("return " + lua_literal(assets["combat_rules"])).encode(),
        "lua/local_inventory.lua": (ROOT / "local_game/inventory.lua").read_bytes(),
        "lua/local_inventory_data.lua": ("return " + lua_literal({"items": inventory["items"]})).encode(),
        "lua/local_lineup.lua": (ROOT / "local_game/lineup.lua").read_bytes(),
        "lua/local_lineup_data.lua": ("return " + lua_literal({k: v for k, v in lineup.items()
            if k not in ("resources", "sources")})).encode(),
        "lua/local_battle.lua": (ROOT / "local_game/battle.lua").read_bytes(),
        "lua/local_battle_data.lua": ("return " + lua_literal({k: v for k, v in battle.items()
            if k not in ("resources", "sources")})).encode(),
        "lua/local_home.lua": (ROOT / "local_game/home.lua").read_bytes(),
        "lua/local_handbook.lua": (ROOT / "local_game/handbook.lua").read_bytes(),
        "lua/local_journey.lua": (ROOT / "local_game/journey.lua").read_bytes(),
        "lua/local_journey_data.lua": (
            "return " + lua_literal({k: v for k, v in journey.items()
                                     if k not in ("resources", "sources")})
        ).encode(),
        "lua/local_handbook_data.lua": (
            "return require('base.json').decode([==["
            + json.dumps(handbook, ensure_ascii=False, separators=(",", ":"))
            + "]==])"
        ).encode(),
    }
    resources = Resources(game)
    all_units=list(assets["heroes"].values())+[u for mode in assets["battle_modes"].values() for team in mode.values() for u in team]
    for hero in all_units:
        if hero["sprite"] in resources.updated:
            extra[hero["sprite"]] = resources.read(hero["sprite"])
    for name in set(handbook["resources"]) | set(journey["resources"]) | set(battle["resources"]) | set(lineup["resources"]) | set(inventory["resources"]) | set(synergy["resources"]):
        # Validate original dependencies too; only updated art needs an APK overlay.
        content = resources.read(name)
        if name in resources.updated:
            extra[name] = content
    for resource in sorted((ROOT / "local_game/resources").rglob("*.png")):
        extra[resource.relative_to(ROOT / "local_game/resources").as_posix()] = resource.read_bytes()
    resource_patches = {}
    for name, data in extra.items():
        hashed = hashlib.md5(data).hexdigest() + ".data"
        entries[name] = (hashed, len(data))
        resource_patches["assets/release_/" + hashed] = data
    index = encode_index(header, entries)
    patches = {
        "AndroidManifest.xml": build_manifest(),
        "classes.dex": patch_dex((game / "classes.dex").read_bytes()),
        "assets/release_/index.txt": index,
        "assets/release_/index_1061.txt": index,
        "assets/release_/" + filename: script,
        **resource_patches,
    }
    # Android MediaPlayer/SoundPool open APK assets via file descriptors; compressed
    # hashed .data entries cannot be opened that way even when the logical name is MP3.
    audio_entries = {'assets/release_/' + entry[0] for name, entry in entries.items()
                     if name.lower().endswith(('.mp3', '.wav', '.ogg'))}
    def compression(name):
        return zipfile.ZIP_STORED if name in audio_entries else zipfile.ZIP_DEFLATED
    unsigned = output / "local-unsigned.apk"
    with zipfile.ZipFile(unsigned, "w", compression=zipfile.ZIP_DEFLATED, allowZip64=False) as archive:
        for root in ROOTS:
            source = game / root
            files = [source] if source.is_file() else sorted(source.rglob("*"))
            for path in files:
                if not path.is_file() or path.name == ".DS_Store":
                    continue
                if path.is_symlink():
                    raise ValueError("Game sources must not contain symlinks")
                name = path.relative_to(game).as_posix()
                if name in patches:
                    archive.writestr(name, patches.pop(name), compress_type=compression(name))
                else:
                    archive.write(path, name, compress_type=compression(name))
        for name, value in patches.items():
            archive.writestr(name, value, compress_type=compression(name))
    java = java_home() / "bin/java"
    bt = SDK / "build-tools/35.0.0"
    aligned = output / "local-aligned.apk"
    apk = output / "jingubang-local.apk"
    subprocess.run([str(bt / "zipalign"), "-f", "-p", "4", str(unsigned), str(aligned)], check=True)
    subprocess.run([str(java), "-jar", str(bt / "lib/apksigner.jar"), "sign",
                    "--ks", str(RUNTIME / "apk/local-test.p12"), "--ks-pass", "pass:android",
                    "--key-pass", "pass:android", "--v1-signing-enabled", "true",
                    "--v2-signing-enabled", "true", "--out", str(apk), str(aligned)], check=True)
    subprocess.run([str(java), "-jar", str(bt / "lib/apksigner.jar"), "verify", "--verbose", str(apk)], check=True)
    receipt = {
        "package": PACKAGE, "activity": ACTIVITY, "apk": str(apk),
        "sha256": hashlib.sha256(apk.read_bytes()).hexdigest(),
        "rules": "local-v4", "original_game_modified": False,
        "features": ["38-live-traits", "75-awakening-stars", "native-awakening-and-spell-advance", "rulai-shield-and-sharing", "elite-arena-guild-story-modes", "uncompressed-native-audio", "original-inventory-ui", "inventory-equip-upgrade-socket-compose-use-smelt", "original-lineup-ui", "formation-drag-and-replace", "lineup-equipment-picker", "original-eight-trigram-support-ui", "support-upgrade-and-stat-transfer", "character-equipment-spell-fates", "original-battle-art-and-ccbi", "eight-slot-paired-reinforcements", "native-and-equipped-spell-procs", "original-home-ui", "original-handbook-ui", "original-journey-ui", "local-save", "roster", "upgrade", "all-heroes-recruit", "10-stage-pve"],
        "journey_counts": {"chapters": len(journey["chapters"]),
                           "stages": sum(len(c["stages"]) for c in journey["chapters"]),
                           "map_positions": sum("x" in c for c in journey["chapters"])},
        "recruitable_count": len(assets["recruitable"]),
        "handbook_counts": {k: len(v) for k, v in handbook.items() if k != "resources"},
    }
    (output / "build.json").write_text(json.dumps(receipt, ensure_ascii=False, indent=2))
    print("本地 APK：", apk)
    print("原版渠道客户端和源资源未修改。")


if __name__ == "__main__":
    main()
