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
  echo "usage: $0 <godot branch> <mono git version>"
  echo
  echo "For example: $0 3.1 mono-5.18.1.3"
  echo
  exit 1
fi

godot_branch=$1
mono_version=$2
img_version=$godot_branch-$mono_version

mkdir -p logs

$podman build -t godot-fedora:${godot_branch} -f Dockerfile.base . 2>&1 | tee logs/base.log
$podman build -t godot-export:${godot_branch} -f Dockerfile.export . 2>&1 | tee logs/export.log

$podman build --build-arg mono_version=${mono_version} -t godot-mono:${img_version} -f Dockerfile.mono . 2>&1 | tee logs/mono.log
$podman build --build-arg mono_version=${mono_version} -t godot-mono-glue:${img_version} -f Dockerfile.mono-glue . 2>&1 | tee logs/mono-glue.log
$podman build --build-arg mono_version=${mono_version} -v $(pwd)/files:/root/files -t godot-windows:${img_version} -f Dockerfile.windows . 2>&1 | tee logs/windows.log
$podman build --build-arg mono_version=${mono_version} -t godot-ubuntu-64:${img_version} -f Dockerfile.ubuntu-64 . 2>&1 | tee logs/ubuntu-64.log
$podman build --build-arg mono_version=${mono_version} -t godot-ubuntu-32:${img_version} -f Dockerfile.ubuntu-32 . 2>&1 | tee logs/ubuntu-32.log
$podman build --build-arg mono_version=${mono_version} -t godot-android:${img_version} -f Dockerfile.android . 2>&1 | tee logs/android.log
$podman build --build-arg mono_version=${mono_version} -v $(pwd)/files:/root/files -t godot-javascript:${img_version}-upstream -f Dockerfile.javascript . 2>&1 | tee logs/javascript.log

$podman build -t godot-xcode-packer:${godot_branch} -f Dockerfile.xcode -v $(pwd)/files:/root/files . 2>&1 | tee logs/xcode.log

if [ ! -e files/MacOSX10.14.sdk.tar.xz ] || [ ! -e files/iPhoneOS12.4.sdk.tar.xz ] || [ ! -e files/iPhoneSimulator12.4.sdk.tar.xz ]; then
  if [ ! -e files/Xcode_10.3.xip ]; then
    echo "files/Xcode_10.3.xip is required. It can be downloaded from https://developer.apple.com/download/more/ with a valid apple ID"
    exit 1
  fi

  echo "Building OSX and iOS SDK packages. This will take a while"
  $podman run -it --rm -v $(pwd)/files:/root/files godot-xcode-packer:${godot_branch} 2>&1 | tee logs/xcode_packer.log
fi

$podman build -t godot-ios:${img_version} -f Dockerfile.ios -v $(pwd)/files:/root/files . 2>&1 | tee logs/ios.log
$podman build --build-arg mono_version=${mono_version} -t godot-osx:${img_version} -f Dockerfile.osx -v $(pwd)/files:/root/files . 2>&1 | tee logs/osx.log

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

$podman build -t godot-msvc:${img_version} -f Dockerfile.msvc -v $(pwd)/files:/root/files . 2>&1 | tee logs/msvc.log
