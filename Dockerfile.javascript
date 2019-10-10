FROM godot-fedora:latest

RUN dnf -y install scons git bzip2 xz java-openjdk yasm && dnf clean all && \
    git clone https://github.com/emscripten-core/emsdk && \
    cd emsdk && \
    ./emsdk install latest && \
    ./emsdk activate latest && \
    echo "source /root/emsdk/emsdk_env.sh" >> /root/.bashrc

CMD ['/bin/bash']
