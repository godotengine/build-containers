#!/bin/bash
#
# Patch Apple's Xcode visionOS SDK so it can be consumed by the open-source
# Swift toolchain from swift.org. Apple's compiler (swiftlang-6.3.0.123.x,
# shipped with Xcode 26) and the swift.org 6.3 release compiler diverge in
# several ways; until the relevant upstream fixes land on `swift/release/6.3`
# and are picked up by a swift.org release, we rewrite the affected header
# and `.swiftinterface` files in place.
#
# This script is idempotent and only touches the visionOS SDK (XROS.sdk).
#
# Remove patches as upstream fixes arrive:
#   cat1 - swiftlang/llvm-project#11866 (visionOS availability inference for Obj-C)
#   cat2 - no upstream fix yet; the OSS compiler does a strict string compare
#          on `// swift-compiler-version:` in .swiftinterface files
#   cat3 - Apple private-framework divergences (no upstream fix expected)
#
set -euo pipefail

SDK="${1:-/root/Xcode.app/Contents/Developer/Platforms/XROS.platform/Developer/SDKs/XROS.sdk}"

if [ ! -d "$SDK" ]; then
    echo "patch-visionos-sdk: SDK not found at $SDK" >&2
    exit 1
fi

echo "patch-visionos-sdk: patching $SDK"

# Several patches below work around open-source-Swift bugs that are fixed in
# Swift 6.4+. cat3a/cat3b remain required (RealityFoundation
# C++-interop divergences). Gate cat1/cat2/cat3c on the compiler version.
#
# NOTE: These will be removed once Swift 6.4 is released, but remain for now
SWIFT_MM="$(swift --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+' | head -1 || true)"
APPLE_FIXED=0
if [ -n "$SWIFT_MM" ]; then
    _maj="${SWIFT_MM%%.*}"; _min="${SWIFT_MM#*.}"
    if [ "$_maj" -gt 6 ] || { [ "$_maj" -eq 6 ] && [ "$_min" -ge 4 ]; }; then
        APPLE_FIXED=1
        echo "patch-visionos-sdk: Swift ${SWIFT_MM} detected (>=6.4); applying cat3a/cat3b only (cat1/cat2/cat3c fixed upstream)"
    fi
fi

###############################################################################
# cat1: visionOS availability inference for Obj-C headers.
#
# Apple's compiler infers `API_UNAVAILABLE(visionos)` whenever `ios` is in the
# unavailable list (visionOS derives from iOS). The OSS compiler doesn't do
# that inference yet, so we make the implicit explicit by adding `visionos`
# to every `API_UNAVAILABLE(...)` that lists `ios` but not `visionos`.
#
# Upstream fix: swiftlang/llvm-project#11866 (targets swift/release/6.3).
###############################################################################
if [ "$APPLE_FIXED" -eq 0 ]; then
echo "patch-visionos-sdk: cat1 - adding visionos to API_UNAVAILABLE in headers"
python3 - "$SDK/System/Library/Frameworks" <<'PY'
import os, re, sys
root = sys.argv[1]
pat = re.compile(r"API_UNAVAILABLE\(([^)]*)\)")
def repl(m):
    inner = m.group(1)
    toks = {t.strip() for t in inner.split(",")}
    if "ios" in toks and "visionos" not in toks:
        return f"API_UNAVAILABLE({inner}, visionos)"
    return m.group(0)
ch_files = ch_calls = 0
for dp, _, files in os.walk(root):
    for fn in files:
        if not fn.endswith(".h"):
            continue
        p = os.path.join(dp, fn)
        try:
            with open(p, "r", encoding="utf-8") as f:
                src = f.read()
        except (UnicodeDecodeError, PermissionError):
            continue
        new, _ = pat.subn(repl, src)
        if new != src:
            real = sum(
                1 for m in pat.finditer(src)
                if "ios" in {t.strip() for t in m.group(1).split(",")}
                and "visionos" not in {t.strip() for t in m.group(1).split(",")}
            )
            if real:
                with open(p, "w", encoding="utf-8") as f:
                    f.write(new)
                ch_files += 1
                ch_calls += real
print(f"  patched {ch_calls} calls in {ch_files} files")
PY
fi

###############################################################################
# cat2: swift-compiler-version stamp in .swiftinterface files.
#
# When the OSS compiler rebuilds a module from its textual interface, it does
# a strict string-compare on the `// swift-compiler-version:` header line.
# Apple's SDK is stamped `swiftlang-6.3.0.123.4` (or .5) and the OSS 6.3
# release stamps `swift-6.3-RELEASE`, so the check fails. Rewrite the stamp
# to whatever the locally-installed OSS compiler reports.
#
# No upstream fix planned; this is fundamental to how Apple's release
# pipeline diverges from swift.org.
###############################################################################
if [ "$APPLE_FIXED" -eq 0 ]; then
echo "patch-visionos-sdk: cat2 - rewriting swift-compiler-version stamp in .swiftinterface"
# Try to resolve the OSS compiler's own stamp; fall back to the 6.3 release
# string if swift isn't in PATH at image-build time.
OSS_VERSION="$(swift --version 2>/dev/null | head -1 || true)"
if [ -z "$OSS_VERSION" ]; then
    OSS_VERSION="Swift version 6.3 (swift-6.3-RELEASE)"
fi
echo "  target stamp: $OSS_VERSION"
OSS_VERSION="$OSS_VERSION" python3 - "$SDK" <<'PY'
import os, re, sys
root = sys.argv[1]
oss = os.environ["OSS_VERSION"]
pat = re.compile(r"^// swift-compiler-version:.*$", re.MULTILINE)
ch = 0
for dp, _, files in os.walk(root):
    for fn in files:
        if not fn.endswith(".swiftinterface"):
            continue
        p = os.path.join(dp, fn)
        try:
            with open(p, "r", encoding="utf-8") as f:
                src = f.read()
        except (UnicodeDecodeError, PermissionError):
            continue
        new, n = pat.subn(f"// swift-compiler-version: {oss}", src)
        if n:
            try:
                with open(p, "w", encoding="utf-8") as f:
                    f.write(new)
                ch += 1
            except PermissionError:
                pass
print(f"  rewrote stamp in {ch} .swiftinterface files")
PY
fi

###############################################################################
# cat3a: gut `@inlinable` bodies in RealityFoundation.swiftinterface that
# touch C++-imported types from `simd`/`AVFAudio`.
#
# With `-cxx-interoperability-mode=default` enabled, the OSS compiler treats
# the simd / AVFAudio C headers as C++ and refuses to compile `@inlinable`
# function bodies that use them ("C++ types ... do not support library
# evolution"). The affected declarations are internal helpers that Godot's
# visionOS code never calls, so we replace their bodies with a fatalError
# stub. The framework binary still provides the real implementation at run
# time on actual visionOS hardware.
#
# Gut every `@inlinable internal` unconditionally (they are implementation
# details), and `@inlinable public` only when its body references one of the
# poison tokens.
###############################################################################
RF_IFACE="$SDK/System/Library/Frameworks/RealityFoundation.framework/Modules/RealityFoundation.swiftmodule/arm64e-apple-xros.swiftinterface"
if [ -f "$RF_IFACE" ]; then
    echo "patch-visionos-sdk: cat3a - gutting @inlinable bodies in RealityFoundation.swiftinterface"
    python3 - "$RF_IFACE" <<'PY'
import sys, re
path = sys.argv[1]
with open(path, "r", encoding="utf-8") as f:
    src = f.read()
poison = re.compile(
    r"\b(simd_[A-Za-z_0-9]+|columns|AVAudioSourceNodeRenderBlock|AVAudioSinkNodeReceiverBlock)\b|\.vector\b"
)
lines = src.splitlines(keepends=True)
out = []
i = 0
gi = gp = 0

def find_ob(start):
    j = start
    while j < len(lines):
        if lines[j].rstrip().endswith("{"):
            return j, lines[j].rstrip().rfind("{")
        j += 1
    return None, None

def find_cb(ol, oc):
    depth = 0
    for li in range(ol, len(lines)):
        line = lines[li]
        start = oc + 1 if li == ol else 0
        for ci in range(start, len(line)):
            ch = line[ci]
            if ch == "{":
                depth += 1
            elif ch == "}":
                if depth == 0:
                    return li
                depth -= 1
    return None

while i < len(lines):
    line = lines[i]
    if "@inlinable" in line:
        is_internal = "internal" in line
        ob, oc = find_ob(i)
        if ob is None:
            out.append(line); i += 1; continue
        cb = find_cb(ob, oc)
        if cb is None:
            out.append(line); i += 1; continue
        body_text = "".join(lines[ob:cb + 1])
        gut = is_internal or bool(poison.search(body_text))
        if gut:
            out.extend(lines[i:ob])
            sig_line = lines[ob]
            brace_pos = sig_line.rstrip().rfind("{")
            out.append(sig_line.rstrip()[:brace_pos + 1] + " Swift.fatalError() }\n")
            if is_internal:
                gi += 1
            else:
                gp += 1
            i = cb + 1
            continue
    out.append(line)
    i += 1

with open(path, "w", encoding="utf-8") as f:
    f.write("".join(out))
print(f"  gutted {gi} @inlinable internal + {gp} @inlinable public bodies")
PY

    ###########################################################################
    # cat3b: replace a public typealias whose target is an `AVFAudio` C++ block
    # type. With C++ interop on, the compiler refuses the typealias itself.
    # We swap it to a compatible function type so call sites that use
    # `@escaping RealityFoundation.Audio.GeneratorRenderHandler` still parse.
    ###########################################################################
    echo "patch-visionos-sdk: cat3b - replacing GeneratorRenderHandler typealias in RealityFoundation.swiftinterface"
    sed -i \
        "s|public typealias GeneratorRenderHandler = AVFAudio\.AVAudioSourceNodeRenderBlock|public typealias GeneratorRenderHandler = () -> Swift.Void|" \
        "$RF_IFACE"
else
    echo "patch-visionos-sdk: cat3a/b - RealityFoundation.swiftinterface not found, skipping"
fi

###############################################################################
# cat3c: `CTTextAlignment` / `CTLineBreakMode` default values in RealityKit.
#
# Apple's compiler strips the full `kCTTextAlignment` / `kCTLineBreak` prefix
# from these CoreFoundation enums and exposes them as `.left` /
# `.byTruncatingTail`. The OSS compiler strips a shorter prefix (the exact
# Swift name depends on version), so the default-argument expression in
# `MeshResource.generateText(...)` fails to resolve. Replace the defaults
# with raw-value initializers - they're valid regardless of how the compiler
# names the cases.
###############################################################################
if [ "$APPLE_FIXED" -eq 0 ]; then
RK_IFACE="$SDK/System/Library/Frameworks/RealityKit.framework/Modules/RealityKit.swiftmodule/arm64e-apple-xros.swiftinterface"
if [ -f "$RK_IFACE" ]; then
    echo "patch-visionos-sdk: cat3c - replacing CT enum defaults in RealityKit.swiftinterface"
    sed -i \
        -e "s|alignment: CoreText\.CTTextAlignment = \.left|alignment: CoreText.CTTextAlignment = CoreText.CTTextAlignment(rawValue: 0)!|g" \
        -e "s|lineBreakMode: CoreText\.CTLineBreakMode = \.byTruncatingTail|lineBreakMode: CoreText.CTLineBreakMode = CoreText.CTLineBreakMode(rawValue: 4)!|g" \
        "$RK_IFACE"
else
    echo "patch-visionos-sdk: cat3c - RealityKit.swiftinterface not found, skipping"
fi
fi

echo "patch-visionos-sdk: done"
