"""Version-checked patches for the supplied 3.75 Activity's initialization.

Keep the original Java/JNI engine, but remove channel SDK initialization and
telephony identity collection. No server authentication or purchased entitlement
is altered; the independent client only connects to the new local service.
"""
import hashlib
import struct
import zlib

SOURCE_SHA256 = "4cf16079d3286ce91c61cefae8e663f4c78bad0ad22113bd6d2be5a8f2d916b3"


def patch_dex(source):
    if hashlib.sha256(source).hexdigest() != SOURCE_SHA256:
        raise ValueError("Unsupported DEX version; refusing unverified bytecode edits")
    data = bytearray(source)

    def replace(offset, before, after):
        before = bytes.fromhex(before)
        if data[offset:offset + len(before)] != before or len(before) != len(after):
            raise ValueError("DEX patch precondition failed")
        data[offset:offset + len(before)] = after

    # invoke-virtual + move-result -> const-string destination, string@0 ("") + nops
    for offset, before, register in (
        (0x14ab0a, "6e109d1b0a000c02", 2),  # getIMEI
        (0x14ab3c, "6e10a01b0a000c05", 5),  # getSubscriberId
        (0x14ab44, "6e109e1b0a000c03", 3),  # getMac
    ):
        replace(offset, before, bytes((0x1a, register, 0, 0, 0, 0, 0, 0)))
    replace(0x14aae2, "6e20561b6100", b"\0" * 6)  # proprietary crash reporter
    replace(0x14acc0, "7130de1baa0a", b"\0" * 6)  # ThirdPartyAPI.init
    data[12:32] = hashlib.sha1(data[32:]).digest()
    struct.pack_into("<I", data, 8, zlib.adler32(data[12:]) & 0xffffffff)
    return bytes(data)
