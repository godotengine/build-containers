# Godot Engine Build Containers

This repository contains the Dockerfiles for the official Godot engine builds. These containers should help you build Godot for all platforms supported on any machine that can run Docker containers.


## What is a Docker?

A Docker is like a chroot environment with its own filesystem, network stack, and process tree. They are similar to a virtual machine, but they use the same kernel as the host operating system.

Basically a **docker image** is a filesystem you can instantiate into a running **docker container**. This allows you to set up and run a complete environment with an isolated filesystem, network stack and process tree, without impacting your primary OS. Though the docker does use the same kernel as the host OS. 

After using these scripts, you will have several linux docker images, each designed to cross compile Godot for a particular platform with officially designated, compatible versions of compilers, sdks and libraries.

[Read more about docker](https://docs.docker.com/engine/docker-overview/).


## How to use this repository

You'll need 25GB+ to store the entire collection (using Podman/overlayfs; maybe 40GB+ for Podman/vfs - see #1) and another 10-20GB while building. The entire process will take 5-10+ hours of downloading and compiling depending on the speed of your internet and system. 

You can reduce time and space needed by manually building only the dockers you need (see #4), or by downloading the pre-built dockers (see #2).

Note: Building the Windows docker on Ubuntu may not work. YMMV.

1. Install [podman](https://podman.io/getting-started/) or [docker](https://docs.docker.com/install/). 

	**Note:** Podman has benefits over docker such as not requiring root access or running a daemon. However it will waste a lot of space if it is configured to use the vfs system. You can reduce space usage by using overlayfs. Do these steps before creating any containers or images.

	1. Install `fuse-overlayfs`.
	1. Edit these lines under the named sections in `~/.config/containers/storage.conf`: 
	```
	[storage]
  	  driver = "overlay"

	[storage.options]
	  mount_program = "/usr/bin/fuse-overlayfs"
	```

1. Optional: Download pre-built dockers. However these dockers may be old. (As of March 1, 2020, they are ancient: Fedora 29.)
	```
	podman pull registry.prehensile-tales.com/godot/export
	podman pull registry.prehensile-tales.com/godot/mono-glue
	podman pull registry.prehensile-tales.com/godot/windows
	podman pull registry.prehensile-tales.com/godot/ubuntu-32
	podman pull registry.prehensile-tales.com/godot/ubuntu-64
	podman pull registry.prehensile-tales.com/godot/javascript
	podman pull registry.prehensile-tales.com/godot/xcode-packer
	```

	See the list of available, non-private dockers [here](https://github.com/godotengine/build-containers/blob/master/upload.sh).

	Dockers that come with a vendor SDK such as Android or IOS cannot be redistributed so you will have to build them on your own with the remaining instructions.

1. Clone this repository:
`git clone https://github.com/godotengine/build-containers`

1. Run `./build.sh <godot branch> <mono tag/branch>`. e.g. `./build.sh master mono-6.6.0.161`
	* Use mono 6+ for Godot 3.2+
	* You can list Godot branches by clicking the Branch button on this page: https://github.com/godotengine/godot
	* You can list Mono branches/tags under the Branch button here: https://github.com/mono/mono
	* You could also manually step through the lines in this script in order to install only the dockers you're interested in, e.g. windows/mono. 

1. Once `build.sh` completes, check your images. You can usally replace the command `podman` with `docker` if you installed the latter.
	```
	$ podman images 
	REPOSITORY                     TAG        	       IMAGE ID       CREATED             SIZE
	localhost/godot-osx            master-mono-6.6.0.161   2588a2164f87   About an hour ago   2.65 GB
	localhost/godot-ios            master-mono-6.6.0.161   6431c17eba79   2 hours ago         1.85 GB
	localhost/godot-javascript     master-mono-6.6.0.161   d63c16ea28e4   2 hours ago         2.74 GB
	localhost/godot-android        master-mono-6.6.0.161   ba83b69aaf2d   2 hours ago         13.3 GB
	localhost/godot-ubuntu-32      master-mono-6.6.0.161   54812d6f6159   3 hours ago         995 MB
	localhost/godot-ubuntu-64      master-mono-6.6.0.161   d15e671bc1f7   3 hours ago         1.67 GB
	localhost/godot-windows        master-mono-6.6.0.161   6b4c7b1d67b1   4 hours ago         2.12 GB
	localhost/godot-mono-glue      master-mono-6.6.0.161   36de478b7116   4 hours ago         1.51 GB
	localhost/godot-mono           master-mono-6.6.0.161   21371aac3535   4 hours ago         1.26 GB
	localhost/godot-export         master-mono-6.6.0.161   951a62f6414c   4 hours ago         863 MB
	localhost/godot-xcode-packer   master-mono-6.6.0.161   ab1cb6e3c8f8   25 hours ago        982 MB
	localhost/godot-fedora         master-mono-6.6.0.161   667fec69f143   25 hours ago        438 MB
	```

### Running a shell inside a docker container
This will instantiate a container based upon the specified image. Here `godot-windows` refers to the `localhost/godot-windows` image listed above.
```
$ podman run -it --rm  godot-windows /usr/bin/bash

[root@a117e628763d ~]# 
```

### Building Godot within a container
You can mount your Godot source tree (`/home/user/godot` below) inside a container, then compile from there:
```
$ podman run -it --rm  -v /home/user/godot:/root/godot godot-windows /bin/sh

[root@a117e628763d ~]# cd godot

[root@a117e628763d godot]# scons -j8 p=windows bits=64 tools=yes target=release_debug module_mono_enabled=yes mono_static=yes mono_glue=yes copy_mono_root=yes mono_prefix=/root/dependencies/mono-64
```

Or you can run it all in one command:	
`podman run --rm  -v /home/user/godot:/root/godot godot-windows scons -C godot -j8 p=windows bits=64 tools=yes target=release_debug module_mono_enabled=yes mono_static=yes mono_glue=yes copy_mono_root=yes mono_prefix=/root/dependencies/mono-64`
	

### Transfering files 
For any part of your host OS directory tree that you have mounted inside a container, you can simultaneously access it inside the docker shell or in your host OS. This allows you to mount the Godot source from your host OS, and as the docker builds Godot, all files are being written to the host OS filesystem. You can immediately access them, for instance to grab the executables from the `godot/bin` directory. 


### Removing docker images
You can remove an image by specifying either the name, or if it was an incomplete build, the image id. Either of these will delete the android image listed above.
```
$ podman rmi ba83b69aaf2d
or
$ podman rmi localhost/godot-android
```

Use `podman images -a` to view incomplete or temporary images.

