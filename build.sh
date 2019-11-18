#!/bin/bash

set -e

podman=podman
if ! which $podman; then
  podman=docker
fi

if ! which $podman; then
  echo "Either podman or docker need to be in PATH for this script to work."
  exit 1
fi

if [ -z "$1" ]; then
  echo "usage: $0 <mono version"
  echo
  echo "For example: $0 5.16.0.220"
  echo
  exit 1
fi

mono_version=$1

mkdir -p logs

$podman build -t godot-fedora:latest -f Dockerfile.base . 2>&1 | tee logs/base.log
$podman build -t godot-export:latest -f Dockerfile.export . 2>&1 | tee logs/export.log

$podman build --build-arg mono_version=${mono_version} -t godot-mono:${mono_version} -f Dockerfile.mono . 2>&1 | tee logs/mono.log
$podman build --build-arg mono_version=${mono_version} -t godot-mono-glue:latest -f Dockerfile.mono-glue . 2>&1 | tee logs/mono-glue.log
$podman build --build-arg mono_version=${mono_version} -v $(pwd)/files:/root/files -t godot-windows:latest -f Dockerfile.windows . 2>&1 | tee logs/windows.log
$podman build --build-arg mono_version=${mono_version} -t godot-ubuntu-64:latest -f Dockerfile.ubuntu-64 . 2>&1 | tee logs/ubuntu-64.log
$podman build --build-arg mono_version=${mono_version} -t godot-ubuntu-32:latest -f Dockerfile.ubuntu-32 . 2>&1 | tee logs/ubuntu-32.log
$podman build --build-arg mono_version=${mono_version} -t godot-android:latest -f Dockerfile.android . 2>&1 | tee logs/android.log
$podman build --build-arg mono_version=${mono_version} -t godot-javascript:latest -f Dockerfile.javascript . 2>&1 | tee logs/javascript.log

$podman build -t godot-xcode-packer:latest -f Dockerfile.xcode -v $(pwd)/files:/root/files . 2>&1 | tee logs/xcode.log

if [ ! -e files/MacOSX10.14.sdk.tar.xz ] || [ ! -e files/iPhoneOS12.4.sdk.tar.xz ] || [ ! -e files/iPhoneSimulator12.4.sdk.tar.xz ]; then
  if [ ! -e files/Xcode_10.3.xip ]; then
    echo "files/Xcode_10.3.xip is required. It can be downloaded from https://developer.apple.com/download/more/ with a valid apple ID"
    exit 1
  fi

  echo "Building OSX and iOS SDK packages. This will take a while"
  $podman run -it --rm -v $(pwd)/files:/root/files godot-xcode-packer:latest 2>&1 | tee logs/xcode_packer.log
fi

$podman build -t godot-ios:latest -f Dockerfile.ios -v $(pwd)/files:/root/files . 2>&1 | tee logs/ios.log
$podman build --build-arg mono_version=${mono_version} -t godot-osx:latest -f Dockerfile.osx -v $(pwd)/files:/root/files . 2>&1 | tee logs/osx.log

if [ ! -e files/msvc2017.tar ]; then
  echo
  echo "files/msvc2017.tar is missing. This file can be created on a Windows 7 or 10 machine by downloading the 'Visual Studio Tools' installer."
  echo "here: https://visualstudio.microsoft.com/downloads/#build-tools-for-visual-studio-2017"
  echo "The required components can be installed by running"
  echo "vs_buildtools.exe --add Microsoft.VisualStudio.Workload.UniversalBuildTools --add Microsoft.VisualStudio.Workload.VCTools --add Microsoft.VisualStudio.Component.Windows10SDK.16299.Desktop --add Microsoft.VisualStudio.Component.Windows10SDK.16299.UWP.Native --passive"
  echo "after that create a zipfile of C:/Program Files (x86)/Microsoft Visual Studio"
  echo "tar -cf msvc2017.tar -C \"c:/Program Files (x86)/ Microsoft Visual Studio\""
  echo
  exit 1
fi

$podman build -t godot-msvc:latest -f Dockerfile.msvc -v $(pwd)/files:/root/files . 2>&1 | tee logs/msvc.log
