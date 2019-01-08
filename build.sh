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

$podman build -t godot-fedora:latest -f Dockerfile.base .

$podman build --build-arg mono_version=${mono_version} -t godot-mono:${mono_version} -f Dockerfile.mono .
$podman build --build-arg mono_version=${mono_version} -t godot-mono-glue:latest -f Dockerfile.mono-glue .
$podman build --build-arg mono_version=${mono_version} -t godot-windows:latest -f Dockerfile.windows .
$podman build --build-arg mono_version=${mono_version} -t godot-ubuntu-32:latest -f Dockerfile.ubuntu-32 .
$podman build --build-arg mono_version=${mono_version} -t godot-ubuntu-64:latest -f Dockerfile.ubuntu-64 .

$podman build -t godot-android:latest -f Dockerfile.android .
$podman build -t godot-javascript:latest -f Dockerfile.javascript .

$podman build -t godot-xcode-packer:latest -f Dockerfile.xcode -v $(pwd)/files:/root/files .

if [ ! -e files/MacOSX10.13.sdk.tar.xz ] || [ ! -e files/iPhoneOS11.2.sdk.tar.xz ] || [ ! -e files/iPhoneSimulator11.2.sdk.tar.xz ]; then
  if [ ! -e files/Xcode_9.2.xip ]; then
    echo "files/Xcode_9.2.xip is required. It can be downloaded from https://developer.apple.com/download/more/ with a valid apple ID"
    exit 1
  fi

  echo "Building OSX and iOS SDK packages. This will take a while"
  $podman run -it --rm -v $(pwd)/files:/root/files godot-xcode-packer:latest
fi

$podman build -t godot-ios:latest -f Dockerfile.ios -v $(pwd)/files:/root/files .
$podman build --build-arg mono_version=${mono_version} -t godot-osx:latest -f Dockerfile.osx -v $(pwd)/files:/root/files .

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

$podman build -t godot-msvc:latest -f Dockerfile.msvc -v $(pwd)/files:/root/files .
