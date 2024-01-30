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

The two arguments can take any value and are meant to convey what Godot branch
you are building for (e.g. `4.x`) and what Linux distribution the `Dockerfile.base`
is based on (e.g. `f39` for Fedora 39).

Run the command using:

    ./build.sh 4.x f39

The above will generate images using the tag '4.x-f39'.
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
    localhost/godot-fedora             4.x-f39            1.20 GB
    localhost/godot-linux              4.x-f39            3.00 GB
    localhost/godot-windows            4.x-f39            2.02 GB
    localhost/godot-web                4.x-f39            2.42 GB
    localhost/godot-android            4.x-f39            4.48 GB
    localhost/godot-osx                4.x-f39            4.94 GB
    localhost/godot-ios                4.x-f39            5.68 GB

In addition to this, generating containers will also require some host disk space
(up to 10 GB) for the dependencies (Xcode).


## Toolchains

These are the toolchains currently in use for Godot 4.2 and later:

- Base image: Fedora 39
- SCons: 4.6.0
- Linux: GCC 13.2.0 built against glibc 2.28, binutils 2.40, from our own [Linux SDK](https://github.com/godotengine/buildroot)
- Windows: MinGW 11.0.0, GCC 13.2.1, binutils 2.40
- Web: Emscripten 3.1.53
- Android: Android NDK 23.2.8568313, build-tools 34.0.0, platform android-34, CMake 3.22.1, JDK 17
- macOS: Xcode 15.2 with Apple Clang (LLVM 16.0.0), MacOSX SDK 14.2
- iOS: Xcode 15.2 with Apple Clang (LLVM 16.0.0), iPhoneOS SDK 17.2
