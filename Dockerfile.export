FROM godot-fedora:latest

RUN dnf -y install xorg-x11-server-Xvfb mesa-dri-drivers libXcursor libXinerama libXrandr libXi alsa-lib pulseaudio-libs java-1.8.0-openjdk-devel && dnf clean all

CMD ['/bin/bash']
