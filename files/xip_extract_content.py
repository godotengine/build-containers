#!/usr/bin/env python3
#
# Extracts a single stored file (default: "Content") from an Apple Xcode .xip
# (a signed xar archive) without using the `xar` tool.
#
# Fedora's `xar 1.8dev` fails to open Apple's signed xips ("Error opening xar
# archive") because it dies initialising the checksum/crypto context. The xip
# is a perfectly valid xar though, so we parse the header + TOC ourselves and
# stream the requested heap file to disk. The Xcode payload ("Content") is
# stored with encoding application/octet-stream (no xar-level compression), so
# the extracted bytes are exactly the pbzx stream that `pbzx` expects.
#
# Usage: xip_extract_content.py <xip path> [member name] [output path]
#   member name  defaults to "Content"
#   output path  defaults to ./<member name>

import os
import struct
import sys
import zlib
import xml.etree.ElementTree as ET

HEADER_FMT = ">4sHHQQI"  # magic, header size, version, toc(compressed), toc(uncompressed), cksum alg
HEADER_LEN = struct.calcsize(HEADER_FMT)
CHUNK = 8 * 1024 * 1024


def main() -> int:
    if len(sys.argv) < 2:
        sys.stderr.write("usage: xip_extract_content.py <xip> [member] [output]\n")
        return 2

    xip = sys.argv[1]
    member = sys.argv[2] if len(sys.argv) > 2 else "Content"
    out = sys.argv[3] if len(sys.argv) > 3 else member

    with open(xip, "rb") as f:
        header = f.read(HEADER_LEN)
        magic, hsize, ver, toc_c, toc_u, cksum = struct.unpack(HEADER_FMT, header)
        if magic != b"xar!":
            sys.stderr.write(f"not a xar archive: {xip}\n")
            return 1
        f.seek(hsize)
        toc = zlib.decompress(f.read(toc_c))
        heap_start = hsize + toc_c

        root = ET.fromstring(toc)
        entry = None
        for fe in root.iter("file"):
            if fe.findtext("name") == member:
                entry = fe
                break
        if entry is None:
            sys.stderr.write(f"member not found in TOC: {member}\n")
            return 1

        data = entry.find("data")
        offset = int(data.findtext("offset"))
        length = int(data.findtext("length"))
        enc = data.find("encoding")
        style = enc.get("style") if enc is not None else "(stored)"
        if style not in ("application/octet-stream", "(stored)"):
            sys.stderr.write(
                f"member {member} uses xar encoding {style!r}; only stored data is supported\n"
            )
            return 1

        f.seek(heap_start + offset)
        remaining = length
        with open(out, "wb") as o:
            while remaining > 0:
                buf = f.read(min(CHUNK, remaining))
                if not buf:
                    sys.stderr.write("unexpected EOF while reading heap (truncated xip?)\n")
                    return 1
                o.write(buf)
                remaining -= len(buf)

    sys.stderr.write(f"extracted {member} ({length} bytes) -> {out}\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
