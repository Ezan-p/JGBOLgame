"""Basic browser control for a selected 32-bit-capable ADB device.

Uses screenshots and completed tap/swipe gestures, not real-time multitouch.
Audio stays on the device. No external process is started or stopped here.
"""
import asyncio
import shlex
import struct
import time
from types import SimpleNamespace


async def execute(app, *args, timeout=15, binary=False):
    proc = await asyncio.create_subprocess_exec(
        str(app["adb"]), "-s", app["config"]["serial"], *map(str, args),
        stdout=asyncio.subprocess.PIPE, stderr=asyncio.subprocess.PIPE, env=app["env"],
    )
    try:
        output, error = await asyncio.wait_for(proc.communicate(), timeout)
    except (asyncio.TimeoutError, asyncio.CancelledError):
        if proc.returncode is None:
            proc.kill()
        await proc.communicate()
        raise
    if proc.returncode:
        raise RuntimeError(error.decode(errors="replace")[:500] or "ADB 操作失败")
    return output if binary else output.decode(errors="replace").strip()


class AdbBackend:
    def __init__(self, app):
        self.app = app
        self.touches = {}

    async def getStatus(self, *args, **kwargs):
        state = await execute(self.app, "get-state")
        if state != "device":
            raise RuntimeError("指定 ADB 设备未就绪，请连接设备并授权 USB 调试。")
        return SimpleNamespace(version="ADB")

    async def getScreenshot(self, *args, **kwargs):
        data = await execute(self.app, "exec-out", "screencap", "-p", timeout=10, binary=True)
        if len(data) < 24 or data[:8] != b"\x89PNG\r\n\x1a\n":
            raise RuntimeError("设备未返回 PNG 截图")
        width, height = struct.unpack(">II", data[16:24])
        if not 0 < width <= 8192 or not 0 < height <= 8192:
            raise RuntimeError("截图尺寸无效")
        return SimpleNamespace(image=data, format=SimpleNamespace(width=width, height=height))

    async def sendTouch(self, event, **kwargs):
        for touch in event.touches:
            ident = touch.identifier
            if touch.pressure:
                if ident not in self.touches:
                    if self.touches:
                        raise ValueError("ADB 模式仅支持单指点击/滑动")
                    self.touches[ident] = (touch.x, touch.y, time.monotonic())
            else:
                start = self.touches.pop(ident, None)
                if start is None:
                    continue
                x, y, began = start
                duration = max(1, min(2000, int((time.monotonic() - began) * 1000)))
                if abs(x - touch.x) + abs(y - touch.y) < 8 and duration < 400:
                    await execute(self.app, "shell", "input", "tap", x, y)
                else:
                    await execute(self.app, "shell", "input", "swipe",
                                  x, y, touch.x, touch.y, duration)

    def cancel_touches(self):
        # Disconnect must not turn an unfinished gesture into a tap.
        self.touches.clear()

    async def sendKey(self, event, **kwargs):
        keys = {"GoBack": 4, "GoHome": 3, "AudioVolumeUp": 24, "AudioVolumeDown": 25,
                "Enter": 66, "Backspace": 67, "ArrowLeft": 21, "ArrowRight": 22,
                "ArrowUp": 19, "ArrowDown": 20, "Tab": 61}
        if event.key in keys:
            await execute(self.app, "shell", "input", "keyevent", keys[event.key])
        elif len(event.key) == 1 and 32 <= ord(event.key) < 127:
            # adb shell reconstructs a remote shell command; quote printable input.
            await execute(self.app, "shell", "input", "text",
                          shlex.quote("%s" if event.key == " " else event.key))
        else:
            raise ValueError("不支持的按键")
