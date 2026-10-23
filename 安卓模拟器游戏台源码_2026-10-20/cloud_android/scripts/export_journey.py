"""Reproducible, lossless journey extraction with explicit inference provenance."""
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from game_config import ROOT, load_config
from local_game.assets import Resources
from local_game.battle_modes import build_modes
from local_game.journey import build_journey
from local_game.journey_rules import ASSUMPTIONS, VERSION
from local_game.role_progression import read_levels


def main():
    resources = Resources(load_config()["game_root"])
    data = build_journey(load_config()["game_root"])
    data["enemy_encounters"] = build_modes(resources)["pve"]
    data["role_levels"] = read_levels(resources)
    data["inferred_rules"] = dict(version=VERSION, assumptions=ASSUMPTIONS,
                                  status="Client clues plus user-authorized inference; not original server code")
    data["notes"] = "Original CSV values are unchanged. Runtime sampling, experience distribution and combat use documented reconstructed rules."
    output = ROOT / "outputs/journey-20261023"
    output.mkdir(parents=True, exist_ok=True)
    path = output / "全部关卡与推测规则.json"
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n")
    print(f"Exported {len(data['chapters'])} chapters / {len(data['enemy_encounters'])} stages: {path}")


if __name__ == "__main__":
    main()
