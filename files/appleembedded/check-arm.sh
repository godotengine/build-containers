#!/usr/bin/env bash

function check_toolchain
{
    local platform=$1
    local sdk_prefix=$2
    local sdk_version=$3
    # if $4 is true, use the simulator SDK
    if [ "$4" == "true" ]; then
        SDK_DIR="/root/SDKs/${sdk_prefix}Simulator${sdk_version}.sdk"
        TARGET_OS="${platform}${sdk_version}-simulator"
        NAME="${platform} (Simulator)"
    else
        SDK_DIR="/root/SDKs/${sdk_prefix}OS${sdk_version}.sdk"
        TARGET_OS="${platform}${sdk_version}"
        NAME="${platform} (Device)"
    fi

    echo ""
    echo "*** checking ${NAME} toolchain ***"
    echo ""
    echo ""

    echo "int main(){return 0;}" | arm-apple-darwin11-clang -isysroot "$SDK_DIR" -mtargetos=${TARGET_OS} -xc -O2 -c -o test.o - || exit 1
    arm-apple-darwin11-ar rcs libtest.a test.o || exit 1
    rm test.o libtest.a
    echo "${NAME} toolchain OK"
}

check_toolchain "ios" "iPhone" "$IOS_SDK" false
check_toolchain "tvos" "AppleTV" "$TVOS_SDK" false
check_toolchain "xros" "XR" "$XROS_SDK" false
# Check for simulator toolchains
check_toolchain "ios" "iPhone" "$IOS_SDK" true
check_toolchain "tvos" "AppleTV" "$TVOS_SDK" true
check_toolchain "xros" "XR" "$XROS_SDK" true

