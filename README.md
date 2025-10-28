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
is based on (e.g. `f43` for Fedora 43).

The third argument is important and should be the name of a tagged Mono release from
the upstream `2020-02` branch (e.g. `mono-6.12.0.182`).

Run the command using:

    ./build.sh 3.x f43 mono-6.12.0.206

The above will generate images using the tag '3.x-f43-mono-6.12.0.206'.
You can then specify it in the `build.sh` of
[godot-build-scripts](https://github.com/godotengine/godot-build-scripts).


### Selecting which images to build

If you don't need to build all versions or you want to try with a single target OS first,
you can comment out the corresponding lines from the script:

    podman_build linux
    podman_build windows
    podman_build javascript
    podman_build android
    ...

**Note:** The MSVC image (used for UWP builds) does not work currently.


## Image sizes

These are the expected container image sizes, so you can plan your disk usage in advance:

    REPOSITORY                                       TAG                        SIZE
    localhost/godot-fedora                           3.x-f43-mono-6.12.0.206    434 MB
    localhost/godot-export                           3.x-f43-mono-6.12.0.206    1.03 GB
    localhost/godot-mono                             3.x-f43-mono-6.12.0.206    1.32 GB
    localhost/godot-mono-glue                        3.x-f43-mono-6.12.0.206    1.61 GB
    localhost/godot-linux                            3.x-f43-mono-6.12.0.206    4.34 GB
    localhost/godot-windows                          3.x-f43-mono-6.12.0.206    3.54 GB
    localhost/godot-javascript                       3.x-f43-mono-6.12.0.206    3.77 GB
    localhost/godot-android                          3.x-f43-mono-6.12.0.206    8.57 GB
    localhost/godot-xcode                            3.x-f43-mono-6.12.0.206    1.01 GB
    localhost/godot-osx                              3.x-f43-mono-6.12.0.206    6.13 GB
    localhost/godot-ios                              3.x-f43-mono-6.12.0.206    7.56 GB

In addition to this, generating containers will also require some host disk space
(up to 30 GB) for the downloaded Mono sources and dependencies (Xcode, MSVC).


## Toolchains

These are the toolchains currently in use for Godot 3.6 and later:

- Base image: Fedora 43
- Mono version: 6.12.0.206
- SCons: 4.10.0
- Linux: GCC 13.2.0 built against glibc 2.28, binutils 2.40, from our own [Linux SDK](https://github.com/godotengine/buildroot)
- Windows: MinGW 13.0.0, GCC 15.2.1, binutils 2.45
- HTML5: Emscripten 3.1.39 (standard builds), Emscripten 1.39.9 (Mono builds)
- Android: Android NDK 28.1.13356709, build-tools 35.0.0, platform android-35, CMake 3.31.6, JDK 17
- macOS: Xcode 16.2 with Apple Clang (LLVM 17.0.6), MacOSX SDK 15.2
- iOS: Xcode 16.2 with Apple Clang (LLVM 17.0.6), iPhoneOS SDK 18.2
- UWP: Visual Studio 2017, current configuration sadly not easily reproducible
  (`Dockerfile.msvc` image is not compiled by default as it doesn't work)
