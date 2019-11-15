ARG mono_version
FROM godot-mono:${mono_version}
ARG mono_version

RUN dnf -y install --setopt=install_weak_deps=False \
      java-openjdk yasm && \
    dnf clean all && \
    git clone https://github.com/emscripten-core/emsdk && \
    cd emsdk && \
    ./emsdk install 1.38.47-upstream && \
    ./emsdk activate 1.38.47-upstream && \
    echo "source /root/emsdk/emsdk_env.sh" >> /root/.bashrc

RUN git clone https://github.com/mono/mono --branch mono-${mono_version} --single-branch && \
    cd mono && git submodule update --init && cd .. && \
    export MONO_SOURCE_ROOT=/root/mono && \
    git clone https://github.com/godotengine/godot-mono-builds && \
    cd godot-mono-builds && \
    git checkout bd129da22b8b9c96f3e8b07af348cc5fb61504bf && \
    python3 patch_emscripten.py && \
    python3 wasm.py configure --target=runtime && \
    python3 wasm.py make --target=runtime && \
    cd /root/mono && git clean -fdx && NOCONFIGURE=1 ./autogen.sh && \
    cd /root/godot-mono-builds && \
    python3 bcl.py make --product wasm && \
    cd .. && \
    rm -rf /root/mono /root/godot-mono-builds

CMD /bin/bash
