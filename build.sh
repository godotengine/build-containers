#!/bin/bash
set -e

podman=`which podman || true`

if [ -z $podman ]; then
  echo "podman needs to be in PATH for this script to work."
  exit 1
fi

if [ -z "$1" -o -z "$2" -o -z "$3" ]; then
  echo "Usage: $0 <godot branch> <base distro> <mono version>"
  echo
  echo "Example: $0 3.x f35 mono-6.12.0.178"
  echo
  echo "godot branch:"
  echo "        Informational, tracks the Godot branch these containers are intended for."
  echo
  echo "base distro:"
  echo "        Informational, tracks the base Linux distro these containers are based on."
  echo
  echo "mono version:"
  echo "	Defines the Mono tag that will be cloned with Git to compile from source."
  echo
  echo "The resulting image version will be <godot branch>-<base distro>-<mono version>."
  exit 1
fi

godot_branch=$1
base_distro=$2
mono_version=$3
img_version=$godot_branch-$base_distro-$mono_version
files_root=$(pwd)/files
mono_root="${files_root}/${mono_version}"
build_msvc=0

# Confirm settings
echo "Docker image tag: ${img_version}"
echo "Mono branch: ${mono_version}"
if [ -e ${mono_root} ]; then
  mono_exists="(exists)"
fi
echo "Mono source folder: ${mono_root} ${mono_exists}"
echo
while true; do
  read -p "Is this correct? [y/n] " yn
  case $yn in
    [Yy]* ) break;;
    [Nn]* ) exit 1;;
    * ) echo "Please answer yes or no.";;
  esac
done

mkdir -p logs

# Check out and patch Mono version
if [ ! -e ${mono_root} ]; then
  git clone -b ${mono_version} --single-branch --progress --depth 1 https://github.com/mono/mono ${mono_root}
  pushd ${mono_root}
  # Download all submodules, up to 6 at a time
  git submodule update --init --recursive --recommend-shallow -j 6 --progress
  # Set up godot-mono-builds in tree
  git clone --progress https://github.com/godotengine/godot-mono-builds
  pushd godot-mono-builds
  git checkout fcf205c105bb2eb88dc85975887170c42675d245
  export MONO_SOURCE_ROOT=${mono_root}
  python3 patch_mono.py
  popd
  popd
fi

# You can add --no-cache  as an option to podman_build below to rebuild all containers from scratch
export podman_build="$podman build --build-arg img_version=${img_version}"
export podman_build_mono="$podman_build --build-arg mono_version=${mono_version} -v ${files_root}:/root/files"

$podman build -v ${files_root}:/root/files -t godot-fedora:${img_version} -f Dockerfile.base . 2>&1 | tee logs/base.log
$podman_build -t godot-export:${img_version} -f Dockerfile.export . 2>&1 | tee logs/export.log

$podman_build_mono -t godot-mono:${img_version} -f Dockerfile.mono . 2>&1 | tee logs/mono.log
$podman_build_mono -t godot-mono-glue:${img_version} -f Dockerfile.mono-glue . 2>&1 | tee logs/mono-glue.log
$podman_build_mono -t godot-linux:${img_version} -f Dockerfile.linux . 2>&1 | tee logs/linux.log
$podman_build_mono -t godot-windows:${img_version} -f Dockerfile.windows . 2>&1 | tee logs/windows.log
$podman_build_mono -t godot-javascript:${img_version} -f Dockerfile.javascript . 2>&1 | tee logs/javascript.log
$podman_build_mono -t godot-android:${img_version} -f Dockerfile.android . 2>&1 | tee logs/android.log

XCODE_SDK=13.3.1
OSX_SDK=12.3
IOS_SDK=15.4
if [ ! -e files/MacOSX${OSX_SDK}.sdk.tar.xz ] || [ ! -e files/iPhoneOS${IOS_SDK}.sdk.tar.xz ] || [ ! -e files/iPhoneSimulator${IOS_SDK}.sdk.tar.xz ]; then
  if [ ! -e files/Xcode_${XCODE_SDK}.xip ]; then
    echo "files/Xcode_${XCODE_SDK}.xip is required. It can be downloaded from https://developer.apple.com/download/more/ with a valid apple ID."
    exit 1
  fi

  echo "Building OSX and iOS SDK packages. This will take a while"
  $podman_build -t godot-xcode-packer:${img_version} -f Dockerfile.xcode -v ${files_root}:/root/files . 2>&1 | tee logs/xcode.log
  $podman run -it --rm -v ${files_root}:/root/files -e XCODE_SDKV="${XCODE_SDK}" -e OSX_SDKV="${OSX_SDK}" -e IOS_SDKV="${IOS_SDK}" godot-xcode-packer:${img_version} 2>&1 | tee logs/xcode_packer.log
fi

$podman_build_mono -t godot-osx:${img_version} -f Dockerfile.osx . 2>&1 | tee logs/osx.log
$podman_build_mono -t godot-ios:${img_version} -f Dockerfile.ios . 2>&1 | tee logs/ios.log

if [ "${build_msvc}" != "0" ]; then
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

  $podman_build -t godot-msvc:${img_version} -f Dockerfile.msvc -v ${files_root}:/root/files . 2>&1 | tee logs/msvc.log
fi
