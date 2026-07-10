#!/usr/bin/env bash
#
# Extracts the macOS SDK and Xcode Developer directory from an Xcode .xip and
# packs them into versioned .tar.xz archives in OUT_DIR.
#
# Normally run during the Docker build (EXTRACT_FROM_XIP=1), which unpacks the
# .xip first and enables both SDKs by default. Run manually with EXTRACT_FROM_XIP=0
# against an existing Xcode.app, then set EXTRACT_MACOS=1 and/or EXTRACT_XCODE=1
# to pick what gets packed.
#
# Key env vars:
#   XCODE_SDKV    - Xcode version, used in .xip filename and Xcode archive name (required)
#   APPLE_SDKV    - macOS SDK version, used in the SDK archive name
#   XCODE_APP_PATH, XCODE_XIP_PATH, OUT_DIR - paths (see defaults below)

set -euo pipefail

# Configurable variables (can be set via env)
XCODE_APP_PATH="${XCODE_APP_PATH:-/root/xcode/Xcode.app}"
XCODE_XIP_PATH="${XCODE_XIP_PATH:-/root/files/Xcode_${XCODE_SDKV}.xip}"
EXTRACT_FROM_XIP="${EXTRACT_FROM_XIP:-1}"

OUT_DIR="${OUT_DIR:-/root/files}"

# SDK versions (should be set via env or Dockerfile)
APPLE_SDKV="${APPLE_SDKV:-}"

# Which SDKs to extract (set to 1 to enable)
# Note: These defaults are overridden below based on execution context

# Optionally extract Xcode.app from .xip if needed
if [[ "$EXTRACT_FROM_XIP" == "1" ]]; then
  mkdir -p /root/xcode
  cd /root/xcode
  # Fedora's Apple `xar 1.8` (417.1) fails to open Apple's signed Xcode .xip
  # ("Error opening xar archive"): the RSA <signature> element in the TOC trips
  # xar_open. The .xip is still a valid xar, and its "Content" member is stored
  # uncompressed (application/octet-stream) -- it is exactly the pbzx stream. So
  # we extract Content directly, bypassing xar, then feed it to pbzx as before.
  python3 /root/files/xip_extract_content.py "$XCODE_XIP_PATH" Content Content
  /root/pbzx/pbzx -n Content | cpio -i
  rm -f Content
  XCODE_APP_PATH="/root/xcode/Xcode.app"
fi

if [[ "${EXTRACT_FROM_XIP:-1}" == "1" ]]; then
  EXTRACT_MACOS="${EXTRACT_MACOS:-1}"
  EXTRACT_XCODE="${EXTRACT_XCODE:-1}"
else
  # When called manually, require explicit SDK selection
  EXTRACT_MACOS="${EXTRACT_MACOS:-0}"
  EXTRACT_XCODE="${EXTRACT_XCODE:-0}"
fi

extract_and_pack() {
  local sdk_dir="$1"
  local sdk_name="$2"
  local versioned_name="$3"
  local tar_name="$4"

  if [[ -d "$sdk_dir/$sdk_name" ]]; then

    # Use tar to copy and preserve everything, then repackage
    echo "=== Copying SDK using tar to preserve special files ==="
    cd "$sdk_dir"
    tar -cf - "$sdk_name" | tar -xf - -C /tmp

    # Rename to versioned name
    mv "/tmp/$sdk_name" "/tmp/$versioned_name"

    # Verify SDKSettings.json exists and has content
    if [[ -f "/tmp/$versioned_name/SDKSettings.json" ]]; then
      echo "=== SDKSettings.json found, size: $(wc -c < "/tmp/$versioned_name/SDKSettings.json") bytes ==="
      echo "=== MD5 check ==="
      echo "Source file MD5: $(md5sum "$sdk_dir/$sdk_name/SDKSettings.json" | cut -d' ' -f1)"
      echo "Copied file MD5: $(md5sum "/tmp/$versioned_name/SDKSettings.json" | cut -d' ' -f1)"
    else
      echo "⚠️  Warning: SDKSettings.json not found in extracted SDK"
    fi

    # Create tar with versioned directory name
    tar -cJf "/tmp/$tar_name" -C "/tmp" "$versioned_name"

    # Clean up temporary directory
    rm -rf "/tmp/$versioned_name"
    mv "/tmp/$tar_name" "$OUT_DIR/$tar_name"

    echo "✓ Packed $tar_name"
  else
    echo "✗ SDK not found: $sdk_dir/$sdk_name"
    exit 1
  fi
}

# Xcode Developer
if [[ "$EXTRACT_XCODE" == "1" ]]; then
  extract_and_pack \
    "$XCODE_APP_PATH/Contents" \
    "Developer" \
    "Xcode-Developer${XCODE_SDKV}" \
    "Xcode-Developer${XCODE_SDKV}.tar.xz"
fi

# macOS SDK
if [[ "$EXTRACT_MACOS" == "1" ]]; then
  extract_and_pack \
    "$XCODE_APP_PATH/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs" \
    "MacOSX.sdk" \
    "MacOSX${APPLE_SDKV}.sdk" \
    "MacOSX${APPLE_SDKV}.sdk.tar.xz"
fi

echo "Done extracting selected SDKs."
