#!/bin/bash
set -e

podman=`which podman || true`

if [ -z $podman ]; then
  echo "podman needs to be in PATH for this script to work."
  exit 1
fi

if ! grep -rq '/usr/bin/wine' /proc/sys/fs/binfmt_misc; then
  echo "binfmt_misc support for PE pointing to /usr/bin/wine must be enabled to build the Windows mono container."
  echo "This can be done by:"
  echo 'mount binfmt_misc -t binfmt_misc /proc/sys/fs/binfmt_misc'
  echo 'echo ":windows:M::MZ::/usr/bin/wine:" > /proc/sys/fs/binfmt_misc/register'
  echo 'echo ":windowsPE:M::PE::/usr/bin/wine:" > /proc/sys/fs/binfmt_misc/register'
  exit 1
fi

if [ -z "$1" -o -z "$2" ]; then
  echo "Usage: $0 <godot branch> <mono version> [<mono branch> <mono commit hash>]"
  echo
  echo "Examples: $0 3.x mono-6.12.0.147"
  echo "	$0 master mono-6.6.0.160 2019-08 bef1e6335812d32f8eab648c0228fc624b9f8357"
  echo
  echo "godot branch:"
  echo "mono version:"
  echo "	These are combined to form the docker image tag, e.g. 'master-mono-6.6.0.160'."
  echo "	Git will then clone the branch/tag that matches the mono version."
  echo
  echo "mono branch:"
  echo "	If specified, git will clone this mono branch/tag instead. Requires specifying a commit."
  echo
  echo "mono commit:"
  echo "	If specified, git will check out this commit after cloning."
  echo
  exit 1
fi

godot_branch=$1
mono_version=$2
img_version=$godot_branch-$mono_version
files_root=$(pwd)/files
mono_commit=
mono_commit_str=

# If optional Mono git branch and commit hash were passed, use them.
if [ ! -z "$3" -a ! -z "$4" ]; then
  mono_version=$3
  mono_commit=$4
  mono_commit_str="-${mono_commit:0:7}"
fi

# If mono branch does not start with mono-, prepend it to the folder name.
if [ ${mono_version:0:5} != "mono-" ]; then
  mono_root="${files_root}/mono-${mono_version}${mono_commit_str}"
else
  mono_root="${files_root}/${mono_version}${mono_commit_str}"
fi

# Confirm settings
echo "Docker image tag: ${img_version}"
echo "Mono branch: ${mono_version}"
if [ ! -z "$mono_commit" ]; then
  echo "Mono commit: ${mono_commit}"
fi
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
  if [ ! -z "${mono_commit}" ]; then
    # If a commit is specified, get the full history
    git clone -b ${mono_version} --single-branch --progress https://github.com/mono/mono ${mono_root}
    pushd ${mono_root}
    git checkout ${mono_commit}
  else
    # Otherwise, get a shallow repo
    git clone -b ${mono_version} --single-branch --progress --depth 1 https://github.com/mono/mono ${mono_root}
    pushd ${mono_root}
  fi
  # Download all submodules, up to 6 at a time
  git submodule update --init --recursive --recommend-shallow -j 6 --progress
  # Set up godot-mono-builds in tree
  git clone --progress https://github.com/godotengine/godot-mono-builds
  pushd godot-mono-builds
  git checkout 0d72e71a50f2b76f10cd348a3bbb6ed81209b5e4
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

XCODE_SDK=12.4
OSX_SDK=11.1
IOS_SDK=14.4
if [ ! -e files/MacOSX${OSX_SDK}.sdk.tar.xz ] || [ ! -e files/iPhoneOS${IOS_SDK}.sdk.tar.xz ] || [ ! -e files/iPhoneSimulator${IOS_SDK}.sdk.tar.xz ]; then
  if [ ! -e files/Xcode_${XCODE_SDK}.xip ]; then
    echo "files/Xcode_${XCODE_SDK}.xip is required. It can be downloaded from https://developer.apple.com/download/more/ with a valid apple ID."
    exit 1
  fi

  echo "Building OSX and iOS SDK packages. This will take a while"
  $podman_build -t godot-xcode-packer:${img_version} -f Dockerfile.xcode -v ${files_root}:/root/files . 2>&1 | tee logs/xcode.log
  $podman run -it --rm -v ${files_root}:/root/files godot-xcode-packer:${img_version} 2>&1 | tee logs/xcode_packer.log
fi

$podman_build_mono -t godot-osx:${img_version} -f Dockerfile.osx . 2>&1 | tee logs/osx.log
$podman_build_mono -t godot-ios:${img_version} -f Dockerfile.ios . 2>&1 | tee logs/ios.log

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
