#!/usr/bin/env bash

basedir=$(cd $(dirname "$0"); pwd)

source $basedir/setup.sh

if [ -z "$1" -o -z "$2" ]; then
  echo "Usage: $0 <godot branch> <base distro>"
  echo
  echo "Example: $0 4.x f39"
  echo
  echo "godot branch:"
  echo "        Informational, tracks the Godot branch these containers are intended for."
  echo
  echo "base distro:"
  echo "        Informational, tracks the base Linux distro these containers are based on."
  echo
  echo "The resulting image version will be <godot branch>-<base distro>."
  exit 1
fi

godot_branch=$1
base_distro=$2
img_version=$godot_branch-$base_distro
files_root="$basedir/files"

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

podman_build linux
podman_build windows

podman_build web
podman_build android

XCODE_SDK=16.4
OSX_SDK=15.5
IOS_SDK=18.5
TVOS_SDK=18.5
VISIONOS_SDK=2.5
if [ ! -e "${files_root}"/MacOSX${OSX_SDK}.sdk.tar.xz ] || [ ! -e "${files_root}"/iPhoneOS${IOS_SDK}.sdk.tar.xz ] || [ ! -e "${files_root}"/iPhoneSimulator${IOS_SDK}.sdk.tar.xz ] \
|| [ ! -e "${files_root}"/AppleTVOS${TVOS_SDK}.sdk.tar.xz ] || [ ! -e "${files_root}"/AppleTVSimulator${TVOS_SDK}.sdk.tar.xz ] \
|| [ ! -e "${files_root}"/XROS${VISIONOS_SDK}.sdk.tar.xz ] || [ ! -e "${files_root}"/XRSimulator${VISIONOS_SDK}.sdk.tar.xz ]; then
  if [ ! -r "${files_root}"/Xcode_${XCODE_SDK}.xip ]; then
    echo
    echo "Error: 'files/Xcode_${XCODE_SDK}.xip' is required for Apple platforms, but was not found or couldn't be read."
    echo "It can be downloaded from https://developer.apple.com/download/more/ with a valid apple ID."
    exit 1
  fi

  echo "Extracting Apple SDK packages. This will take a while."
  podman_build xcode
  "$podman" run -it --rm \
    -v "${files_root}":/root/files:z \
    -e XCODE_SDKV="${XCODE_SDK}" \
    -e OSX_SDKV="${OSX_SDK}" \
    -e IOS_SDKV="${IOS_SDK}" \
    -e TVOS_SDKV="${TVOS_SDK}" \
    -e VISIONOS_SDKV="${VISIONOS_SDK}" \
    godot-xcode:${img_version} \
    2>&1 | tee logs/xcode_packer.log
fi

podman_build osx
podman_build appleembedded
