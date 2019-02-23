FROM godot-fedora:latest

RUN dnf -y install scons git xz java-openjdk yasm && dnf clean all && \
    git clone https://github.com/juj/emsdk.git && \
    cd /root/emsdk && \
    /root/emsdk/emsdk install latest && \
    /root/emsdk/emsdk activate latest 

CMD ['/bin/bash']
