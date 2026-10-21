"""Generate a minimal binary Android manifest using the original string pool.

The game Activity and its Java/JNI class names stay unchanged; the application
package, launcher and permissions are independent of the Lenovo channel app.
"""
import struct

ANDROID = "http://schemas.android.com/apk/res/android"
PACKAGE = "com.sygame.jingubang.localg"
ACTIVITY = "com.sygame.jingubang.lenovo.xiyoujilua"
NONE = 0xffffffff


def build_manifest():
    strings = []
    resource_ids = []

    def string(value, resource=0):
        if value in strings:
            index = strings.index(value)
            if resource:
                resource_ids[index] = resource
            return index
        strings.append(value)
        resource_ids.append(resource)
        return len(strings) - 1

    def attr(name, value, kind=3, android=True, resource=0):
        ns = string(ANDROID) if android else NONE
        name_id = string(name, resource)
        data = string(value) if kind == 3 else value
        raw = data if kind == 3 else NONE
        return struct.pack("<IIIHBBI", ns, name_id, raw, 8, 0, kind, data)

    def node(typ, payload):
        return struct.pack("<HHIII", typ, 16, 16 + len(payload), 1, NONE) + payload

    chunks = [node(0x100, struct.pack("<II", string("android"), string(ANDROID)))]

    def start(name, attrs=()):
        # Android's compiled-XML attribute lookup expects resource ID order.
        attrs = sorted(attrs, key=lambda a: resource_ids[struct.unpack_from("<I", a, 4)[0]])
        payload = struct.pack("<IIHHHHHH", NONE, string(name), 20, 20, len(attrs), 0, 0, 0)
        chunks.append(node(0x102, payload + b"".join(attrs)))

    def end(name):
        chunks.append(node(0x103, struct.pack("<II", NONE, string(name))))

    start("manifest", [
        attr("package", PACKAGE, android=False),
        attr("versionCode", 1, 0x10, resource=0x0101021b),
        attr("versionName", "1.0-local", resource=0x0101021c),
    ])
    start("uses-sdk", [attr("minSdkVersion", 8, 0x10, resource=0x0101020c),
                       attr("targetSdkVersion", 17, 0x10, resource=0x01010270)])
    end("uses-sdk")
    for permission in ("INTERNET", "ACCESS_NETWORK_STATE", "WAKE_LOCK"):
        start("uses-permission", [attr("name", "android.permission." + permission, resource=0x01010003)])
        end("uses-permission")
    start("application", [
        attr("label", "金箍棒·本地", resource=0x01010001),
        attr("icon", 0x7f02006b, 1, resource=0x01010002),
        attr("debuggable", 0, 0x12, resource=0x0101000f),
        attr("allowBackup", 0, 0x12, resource=0x01010280),
    ])
    start("activity", [
        attr("name", ACTIVITY, resource=0x01010003),
        attr("label", "金箍棒·本地", resource=0x01010001),
        attr("theme", 0x01030007, 1, resource=0x01010000),
        attr("screenOrientation", 0, 0x10, resource=0x0101001e),
        attr("configChanges", 0x80, 0x11, resource=0x0101001f),
        attr("exported", 1, 0x12, resource=0x01010010),
    ])
    start("intent-filter")
    start("action", [attr("name", "android.intent.action.MAIN", resource=0x01010003)])
    end("action")
    start("category", [attr("name", "android.intent.category.LAUNCHER", resource=0x01010003)])
    end("category")
    end("intent-filter")
    end("activity")
    end("application")
    end("manifest")
    chunks.append(node(0x101, struct.pack("<II", string("android"), string(ANDROID))))
    data = bytearray()
    offsets = []
    for text in strings:
        offsets.append(len(data))
        raw = text.encode("utf-16le")
        data.extend(struct.pack("<H", len(raw) // 2) + raw + b"\0\0")
    data.extend(b"\0" * (-len(data) % 4))
    header_size = 28
    start_offset = header_size + 4 * len(strings)
    pool = struct.pack("<HHIIIIII", 1, header_size, start_offset + len(data), len(strings),
                       0, 0, start_offset, 0)
    pool += struct.pack("<" + "I" * len(offsets), *offsets) + data
    ids = struct.pack("<HHI", 0x180, 8, 8 + 4 * len(resource_ids))
    ids += struct.pack("<" + "I" * len(resource_ids), *resource_ids)
    body = pool + ids + b"".join(chunks)
    return struct.pack("<HHI", 3, 8, 8 + len(body)) + body
