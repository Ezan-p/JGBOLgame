"""Create a separate game AVD; never overwrite an existing data disk/config."""
import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from game_config import RUNTIME, SDK, load_config
from runtime_profiles import PROFILES


def create_avd(name, runtime_profile):
    profile = PROFILES[runtime_profile]
    avds = RUNTIME / "avd"
    avd = avds / (name + ".avd")
    image = profile["image"]
    if not (image / "system.img").is_file():
        raise RuntimeError("尚未安装 Android 镜像：" + str(image))
    if (avd / "config.ini").exists() or (avds / (name + ".ini")).exists():
        raise RuntimeError("AVD 已存在，保留已有配置和数据：" + str(avd))
    avd.mkdir(parents=True, exist_ok=True)
    (avds / (name + ".ini")).write_text(f"avd.ini.encoding=UTF-8\npath={avd}\ntarget=android-{profile['api']}\n")
    config = {
        "avd.ini.encoding": "UTF-8", "AvdId": name, "avd.ini.displayname": "金箍棒游戏台",
        "abi.type": profile["abi"], "hw.cpu.arch": profile["arch"], "hw.cpu.ncore": profile["cores"], "hw.ramSize": profile["memory"],
        "image.sysdir.1": str(image) + "/", "tag.id": profile["tag"], "tag.display": profile["tag"],
        "disk.dataPartition.size": "2G", "hw.lcd.width": profile["width"], "hw.lcd.height": profile["height"],
        "hw.lcd.density": profile["density"], "hw.gpu.enabled": "yes", "hw.gpu.mode": profile["gpu"],
        "hw.keyboard": "yes", "hw.mainKeys": "no", "hw.audioInput": "no", "hw.audioOutput": "yes",
        "hw.camera.back": "none", "hw.camera.front": "none", "hw.initialOrientation": "landscape",
        "showDeviceFrame": "no", "fastboot.forceColdBoot": "yes", "PlayStore.enabled": "false",
    }
    if profile["arch"] == "arm":
        config["hw.cpu.model"] = "cortex-a8"
    (avd / "config.ini").write_text("".join(f"{k}={v}\n" for k, v in config.items()), encoding="utf-8")
    print("AVD 已创建。启动后运行 manage.py doctor 验证 armeabi 支持：", avd)


if __name__ == "__main__":
    try:
        config = load_config()
        create_avd(config["avd_name"], config["runtime_profile"])
    except RuntimeError as exc:
        sys.exit(str(exc))
