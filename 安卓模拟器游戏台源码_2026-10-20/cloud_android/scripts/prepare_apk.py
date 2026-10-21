"""Rebuild this game's APK without modifying the extracted game files."""
import argparse
import hashlib
import json
import os
import subprocess
import sys
import zipfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from game_config import APK, RUNTIME, SDK, load_config

ROOTS = ("AndroidManifest.xml", "classes.dex", "resources.arsc", "assets", "lib", "res")


def validate_source(game):
    missing = [name for name in ROOTS if not (game / name).exists()]
    if missing:
        raise RuntimeError("游戏资源目录不完整：" + str(game) + "；缺少 " + ", ".join(missing))
    if not (game / "classes.dex").read_bytes().startswith(b"dex\n"):
        raise RuntimeError("classes.dex 格式错误")
    if not (game / "lib/armeabi/libxiyoujilua.so").is_file():
        raise RuntimeError("缺少金箍棒 32 位游戏库 lib/armeabi/libxiyoujilua.so")


def build_unsigned(game, output):
    validate_source(game)
    output.parent.mkdir(parents=True, exist_ok=True)
    # Allowlist excludes the nested game table and all old signing metadata.
    with zipfile.ZipFile(output, "w", compression=zipfile.ZIP_DEFLATED, allowZip64=False) as archive:
        count = 0
        for name in ROOTS:
            path = game / name
            files = [path] if path.is_file() else sorted(path.rglob("*"))
            for file in files:
                if not file.is_file() or file.name == ".DS_Store":
                    continue
                if file.is_symlink():
                    raise RuntimeError("游戏资源不应包含符号链接：" + str(file))
                archive.write(file, file.relative_to(game).as_posix())
                count += 1
    return count


def java_home():
    bundled = sorted((RUNTIME / "java").glob("*/Contents/Home"))
    candidates = bundled + ([Path(os.environ["JAVA_HOME"])] if os.environ.get("JAVA_HOME") else [])
    for home in candidates:
        if (home / "bin/java").is_file() and (home / "bin/keytool").is_file():
            return home
    raise RuntimeError("缺少 Java。先完成运行环境部署，或设置 JAVA_HOME 指向 Java 17。")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--unsigned-only", action="store_true", help="只核验资源并生成未签名 APK，不能直接安装")
    args = parser.parse_args()
    game = load_config()["game_root"]
    validate_source(game)
    out = APK.parent
    bt = SDK / "build-tools/35.0.0"
    if not args.unsigned_only:
        java = java_home()
        for tool in (bt / "zipalign", bt / "lib/apksigner.jar"):
            if not tool.is_file():
                raise RuntimeError("缺少构建工具：" + str(tool))
    unsigned = out / "game-unsigned.apk"
    count = build_unsigned(game, unsigned)
    if args.unsigned_only:
        print(f"未签名 APK（不可安装）：{unsigned}；{count} 个文件")
        return
    def run(args):
        subprocess.run(list(map(str, args)), check=True)
    aligned = out / "game-aligned.apk"
    run([bt / "zipalign", "-f", "-p", "4", unsigned, aligned])
    keystore = out / "local-test.p12"
    if not keystore.exists():
        run([java / "bin/keytool", "-genkeypair", "-keystore", keystore,
             "-storepass", "android", "-keypass", "android", "-alias", "local-test",
             "-keyalg", "RSA", "-keysize", "2048", "-validity", "3650",
             "-dname", "CN=Local Jingubang Test"])
    run([java / "bin/java", "-jar", bt / "lib/apksigner.jar", "sign",
         "--ks", keystore, "--ks-pass", "pass:android", "--key-pass", "pass:android",
         "--v1-signing-enabled", "true", "--v2-signing-enabled", "true",
         "--out", APK, aligned])
    run([java / "bin/java", "-jar", bt / "lib/apksigner.jar", "verify", "--verbose", APK])
    digest = hashlib.sha256()
    with APK.open("rb") as src:
        for chunk in iter(lambda: src.read(1024 * 1024), b""):
            digest.update(chunk)
    (out / "receipt.json").write_text(json.dumps({
        "file": APK.name, "size": APK.stat().st_size, "sha256": digest.hexdigest(),
        "source": str(game), "entries": count, "test_resigned": True,
    }, ensure_ascii=False, indent=2), encoding="utf-8")
    print("可安装的测试 APK：", APK)


if __name__ == "__main__":
    try:
        main()
    except (RuntimeError, subprocess.CalledProcessError) as exc:
        sys.exit(str(exc))
