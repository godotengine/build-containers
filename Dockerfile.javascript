FROM godot-fedora:latest

RUN dnf -y install java-openjdk yasm && dnf clean all && \
    git clone https://github.com/emscripten-core/emsdk && \
    cd emsdk && \
    ./emsdk install 1.39.0 && \
    ./emsdk activate 1.39.0 && \
    echo "source /root/emsdk/emsdk_env.sh" >> /root/.bashrc

CMD ['/bin/bash']
