"""Matched emulator engines and Android images; CPU architecture is not a label."""
from game_config import RUNTIME, SDK, device_environment

PROFILES = {
    "arm64": {
        "emulator": SDK / "emulator/emulator",
        "image": SDK / "system-images/android-30/google_apis/arm64-v8a",
        "api": 30, "abi": "arm64-v8a", "arch": "arm64", "tag": "google_apis",
        "memory": 4096, "cores": 4, "gpu": "host", "width": 1280, "height": 720,
        "density": 240, "extra": ["-no-metrics"],
    },
    "arm32-software": {
        "emulator": RUNTIME / "compat32/emulator/emulator",
        "image": SDK / "system-images/android-23/default/armeabi-v7a",
        "api": 23, "abi": "armeabi-v7a", "arch": "arm", "tag": "default",
        "memory": 1536, "cores": 1, "gpu": "swiftshader_indirect",
        "width": 960, "height": 540, "density": 160,
        "extra": ["-accel", "off"],
    },
    "arm32-native": {
        "emulator": RUNTIME / "compat32/native-engine/qemu-system-armel-headless",
        "image": SDK / "system-images/android-23/default/armeabi-v7a",
        "api": 23, "abi": "armeabi-v7a", "arch": "arm", "tag": "default",
        "memory": 1536, "cores": 1, "gpu": "host",
        "width": 960, "height": 540, "density": 160,
        "extra": ["-accel", "off", "-no-metrics"],
    },
}


def profile_for(config):
    return PROFILES[config.get("runtime_profile", "arm64")]


def emulator_environment(config):
    env = device_environment()
    if config.get("runtime_profile") == "arm32-native":
        env["ANDROID_EMULATOR_LAUNCHER_DIR"] = str(SDK / "emulator")
        env["ANDROID_EMU_ENABLE_CRASH_REPORTING"] = "0"
    return env


def emulator_command(config, dns="8.8.8.8,1.1.1.1"):
    profile = profile_for(config)
    return [
        str(profile["emulator"]), "-avd", config["avd_name"],
        "-port", str(config["console_port"]), "-grpc", str(config["grpc_port"]),
        "-grpc-use-token", "-no-window", "-no-snapshot", "-no-boot-anim",
        "-gpu", profile["gpu"], "-memory", str(profile["memory"]),
        "-cores", str(profile["cores"]), "-dns-server", dns,
        *profile["extra"],
    ]
