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

These containers have been tested under Fedora 33 and Ubuntu 18.04 (others may work too).

The tool used to build and manage the containers is `podman`.

See the Host OS section below for further information on how to setup your host OS before start.


## Usage

The 'build.sh' script included is used to build the containers themselves.

Run the command using:

    ./build.sh 3.x mono-6.12.0.122

Note that this will also download that Mono branch (2020-02) from Mono repository.
That branch corresponds to the given Mono version (6.12.0.122) as per
https://www.mono-project.com/docs/about-mono/versioning/#mono-source-versioning .

More details can be found in the Godot https://github.com/godotengine/godot-mono-builds
repository (but you don't need this repository, as in this case Mono is built
inside the containers)

The above will generate images using the tag '3.x-mono-6.12.0.122'. This is convenient
since as of today, this branch can be used to compile every 3.x version or
your custom modifications.

### Selecting which images to build

If you don't need to build all versions or you want to try with a single target OS first,
you can comment out the corresponding lines from the script:

    $podman_build_mono -t godot-linux:${img_version} -f Dockerfile.linux . 2>&1 | tee logs/linux.log
    $podman_build_mono -t godot-windows:${img_version} -f Dockerfile.windows --ulimit nofile=65536 . 2>&1 | tee logs/windows.log
    $podman_build_mono -t godot-javascript:${img_version} -f Dockerfile.javascript . 2>&1 | tee logs/javascript.log
    $podman_build_mono -t godot-android:${img_version} -f Dockerfile.android . 2>&1 | tee logs/android.log
    ...

## Host OS preparation

### Podman Fedora image

To be extra-sure that you are building with the same base container image as the official
builds, you can use:

    podman pull registry.fedoraproject.org/fedora@sha256:acc80ce6652d35f55ad220aa1cfa3787cbaf19b0016b202f1ab29dc5060f5392
    podman image tag registry.fedoraproject.org/fedora@27a979020952 fedora:32

### Fedora 33 Host

Fedora 33 default configuration is able to build the containers. Ensure the tools
are installed:

    sudo dnf -y install podman

### Ubuntu 18.04 Host

Install `podman` (as per https://podman.io/getting-started/installation). On
Ubuntu 18.04, podman 2.2.1 was used successfully:

    . /etc/os-release
    echo "deb https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/xUbuntu_${VERSION_ID}/ /" | sudo tee /etc/apt/sources.list.d/devel:kubic:libcontainers:stable.list
    curl -L https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/xUbuntu_${VERSION_ID}/Release.key | sudo apt-key add -
    sudo apt-get update
    sudo apt-get -y upgrade
    sudo apt-get -y install podman
    # (Ubuntu 18.04) Restart dbus for rootless podman
    systemctl --user restart dbus

Modify your system default ulimit to support more open file handlers.
Add this at the end of your /etc/sysctl.conf file:

    fs.file-max = 65536

Then reboot or run:

    sudo sysctl -p

Install Python3 dataclasses:

    pip3 install dataclasses

Install wine64, binfmt_misc, and configure it:

    sudo apt install wine64 wine64-preloader binfmt-support

    sudo bash -c "echo -1 > /proc/sys/fs/binfmt_misc/wine"  # It's ok this command fails, eg. if you don't have wine binfmt
    sudo bash -c 'echo ":windows:M::MZ::/usr/bin/wine:" > /proc/sys/fs/binfmt_misc/register'
    sudo bash -c 'echo ":windowsPE:M::PE::/usr/bin/wine:" > /proc/sys/fs/binfmt_misc/register'

This `binfmt` configuration **is not persistent**, you need to do it after a reboot in order to build the containers.

(Note that this may break previous .exe binfmt support through `run-detectors`).


## Appendix: Image sizes

These are the expected container image sizes, so you can plan your disk usage in advance:

    REPOSITORY                                       TAG                    SIZE
    localhost/godot-fedora                           3.2-mono-6.12.0.114    692 MB
    localhost/godot-export                           3.2-mono-6.12.0.114    1.09 GB
    localhost/godot-mono                             3.2-mono-6.12.0.114    1.51 GB
    localhost/godot-mono-glue                        3.2-mono-6.12.0.114    1.73 GB
    localhost/godot-msvc                             3.2-mono-6.12.0.114    11.5 GB
    localhost/godot-windows                          3.2-mono-6.12.0.114    4.42 GB
    localhost/godot-ubuntu-64                        3.2-mono-6.12.0.114    1.08 GB
    localhost/godot-ubuntu-32                        3.2-mono-6.12.0.114    1 GB
    localhost/godot-javascript                       3.2-mono-6.12.0.114    4.72 GB
    localhost/godot-android                          3.2-mono-6.12.0.114    19.7 GB
    localhost/godot-osx                              3.2-mono-6.12.0.114    2.84 GB
    localhost/godot-ios                              3.2-mono-6.12.0.114    4.53 GB

In addition to this, generating containers will also require some host disk space (around 4.5GB)
for the downloaded Mono sources and dependencies.
