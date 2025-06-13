#!/usr/bin/env bash

set -euo pipefail

# Configurable variables (can be set via env)
XCODE_APP_PATH="${XCODE_APP_PATH:-/root/xcode/Xcode.app}"
XCODE_XIP_PATH="${XCODE_XIP_PATH:-/root/files/Xcode_${XCODE_SDKV}.xip}"
EXTRACT_FROM_XIP="${EXTRACT_FROM_XIP:-1}"

OUT_DIR="${OUT_DIR:-/root/files}"

# SDK versions (should be set via env or Dockerfile)
OSX_SDKV="${OSX_SDKV:-}"
IOS_SDKV="${IOS_SDKV:-}"
TVOS_SDKV="${TVOS_SDKV:-}"
VISIONOS_SDKV="${VISIONOS_SDKV:-}"

# Which SDKs to extract (set to 1 to enable)
# Note: These defaults are overridden below based on execution context

# Optionally extract Xcode.app from .xip if needed
if [[ "$EXTRACT_FROM_XIP" == "1" ]]; then
  mkdir -p /root/xcode
  cd /root/xcode
  xar -xf "$XCODE_XIP_PATH"
  /root/pbzx/pbzx -n Content | cpio -i
  XCODE_APP_PATH="/root/xcode/Xcode.app"
fi

if [[ "${EXTRACT_FROM_XIP:-1}" == "1" ]]; then
  EXTRACT_MACOS="${EXTRACT_MACOS:-1}"
  EXTRACT_IOS="${EXTRACT_IOS:-1}"
  EXTRACT_IOS_SIM="${EXTRACT_IOS_SIM:-1}"
  EXTRACT_TVOS="${EXTRACT_TVOS:-1}"
  EXTRACT_TVOS_SIM="${EXTRACT_TVOS_SIM:-1}"
  EXTRACT_VISIONOS="${EXTRACT_VISIONOS:-1}"
  EXTRACT_VISIONOS_SIM="${EXTRACT_VISIONOS_SIM:-1}"
else
  # When called manually, require explicit SDK selection
  EXTRACT_MACOS="${EXTRACT_MACOS:-0}"
  EXTRACT_IOS="${EXTRACT_IOS:-0}"
  EXTRACT_IOS_SIM="${EXTRACT_IOS_SIM:-0}"
  EXTRACT_TVOS="${EXTRACT_TVOS:-0}"
  EXTRACT_TVOS_SIM="${EXTRACT_TVOS_SIM:-0}"
  EXTRACT_VISIONOS="${EXTRACT_VISIONOS:-0}"
  EXTRACT_VISIONOS_SIM="${EXTRACT_VISIONOS_SIM:-0}"
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
    tar -cf - "$sdk_name" | (cd "/tmp" && tar -xf -)

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
    tar -cJf "$OUT_DIR/$tar_name" -C "/tmp" "$versioned_name"

    # Clean up temporary directory
    rm -rf "/tmp/$versioned_name"

    echo "✓ Packed $tar_name"
  else
    echo "✗ SDK not found: $sdk_dir/$sdk_name"
    exit 1
  fi
}

# macOS SDK
if [[ "$EXTRACT_MACOS" == "1" ]]; then
  extract_and_pack \
    "$XCODE_APP_PATH/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs" \
    "MacOSX.sdk" \
    "MacOSX${OSX_SDKV}.sdk" \
    "MacOSX${OSX_SDKV}.sdk.tar.xz"
fi

# iOS SDK
if [[ "$EXTRACT_IOS" == "1" ]]; then
  extract_and_pack \
    "$XCODE_APP_PATH/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs" \
    "iPhoneOS.sdk" \
    "iPhoneOS${IOS_SDKV}.sdk" \
    "iPhoneOS${IOS_SDKV}.sdk.tar.xz"
fi

# iOS Simulator SDK
if [[ "$EXTRACT_IOS_SIM" == "1" ]]; then
  extract_and_pack \
    "$XCODE_APP_PATH/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs" \
    "iPhoneSimulator.sdk" \
    "iPhoneSimulator${IOS_SDKV}.sdk" \
    "iPhoneSimulator${IOS_SDKV}.sdk.tar.xz"
fi

# tvOS SDK
if [[ "$EXTRACT_TVOS" == "1" ]]; then
  extract_and_pack \
    "$XCODE_APP_PATH/Contents/Developer/Platforms/AppleTVOS.platform/Developer/SDKs" \
    "AppleTVOS.sdk" \
    "AppleTVOS${TVOS_SDKV}.sdk" \
    "AppleTVOS${TVOS_SDKV}.sdk.tar.xz"
fi

# tvOS Simulator SDK
if [[ "$EXTRACT_TVOS_SIM" == "1" ]]; then
  extract_and_pack \
    "$XCODE_APP_PATH/Contents/Developer/Platforms/AppleTVSimulator.platform/Developer/SDKs" \
    "AppleTVSimulator.sdk" \
    "AppleTVSimulator${TVOS_SDKV}.sdk" \
    "AppleTVSimulator${TVOS_SDKV}.sdk.tar.xz"
fi

# visionOS SDK
if [[ "$EXTRACT_VISIONOS" == "1" ]]; then
  extract_and_pack \
    "$XCODE_APP_PATH/Contents/Developer/Platforms/XROS.platform/Developer/SDKs" \
    "XROS.sdk" \
    "XROS${VISIONOS_SDKV}.sdk" \
    "XROS${VISIONOS_SDKV}.sdk.tar.xz"
fi

# visionOS Simulator SDK
if [[ "$EXTRACT_VISIONOS_SIM" == "1" ]]; then
  extract_and_pack \
    "$XCODE_APP_PATH/Contents/Developer/Platforms/XRSimulator.platform/Developer/SDKs" \
    "XRSimulator.sdk" \
    "XRSimulator${VISIONOS_SDKV}.sdk" \
    "XRSimulator${VISIONOS_SDKV}.sdk.tar.xz"
fi

echo "Done extracting selected SDKs."
