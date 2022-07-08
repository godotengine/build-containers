# Godot engine build containers

This repository contains the Dockerfiles for the official Godot engine builds.
These containers should help you build Godot for all platforms supported on
any machine that can run Docker containers.

The in-container build scripts are in a separate repository:
https://github.com/godotengine/godot-build-scripts


## Introduction

These scripts build a number of containers which are then used to build final
Godot tools, templates and server packages for several platforms.

Once these containers are built, they can be used to compile different Godot
versions without the need of recreating them.

The `upload.sh` file is meant to be used by Godot Release Team and is not
documented here.


## Requirements

These containers have been tested under Fedora 36 (other distros/releases may work too).

The tool used to build and manage the containers is `podman` (install it with `dnf -y podman`).

We currently use `podman` as root to build and use these containers. Documenting a workflow to
configure the host OS to be able to do all this without root would be welcome (but back when we
tried we ran into performance issues).


## Usage

The `build.sh` script included is used to build the containers themselves.

The first two arguments can take any value and are meant to convey what Godot branch
you are building for (e.g. `3.x`) and what Linux distribution the `Dockerfile.base`
is based on (e.g. `f36` for Fedora 36).

The third argument is important and should be the name of a tagged Mono release from
the upstream `2020-02` branch (e.g. `mono-6.12.0.182`).

Run the command using:

    ./build.sh 3.x f36 mono-6.12.0.182

The above will generate images using the tag '3.x-f36-mono-6.12.0.182'.
You can then specify it in the `build.sh` of [godot-build-scripts]().

### Selecting which images to build

If you don't need to build all versions or you want to try with a single target OS first,
you can comment out the corresponding lines from the script:

    $podman_build_mono -t godot-linux:${img_version} -f Dockerfile.linux . 2>&1 | tee logs/linux.log
    $podman_build_mono -t godot-windows:${img_version} -f Dockerfile.windows . 2>&1 | tee logs/windows.log
    $podman_build_mono -t godot-javascript:${img_version} -f Dockerfile.javascript . 2>&1 | tee logs/javascript.log
    $podman_build_mono -t godot-android:${img_version} -f Dockerfile.android . 2>&1 | tee logs/android.log
    ...

**Note:** The MSVC image (used for UWP builds) does not work currently.


## Image sizes

These are the expected container image sizes, so you can plan your disk usage in advance:

    REPOSITORY                                       TAG                        SIZE
    localhost/godot-fedora                           3.x-f36-mono-6.12.0.182    546 MB
    localhost/godot-export                           3.x-f36-mono-6.12.0.182    1.03 GB
    localhost/godot-mono                             3.x-f36-mono-6.12.0.182    1.41 GB
    localhost/godot-mono-glue                        3.x-f36-mono-6.12.0.182    1.75 GB
    localhost/godot-linux                            3.x-f36-mono-6.12.0.182    3.8 GB
    localhost/godot-windows                          3.x-f36-mono-6.12.0.182    3.31 GB
    localhost/godot-javascript                       3.x-f36-mono-6.12.0.182    3.87 GB
    localhost/godot-android                          3.x-f36-mono-6.12.0.182    6.06 GB
    localhost/godot-osx                              3.x-f36-mono-6.12.0.182    5.71 GB
    localhost/godot-ios                              3.x-f36-mono-6.12.0.182    6.53 GB

In addition to this, generating containers will also require some host disk space
(up to 30 GB) for the downloaded Mono sources and dependencies (Xcode, MSVC).


## Toolchains

These are the toolchains currently in use for Godot 3.5 and later:

- Base image: Fedora 36
- Mono version: 6.12.0.182
- SCons: 4.3.0
- Linux: GCC 10.2.0 built against glibc 2.19, binutils 2.35.1, from our own [Linux SDK](https://github.com/godotengine/buildroot)
- Windows: MinGW 9.0.0, GCC 11.2.0, binutils 2.37
- HTML5: Emscripten 3.1.14 (standard builds), Emscripten 1.39.9 (Mono builds)
- Android: Android NDK 23.2.8568313, build-tools 32.0.0, platform android-32, CMake 3.18.1
- macOS: Xcode 13.3.1 with LLVM Clang 13.0.1, MacOSX SDK 12.3
- iOS: Xcode 13.3.1 with LLVM Clang 13.0.1, iPhoneOS SDK 15.4
- UWP: Visual Studio 2017, current configuration sadly not easily reproducible
  (`Dockerfile.msvc` image is not compiled by default as it doesn't work)
