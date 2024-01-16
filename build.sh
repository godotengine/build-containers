#!/usr/bin/env bash

basedir=$(cd $(dirname "$0"); pwd)

source $basedir/setup.sh

if [ -z "$1" -o -z "$2" -o -z "$3" ]; then
  echo "Usage: $0 <godot branch> <base distro> <mono version>"
  echo
  echo "Example: $0 3.x f39 mono-6.12.0.198"
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
files_root=$basedir/files
mono_root="${files_root}/${mono_version}"
build_msvc=0

if [ ! -z "$PS1" ]; then
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
fi

# Check out and patch Mono version
if [ ! -e ${mono_root} ]; then
  git clone -b ${mono_version} --single-branch --progress --depth 1 https://github.com/mono/mono ${mono_root}
  pushd ${mono_root}
  # Download all submodules, up to 6 at a time
  git submodule update --init --recursive --recommend-shallow -j 6 --progress
  # Set up godot-mono-builds in tree
  git clone --progress https://github.com/godotengine/godot-mono-builds
  pushd godot-mono-builds
  git checkout 4912f62a8f263e5673012de6ed489402af2d63bb
  export MONO_SOURCE_ROOT=${mono_root}
  python3 patch_mono.py
  popd
  popd
fi

mkdir -p logs

"$podman" build -t godot-fedora:${img_version} -f Dockerfile.base . 2>&1 | tee logs/base.log

podman_build() {
  # You can add --no-cache as an option to podman_build below to rebuild all containers from scratch.
  "$podman" build \
    --build-arg img_version=${img_version} \
    --build-arg mono_version=${mono_version} \
    -v "${files_root}":/root/files:z \
    -t godot-"$1:${img_version}" \
    -f Dockerfile."$1" . \
    2>&1 | tee logs/"$1".log
}

podman_build export
podman_build mono
podman_build mono-glue

podman_build linux
podman_build windows

podman_build javascript
podman_build android

XCODE_SDK=15
OSX_SDK=14.0
IOS_SDK=17.0
if [ ! -e "${files_root}"/MacOSX${OSX_SDK}.sdk.tar.xz ] || [ ! -e "${files_root}"/iPhoneOS${IOS_SDK}.sdk.tar.xz ] || [ ! -e "${files_root}"/iPhoneSimulator${IOS_SDK}.sdk.tar.xz ]; then
  if [ ! -e "${files_root}"/Xcode_${XCODE_SDK}.xip ]; then
    echo ""${files_root}"/Xcode_${XCODE_SDK}.xip is required. It can be downloaded from https://developer.apple.com/download/more/ with a valid apple ID."
    exit 1
  fi

  echo "Building OSX and iOS SDK packages. This will take a while"
  podman_build xcode

  "$podman" run -it --rm \
    -v "${files_root}":/root/files:z \
    -e XCODE_SDKV="${XCODE_SDK}" \
    -e OSX_SDKV="${OSX_SDK}" \
    -e IOS_SDKV="${IOS_SDK}" \
    godot-xcode:${img_version} \
    2>&1 | tee logs/xcode_packer.log
fi

podman_build osx
podman_build ios

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

  podman_build msvc
fi
