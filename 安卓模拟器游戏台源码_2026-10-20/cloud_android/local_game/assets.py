"""Read/write the game's resource index. Original files are never changed."""
import base64
import csv
import hashlib
import io
import json
from pathlib import Path

from PIL import Image

ALPHABET = b"yfgl mnovwxapzdechijkqrstbuHOMICDJPQRSTUVWXYZABKEFGLN39+0126-4785".replace(b" ", b"")
STANDARD = b"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"


def decode_index(data):
    header, body = data.split(b"\n", 1)
    raw = base64.b64decode(body.strip().translate(bytes.maketrans(ALPHABET + b"_", STANDARD + b"=")),
                          validate=True)
    try:
        text = raw.decode("utf-8")
    except UnicodeDecodeError:
        text = raw.decode("gb18030")
    entries = {}
    for line in text.splitlines():
        name, filename, size = line.split("====")
        if name.startswith("/") or ".." in Path(name).parts or Path(filename).name != filename:
            raise ValueError("Unsafe resource index")
        entries[name] = (filename, int(size))
    return header, entries


def encode_index(header, entries):
    text = "".join(f"{name}===={filename}===={size}\n"
                   for name, (filename, size) in sorted(entries.items())).encode()
    return header + b"\n" + base64.b64encode(text).translate(bytes.maketrans(STANDARD + b"=", ALPHABET + b"_"))


CHARACTER_RESOURCES = Path(__file__).parent / "character_resources"
CATEGORIES = {1: "神", 2: "妖", 3: "人", 4: "魔", 5: "佛"}


class Resources:
    """Resolve the versioned update snapshot over the original APK resources."""
    def __init__(self, game_root):
        self.directory = Path(game_root) / "assets/release_"
        self.header, self.index = decode_index((self.directory / "index.txt").read_bytes())
        self.manifest = json.loads((CHARACTER_RESOURCES / "manifest.json").read_text())
        self.updated = self.manifest["entries"]
        self.inventory_directory = Path(__file__).parent / "inventory_resources"
        extra_manifest = self.inventory_directory / "manifest.json"
        self.inventory_updated = (json.loads(extra_manifest.read_text())["entries"]
                                  if extra_manifest.exists() else {})
        self.updated = {**self.updated, **self.inventory_updated}
        self.synergy_directory = Path(__file__).parent / "synergy_resources"
        synergy_manifest = self.synergy_directory / "manifest.json"
        self.synergy_updated = (json.loads(synergy_manifest.read_text())["entries"]
                                if synergy_manifest.exists() else {})
        self.updated.update(self.synergy_updated)
        self.battle_directory = Path(__file__).parent / "battle_resources"
        manifest = self.battle_directory / "manifest.json"
        self.battle_updated = json.loads(manifest.read_text())["entries"] if manifest.exists() else {}
        self.updated.update(self.battle_updated)

    def read(self, name):
        if name in self.updated:
            entry = self.updated[name]
            directory = (self.battle_directory if name in self.battle_updated else
                         self.synergy_directory if name in self.synergy_updated else
                         self.inventory_directory if name in self.inventory_updated else CHARACTER_RESOURCES)
            data = (directory / entry["filename"]).read_bytes()
            if len(data) != entry["size"] or hashlib.sha256(data).hexdigest() != entry["sha256"]:
                raise ValueError("Updated resource checksum mismatch: " + name)
            return data
        return (self.directory / self.index[name][0]).read_bytes()

    def rows(self, name):
        data = self.read(name)
        try:
            text = data.decode("utf-8-sig")
        except UnicodeDecodeError:
            text = data.decode("gb18030")
        return list(csv.DictReader(io.StringIO(text)))

    def names(self):
        return sorted(set(self.index) | set(self.updated))

    def source(self, name):
        return {
            "resource": name,
            "version": self.manifest["version"] if name in self.updated else self.header.decode(),
            "filename": self.updated[name]["filename"] if name in self.updated else self.index[name][0],
            "sha256": hashlib.sha256(self.read(name)).hexdigest(),
        }


def is_handbook_hero(row):
    # Original ui/handbookUI.lua: IDs 101..5999, quality > 1, book_hide == 1.
    return 100 < int(row["type_id"]) < 6000 and int(row["quality"]) > 1 and row["book_hide"] == "1"


def character_sprite(row):
    quality = int(row["quality"])
    group = quality if quality >= 4 else 123
    return f"chars/{group}/{group}_{int(row['resource'])}.png"


def sprite_content(data):
    """Opaque bounds used by the detail page to fit wide weapon poses."""
    image = Image.open(io.BytesIO(data)).convert("RGBA")
    bounds = image.getchannel("A").getbbox() or (0, 0, image.width, image.height)
    x, y, right, bottom = bounds
    return {"x": x, "y": y, "width": right - x, "height": bottom - y,
            "texture_width": image.width, "texture_height": image.height}


def catalog(game_root):
    resources = Resources(game_root)
    rows = resources.rows
    bases = {int(r["type_id"]): r for r in rows("csv_config/cortege/cortege_base_0.csv")}
    names = {int(r["type_id"]): r for r in rows("csv_config/cortege/cortege_name_0.csv")}
    skills = {int(r["type_id"]): r for r in rows("csv_config/skill_name.csv")}
    skill_config = {}
    for r in rows("csv_config/skill_base.csv"):
        get = lambda prefix: int(next(v for k, v in r.items() if k.startswith(prefix)))
        skill_config[r["type_id"]] = {
            "id": int(r["type_id"]), "name": skills[int(r["type_id"])]["name"],
            "active": get("use_mode") == 1, "multi": get("effect_target") == 2,
            "quality": int(r["quality"]), "original": r,
        }
    recruitable = sorted((i for i, row in bases.items() if is_handbook_hero(row)),
                         key=lambda i: (-int(bases[i]["quality"]), i))
    heroes = {}
    for ident in sorted(set(recruitable) | {1020, 1021}):
        row = bases[ident]
        quality = int(row["quality"])
        sprite = character_sprite(row)
        data = resources.read(sprite)
        if not data.startswith(b"\x89PNG\r\n\x1a\n"):
            raise ValueError(f"Missing original character sprite: {sprite}")
        heroes[str(ident)] = {
            "id": ident, "name": names[ident]["name"].strip(), "description": names[ident]["desc"],
            "sprite": sprite, "sprite_bounds": sprite_content(data), "quality": quality,
            "category": CATEGORIES[int(row["category"])],
            "skill_id": int(row["chushijineng"]),
            "skill_name": skills[int(row["chushijineng"])]["name"],
            "attack": int(row["base_gongji"]), "defense": int(row["base_fangyu"]),
            "hp": int(row["base_max_hp"]), "magic": int(row["base_max_magic"]),
            "growth": {"hp": float(row["base_maxhp_plus"]),
                       "attack": float(row["base_gongji_plus"]),
                       "defense": float(row["base_fangyu_plus"]),
                       "magic": float(row["base_maxmagic_plus"])},
        }
    stages = []
    map_names = {int(r["id"]): r["name"] for r in rows("csv_config/map_name.csv")}
    for row in rows("csv_config/tollgate_name.csv"):
        if int(row["map_id"]) not in (1, 2):
            continue
        number = len(stages) + 1
        if number > 10:
            break
        stages.append({
            "id": number, "original_id": int(row["id"]), "name": row["name"],
            "chapter": map_names[int(row["map_id"])],
            "enemies": [1020, 1021, 5003 if number % 5 == 0 else 1020],
            "silver": 180 + number * 40, "exp": 30 + number * 10,
        })
    from .battle_rules import build_rules
    from .battle_modes import build_modes
    # Original ui/data.lua getCharacterExperienceCSVConfig: csv_config/cortege_experience.csv
    # stores, per quality, the exp required to advance from `level` to `level + 1`
    # (the value shown as `next_exp` for that level).
    exp_table = {}
    for r in rows("csv_config/cortege_experience.csv"):
        quality = int(r["quality"])
        level = int(r["level"])
        value = int(r["experience"])
        exp_table.setdefault(quality, {})[level] = value
    return {"schema": 2, "combat_rules": build_rules(resources), "battle_modes": build_modes(resources), "heroes": heroes, "stages": stages,
            "recruitable": recruitable, "exp_table": exp_table,
            "skills": skill_config, "rules": "local-v4", "source": "Original APK 1061 + installed update 1263; local combat/reward rules"}
