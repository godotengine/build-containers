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

These containers have been tested under currently supported Fedora releases
(other distros may work too).

The tool used to build and manage the containers is `podman` (install it with
`dnf -y podman`).

We currently use `podman` as root to build and use these containers. Documenting
a workflow to configure the host OS to be able to do all this without root would
be welcome (but back when we tried we ran into performance issues).


## Usage

The `build.sh` script included is used to build the containers themselves.

The two arguments can take any value and are meant to convey what Godot branch
you are building for (e.g. `4.5`) and what Linux distribution the `Dockerfile.base`
is based on (e.g. `f42` for Fedora 42).

Run the command using:

    ./build.sh 4.5 f42

The above will generate images using the tag '4.5-f42'.
You can then specify it in the `build.sh` of
[godot-build-scripts](https://github.com/godotengine/godot-build-scripts).


### Selecting which images to build

If you don't need to build all versions or you want to try with a single target OS first,
you can comment out the corresponding lines from the script:

    podman_build linux
    podman_build windows
    podman_build web
    podman_build android
    ...


## Image sizes

These are the expected container image sizes, so you can plan your disk usage in advance:

    REPOSITORY                         TAG                SIZE
    localhost/godot-fedora             4.5-f42            949 MB
    localhost/godot-linux              4.5-f42            2.74 GB
    localhost/godot-windows            4.5-f42            2.54 GB
    localhost/godot-web                4.5-f42            2.35 GB
    localhost/godot-android            4.5-f42            4.19 GB
    localhost/godot-osx                4.5-f42            5.30 GB
    localhost/godot-appleembedded      4.5-f42            14.1 GB

In addition to this, generating containers will also require some host disk space
(up to 10 GB) for the dependencies (Xcode).


## Toolchains

These are the toolchains currently in use for Godot 4.3 and later:

- Base image: Fedora 42
- SCons: 4.9.1
- Linux: GCC 13.2.0 built against glibc 2.28, binutils 2.40, from our own [Linux SDK](https://github.com/godotengine/buildroot)
- Windows:
  * x86_64/x86_32: MinGW 12.0.0, GCC 14.2.1, binutils 2.43.1
  * arm64: llvm-mingw 20250528, LLVM 20.1.6
- Web: Emscripten 4.0.10
- Android: Android NDK 28.1.13356709, build-tools 35.0.0, platform android-35, CMake 3.31.6, JDK 21
- Apple: Xcode 16.4 with Apple Clang (LLVM 19.1.4), cctools 1024.3, ld64 955.13
  * macOS: MacOSX SDK 15.5
  * Apple Embedded: iPhoneOS and iPhoneSimulator SDKs 18.5, AppleTVOS and AppleTVSimulator SDKs 18.5, XROS and XRSimulator SDKs 2.5
