"""Install official ARM32 image + locally signed native macOS ARM32 engine, without switching a running AVD.

Image checksum: Google sys-img/android/sys-img2-1.xml.
The native engine is copied from the separately installed SDK emulator.
"""
import hashlib
import json
import platform
import plistlib
import shutil
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from game_config import RUNTIME, SDK
from scripts.prepare_avd import create_avd
from scripts.setup_runtime import extract

PACKAGES = [
    ("arm32-image.zip",
     "https://dl.google.com/android/repository/sys-img/android/armeabi-v7a-23_r06.zip",
     "sha1", "7cf2ad756e54a3acfd81064b63cb0cb9dff2798d",
     SDK / "system-images/android-23/default"),
]


def digest(path, algorithm):
    result = hashlib.new(algorithm)
    with path.open("rb") as src:
        for data in iter(lambda: src.read(1024 * 1024), b""):
            result.update(data)
    return result.hexdigest()


def main():
    # Reinstalling emulator libraries while QEMU is running can crash it.
    processes = subprocess.run(["ps", "-ax", "-o", "command="], capture_output=True, text=True, check=True).stdout
    if any(str(RUNTIME / suffix) in processes for suffix in
           ("compat32/emulator/qemu", "compat32/native-engine/qemu-system-armel-headless")):
        raise RuntimeError("ARM32 模拟器正在运行，请先停止它再部署工具。")
    if platform.system() != "Darwin" or platform.machine() != "arm64":
        raise RuntimeError("当前原生引擎部署方案仅用于 Apple Silicon macOS。")
    source = SDK / "emulator/qemu/darwin-aarch64/qemu-system-armel-headless"
    if not source.is_file():
        raise RuntimeError("请先部署 SDK 的 Apple Silicon 模拟器（本机验证版本 37.2.12）。")
    directory = RUNTIME / "compat32"
    directory.mkdir(parents=True, exist_ok=True)
    receipts = []
    for name, url, algorithm, expected, destination in PACKAGES:
        archive = directory / name
        if not archive.is_file() or digest(archive, algorithm) != expected:
            part = archive.with_suffix(".zip.part")
            subprocess.run(["curl", "-fL", "--retry", "3", "--connect-timeout", "20",
                            "--output", str(part), url], check=True)
            if digest(part, algorithm) != expected:
                raise RuntimeError("官方校验值不匹配，拒绝解压：" + name)
            part.replace(archive)
        print("已核验，正在解压：" + name, flush=True)
        extract(archive, destination)
        receipts.append(dict(file=name, url=url, algorithm=algorithm, checksum=expected))
    # Older official launchers require this SDK directory even for prebuilt images.
    (SDK / "platforms").mkdir(parents=True, exist_ok=True)
    (directory / "receipt.json").write_text(json.dumps(receipts, indent=2))
    engine_dir = directory / "native-engine"
    engine_dir.mkdir(exist_ok=True)
    engine = engine_dir / source.name
    shutil.copy2(source, engine)
    entitlements = engine_dir / "jit-entitlements.plist"
    entitlements.write_bytes(plistlib.dumps({
        "com.apple.security.cs.allow-jit": True,
        "com.apple.security.cs.allow-unsigned-executable-memory": True,
        "com.apple.security.cs.disable-library-validation": True,
    }))
    subprocess.run(["install_name_tool", "-add_rpath",
                    "@executable_path/../../sdk/emulator/lib64", str(engine)], check=True)
    subprocess.run(["codesign", "--force", "--sign", "-", "--options", "runtime",
                    "--entitlements", str(entitlements), str(engine)], check=True)
    subprocess.run(["codesign", "--verify", "--strict", str(engine)], check=True)
    (engine_dir / "receipt.json").write_text(json.dumps({
        "source": str(source), "source_sha256": digest(source, "sha256"),
        "local_engine_sha256": digest(engine, "sha256"),
        "note": "Local copy with JIT entitlements and SDK library rpath; original SDK unchanged",
    }, indent=2))
    if not (RUNTIME / "avd/jingubang32native.ini").exists():
        create_avd("jingubang32native", "arm32-native")
    else:
        print("保留已有 jingubang32native AVD 与游戏数据。")
    print("ARM32 原生引擎和镜像已准备好；使用 README 中的 arm32-native 配置。")


if __name__ == "__main__":
    try:
        main()
    except (RuntimeError, OSError, subprocess.SubprocessError) as exc:
        sys.exit(str(exc))
