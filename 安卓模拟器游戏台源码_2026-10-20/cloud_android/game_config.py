"""Shared game/device settings. Relative paths are relative to this directory."""
import json
import os
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent
RUNTIME = ROOT / ".runtime"
SDK = RUNTIME / "sdk"
APK = RUNTIME / "apk/jingubang-test.apk"


def load_config():
    config = json.loads((ROOT / "game.json").read_text(encoding="utf-8"))
    config.setdefault("runtime_profile", "arm64")
    config.setdefault("local_game", False)
    if type(config["local_game"]) is not bool:
        raise ValueError("local_game 必须为布尔值")
    if config["runtime_profile"] not in ("arm64", "arm32-software", "arm32-native"):
        raise ValueError("未知 runtime_profile")
    for key in ("mode", "serial", "adb_path"):
        config[key] = os.environ.get("JGB_" + key.upper(), config[key])
    if config["mode"] not in ("emulator", "adb"):
        raise ValueError("mode 必须是 emulator 或 adb")
    if not re.fullmatch(r"[A-Za-z0-9_.:-]+", config["serial"]):
        raise ValueError("请配置明确的 ADB serial（adb devices 输出的第一列）")
    for key in ("console_port", "grpc_port", "web_port"):
        if type(config[key]) is not int or not 1024 <= config[key] <= 65535:
            raise ValueError("端口必须是 1024—65535 的整数：" + key)
    if not 5554 <= config["console_port"] <= 5682 or config["console_port"] % 2:
        raise ValueError("console_port 必须是 5554—5682 的偶数")
    if len({config["console_port"], config["console_port"] + 1, config["grpc_port"], config["web_port"]}) != 4:
        raise ValueError("安卓控制、ADB、gRPC、网页端口不能重叠")
    if config["local_game"] and 8770 in (config["console_port"], config["console_port"] + 1,
                                       config["grpc_port"], config["web_port"]):
        raise ValueError("本地游戏服务使用 8770，不能与游戏台端口重叠")
    if config["mode"] == "emulator" and config["serial"] != f'emulator-{config["console_port"]}':
        raise ValueError("内置模拟器 serial 必须与 console_port 对应；其他设备请使用 adb 模式")
    for key in ("package", "activity", "avd_name"):
        if not re.fullmatch(r"[A-Za-z0-9_.]+", config[key]):
            raise ValueError("无效配置：" + key)
    for key in ("game_root", "adb_path"):
        config[key] = (ROOT / Path(config[key]).expanduser()).resolve()
    config["component"] = config["package"] + "/" + config["activity"]
    return config


def abi_error(abis, abis32):
    """Legacy lib/armeabi must be explicitly advertised by PackageManager."""
    supported = set(abis.split(",")) | set(abis32.split(","))
    if "armeabi" not in supported:
        return (
            "此设备未声明支持游戏所需的 32 位 armeabi（ABI: "
            + (abis or "未知")
            + "）。无法安装本游戏；请连接支持 armeabi 的安卓设备/模拟器并使用 adb 模式。"
            "仅修改 ARM64 配置或库目录名不能转换原生代码。"
        )
    return None


def device_environment():
    return {
        **os.environ,
        "ANDROID_SDK_ROOT": str(SDK),
        "ANDROID_HOME": str(SDK),
        "ANDROID_AVD_HOME": str(RUNTIME / "avd"),
        "ANDROID_USER_HOME": str(RUNTIME / "android-user"),
        "ANDROID_EMULATOR_HOME": str(RUNTIME / "android-user"),
        "PYTHONPYCACHEPREFIX": str(RUNTIME / "pycache"),
        "ANDROID_ADB_SERVER_PORT": "5037",
    }
