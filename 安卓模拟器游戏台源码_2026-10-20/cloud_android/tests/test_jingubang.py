import asyncio
import os
import struct
import sys
import tempfile
import unittest
import zipfile
from pathlib import Path
from types import SimpleNamespace
from unittest.mock import AsyncMock, patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from game_config import abi_error, load_config
from scripts.prepare_apk import build_unsigned
import adb_backend
import manage
import server
from runtime_profiles import emulator_command, emulator_environment
from scripts import prepare_avd


class PackagingTests(unittest.TestCase):
    def test_real_game_root_and_launcher(self):
        cfg = load_config()
        self.assertTrue((cfg["game_root"] / "lib/armeabi/libxiyoujilua.so").is_file())
        expected = ("com.sygame.jingubang.localg/com.sygame.jingubang.lenovo.xiyoujilua"
                    if cfg.get("local_game") else
                    "com.sygame.jingubang.lenovo/com.lenovo.lsf.gamesdk.ui.WelcomeActivity")
        self.assertEqual(cfg["component"], expected)

    def test_packaging_excludes_signatures_and_nested_tools(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            for name, data in {
                "AndroidManifest.xml": b"manifest", "classes.dex": b"dex\n035\0",
                "resources.arsc": b"resource", "assets/file.data": b"game data",
                "lib/armeabi/libxiyoujilua.so": b"library", "res/icon.png": b"image",
                "META-INF/CERT.RSA": b"old signature", "assets/.DS_Store": b"metadata",
                "cloud_android/.runtime/secret": b"not game content",
            }.items():
                path = root / name
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_bytes(data)
            output = root / "cloud_android/output.apk"
            self.assertEqual(build_unsigned(root, output), 6)
            with zipfile.ZipFile(output) as archive:
                self.assertEqual(archive.read("assets/file.data"), b"game data")
                self.assertFalse(any(n.startswith(("META-INF/", "cloud_android/")) for n in archive.namelist()))
                self.assertIsNone(archive.testzip())

    def test_missing_source_fails_before_creating_apk(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp)
            with self.assertRaisesRegex(RuntimeError, "不完整"):
                build_unsigned(path, path / "bad.apk")
            self.assertFalse((path / "bad.apk").exists())


class CompatibilityTests(unittest.TestCase):
    def test_native_arm32_engine_has_sdk_libraries_and_host_graphics(self):
        config = {**load_config(), "runtime_profile": "arm32-native"}
        command = emulator_command(config)
        self.assertIn("/compat32/native-engine/qemu-system-armel-headless", command[0])
        self.assertEqual(command[command.index("-accel") + 1], "off")
        self.assertEqual(command[command.index("-gpu") + 1], "host")
        env = emulator_environment(config)
        self.assertTrue(env["ANDROID_EMULATOR_LAUNCHER_DIR"].endswith("/sdk/emulator"))
        self.assertNotIn("ANDROID_EMULATOR_LAUNCHER_DIR",
                         {k: v for k, v in emulator_environment({"runtime_profile": "arm64"}).items()
                          if k not in os.environ})

    def test_arm32_uses_matching_engine_and_software_cpu(self):
        config = {**load_config(), "runtime_profile": "arm32-software", "avd_name": "jingubang32"}
        command = emulator_command(config)
        self.assertIn("/compat32/emulator/emulator", command[0])
        self.assertEqual(command[command.index("-accel") + 1], "off")
        self.assertEqual(command[command.index("-cores") + 1], "1")
        self.assertNotIn("-no-metrics", command)
        self.assertEqual(command[command.index("-gpu") + 1], "swiftshader_indirect")

    def test_arm32_avd_is_real_arm_image_and_preserves_existing_data(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            image = root / "image"
            image.mkdir()
            (image / "system.img").write_bytes(b"fixture")
            profile = {**prepare_avd.PROFILES["arm32-software"], "image": image}
            with patch.object(prepare_avd, "RUNTIME", root), patch.dict(prepare_avd.PROFILES, {"arm32-software": profile}):
                prepare_avd.create_avd("test32", "arm32-software")
                config = root / "avd/test32.avd/config.ini"
                text = config.read_text()
                self.assertIn("abi.type=armeabi-v7a", text)
                self.assertIn("hw.cpu.arch=arm\n", text)
                self.assertIn("hw.cpu.model=cortex-a8", text)
                self.assertIn("target=android-23", (root / "avd/test32.ini").read_text())
                with self.assertRaisesRegex(RuntimeError, "已存在"):
                    prepare_avd.create_avd("test32", "arm32-software")
                self.assertEqual(config.read_text(), text)

    def test_arm64_only_rejected(self):
        self.assertIn("armeabi", abi_error("arm64-v8a", ""))
        self.assertIsNotNone(abi_error("", ""))
        self.assertIsNotNone(abi_error("x86,x86_64", "x86"))

    def test_legacy_abi_must_be_advertised(self):
        self.assertIsNone(abi_error("arm64-v8a,armeabi-v7a,armeabi", "armeabi-v7a,armeabi"))
        self.assertIsNone(abi_error("armeabi", ""))
        self.assertIsNotNone(abi_error("arm64-v8a,armeabi-v7a", "armeabi-v7a"))

    def test_install_never_runs_on_incompatible_device(self):
        with tempfile.NamedTemporaryFile(suffix=".apk") as apk:
            with patch.object(manage, "inspect_device", return_value={"issue": "不兼容"}), patch.object(manage, "adb") as adb:
                with self.assertRaisesRegex(RuntimeError, "不兼容"):
                    manage.install(Path(apk.name))
                adb.assert_not_called()

    def test_wrong_avd_is_rejected(self):
        cfg = load_config()
        with patch.object(Path, "is_file", return_value=True), patch.object(manage, "adb", side_effect=["device", "other_game\nOK"]):
            with self.assertRaisesRegex(RuntimeError, "拒绝操作"):
                manage.inspect_device(cfg)

    def test_legacy_android_properties(self):
        cfg = {**load_config(), "mode": "adb"}
        values = ["device", "", "", "armeabi-v7a", "armeabi", "1", "4.4"]
        with patch.object(Path, "is_file", return_value=True), patch.object(manage, "adb", side_effect=values):
            self.assertTrue(manage.inspect_device(cfg)["compatible"])


class GatewayGameTests(unittest.IsolatedAsyncioTestCase):
    async def test_launch_uses_channel_entry(self):
        app = {"config": load_config()}
        with patch.object(server, "device_info", AsyncMock(return_value={"issue": None})), patch.object(server, "adb", AsyncMock(return_value="Status: ok")) as adb:
            response = await server.perform_action(app, "launch")
            self.assertEqual(response.status, 200)
            self.assertEqual(adb.call_args.args[-1], app["config"]["component"])

    async def test_launch_blocks_incompatible_device(self):
        with patch.object(server, "device_info", AsyncMock(return_value={"issue": "32 位不兼容"})), patch.object(server, "adb", AsyncMock()) as adb:
            response = await server.perform_action({"config": load_config()}, "launch")
            self.assertEqual(response.status, 503)
            adb.assert_not_awaited()

    async def test_activity_error_is_not_reported_as_success(self):
        with patch.object(server, "device_info", AsyncMock(return_value={"issue": None})), patch.object(server, "adb", AsyncMock(return_value="Error type 3\nError: Activity does not exist")):
            response = await server.perform_action({"config": load_config()}, "launch")
            self.assertEqual(response.status, 503)

    async def test_source_bundle_builds_app_without_missing_mod_assets(self):
        app = server.make_app()
        self.assertFalse(any("/mod/" in resource.canonical for resource in app.router.resources()))


class AdbTests(unittest.IsolatedAsyncioTestCase):
    def touch(self, x, y, pressure, ident=1):
        return SimpleNamespace(touches=[SimpleNamespace(x=x, y=y, pressure=pressure, identifier=ident)])

    async def test_gesture_deferred_until_release_and_disconnect_cancels(self):
        backend = adb_backend.AdbBackend({})
        with patch.object(adb_backend, "execute", AsyncMock()) as execute:
            await backend.sendTouch(self.touch(10, 20, 1))
            execute.assert_not_awaited()
            await backend.sendTouch(self.touch(10, 20, 0))
            self.assertEqual(execute.call_args.args[1:], ("shell", "input", "tap", 10, 20))
            execute.reset_mock()
            await backend.sendTouch(self.touch(10, 20, 1))
            backend.cancel_touches()
            await backend.sendTouch(self.touch(10, 20, 0))
            execute.assert_not_awaited()

    async def test_swipe_and_multitouch_rejection(self):
        backend = adb_backend.AdbBackend({})
        with patch.object(adb_backend, "execute", AsyncMock()) as execute:
            await backend.sendTouch(self.touch(10, 20, 1))
            with self.assertRaisesRegex(ValueError, "单指"):
                await backend.sendTouch(self.touch(30, 40, 1, 2))
            await backend.sendTouch(self.touch(300, 400, 0))
            self.assertEqual(execute.call_args.args[1:8], ("shell", "input", "swipe", 10, 20, 300, 400))

    async def test_shell_metacharacters_are_quoted(self):
        backend = adb_backend.AdbBackend({})
        with patch.object(adb_backend, "execute", AsyncMock()) as execute:
            for key in (";", "'", "$", "`", " "):
                await backend.sendKey(SimpleNamespace(key=key))
                value = execute.call_args.args[-1]
                if key != " ":
                    self.assertNotEqual(value, key)
            with self.assertRaises(ValueError):
                await backend.sendKey(SimpleNamespace(key="hello; reboot"))

    async def test_invalid_screenshot_rejected(self):
        backend = adb_backend.AdbBackend({})
        with patch.object(adb_backend, "execute", AsyncMock(return_value=b"adb: disconnected")):
            with self.assertRaisesRegex(RuntimeError, "PNG"):
                await backend.getScreenshot()
        image = b"\x89PNG\r\n\x1a\n" + b"\0" * 8 + struct.pack(">II", 720, 1280)
        with patch.object(adb_backend, "execute", AsyncMock(return_value=image)):
            shot = await backend.getScreenshot()
            self.assertEqual((shot.format.width, shot.format.height), (720, 1280))


if __name__ == "__main__":
    unittest.main()
