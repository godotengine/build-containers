#!/bin/bash

basedir=$(cd $(dirname "$0"); pwd)

source $basedir/setup.sh

platforms="linux,windows,web,android,osx,ios,msvc"

if [ -z "$1" -o -z "$2" ]; then
  echo "Usage: $0 <godot branch> <base distro> [<platforms>]"
  echo
  echo "Example: $0 3.x f35"
  echo
  echo "godot branch:"
  echo "        Informational, tracks the Godot branch these containers are intended for."
  echo
  echo "base distro:"
  echo "        Informational, tracks the base Linux distro these containers are based on."
  echo
  echo "(Optional) platforms:"
  echo "        Comma-separated list of platforms."
  echo "        Defaults to: $platforms"
  echo
  echo "The resulting image version will be <godot branch>-<base distro>."
  exit 1
fi

godot_branch=$1
base_distro=$2
img_version=$godot_branch-$base_distro
files_root="$basedir/files"

if [ ! -z "$3" ]; then
  case "$3" in
    free) platforms="linux,windows,web,android";;
    nonfree) platforms="osx,ios,msvc";;
    *) platforms="$3";;
  esac
fi

if [ ! -z "$PS1" ]; then
  # Confirm settings
  echo "Docker image tag: ${img_version}"
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

mkdir -p logs

"$podman" build -t godot-fedora:${img_version} -f Dockerfile.base . 2>&1 | tee logs/base.log

podman_build() {
  # You can add --no-cache as an option to podman_build below to rebuild all containers from scratch.
  "$podman" build \
    --build-arg img_version=${img_version} \
    -v "${files_root}":/root/files:z \
    -t godot-"$1:${img_version}" \
    -f Dockerfile."$1" . \
    2>&1 | tee logs/"$1".log
}

podman_build export

for platform in linux windows web android; do
  if grep -q "$platform" <<< "$platforms"; then podman_build "$platform"; fi
done

if grep -q osx <<< "$platforms" || grep -q ios <<< "$platforms"; then
  XCODE_SDK=14.1
  OSX_SDK=13.0
  IOS_SDK=16.1
  if [ ! -e "${files_root}"/MacOSX${OSX_SDK}.sdk.tar.xz ] || [ ! -e "${files_root}"/iPhoneOS${IOS_SDK}.sdk.tar.xz ] || [ ! -e "${files_root}"/iPhoneSimulator${IOS_SDK}.sdk.tar.xz ]; then
    if [ ! -e "${files_root}"/Xcode_${XCODE_SDK}.xip ]; then
      echo "files/Xcode_${XCODE_SDK}.xip is required. It can be downloaded from https://developer.apple.com/download/more/ with a valid apple ID."
      exit 1
    fi

    echo "Building OSX and iOS SDK packages. This will take a while"
    podman_build xcode
    $podman run -it --rm \
      -v "${files_root}":/root/files:z \
      -e XCODE_SDKV="${XCODE_SDK}" \
      -e OSX_SDKV="${OSX_SDK}" \
      -e IOS_SDKV="${IOS_SDK}" \
      godot-xcode:${img_version} \
      2>&1 | tee logs/xcode_packer.log
  fi

  podman_build osx
  podman_build ios
fi

if grep -q msvc <<< "$platforms"; then
  if [ ! -e "${files_root}"/msvc2017.tar ]; then
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
