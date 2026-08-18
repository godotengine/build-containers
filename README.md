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
you are building for (e.g. `4.8`) and what Linux distribution the `Dockerfile.base`
is based on (e.g. `f44` for Fedora 44).

Run the command using:

    ./build.sh 4.8 f44

The above will generate images using the tag '4.8-f44'.
You can then specify it in the `build.sh` of
[godot-build-scripts](https://github.com/godotengine/godot-build-scripts).


### Selecting which images to build

If you don't need to build all versions or you want to try with a single target OS first,
you can comment out the corresponding lines from the script:

    podman_build linux
    podman_build windows
    podman_build web
    podman_build android
    podman_build apple


## Image sizes

These are the expected container image sizes, so you can plan your disk usage in advance:

    REPOSITORY                         TAG                SIZE
    localhost/godot-fedora             4.8-f44            972 MB
    localhost/godot-linux              4.8-f44            2.98 GB
    localhost/godot-windows            4.8-f44            2.76 GB
    localhost/godot-web                4.8-f44            2.74 GB
    localhost/godot-android            4.8-f44            4.55 GB
    localhost/godot-apple              4.8-f44            11.5 GB
    localhost/godot-xcode              4.8-f44            1.56 GB

In addition to this, generating containers will also require some host disk space
(up to 5 GB) for the dependencies (Xcode).


## Toolchains

These are the toolchains currently in use for Godot 4.3 and later:

- Base image: Fedora 44
- SCons: 4.10.1
- Linux: GCC 15.2.0 built against glibc 2.34, binutils 2.46.0, from our own [Linux SDK](https://github.com/godotengine/buildroot)
- Windows:
  * x86_64/x86_32: MinGW 13.0.0, GCC 16.1.1, binutils 2.46.0
  * arm64: llvm-mingw 20260616, LLVM 22.1.8
- Web: Emscripten 6.0.1
- Android: Android NDK 29.0.14206865, build-tools 36.1.0, platform android-36, CMake 3.31.6, JDK 21
- Apple: Xcode 26.6 with LLVM 21.1.6, Swift 6.3.3, Swiftly 1.1.3
  * SDKs: MacOSX, iPhoneOS, iPhoneSimulator, AppleTVOS, AppleTVSimulator, XROS, XRSimulator
