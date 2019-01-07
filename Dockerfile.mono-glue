ARG mono_version
FROM godot-mono:${mono_version}
ARG mono_version

RUN dnf -y install scons xorg-x11-server-Xvfb pkgconfig libX11-devel libXcursor-devel libXrandr-devel libXinerama-devel libXi-devel mesa-libGL-devel alsa-lib-devel pulseaudio-libs-devel freetype-devel openssl-devel libudev-devel mesa-libGLU-devel mesa-dri-drivers && dnf clean all

CMD ['/bin/bash']
