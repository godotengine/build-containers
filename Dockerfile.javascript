ARG img_version
FROM godot-mono:${img_version}

ARG mono_version

RUN if [ -z "${mono_version}" ]; then printf "\n\nArgument mono_version is mandatory!\n\n"; exit 1; fi && \
    dnf -y install --setopt=install_weak_deps=False \
      java-openjdk yasm && \
    git clone --progress https://github.com/emscripten-core/emsdk && \
    cd emsdk && \
    git checkout a5082b232617c762cb65832429f896c838df2483 && \
    ./emsdk install 1.38.47-upstream && \
    ./emsdk activate 1.38.47-upstream && \
    echo "source /root/emsdk/emsdk_env.sh" >> /root/.bashrc

RUN cp -a /root/files/${mono_version} /root && \
    cd /root/${mono_version} && \
    patch -p1 < /root/files/patches/mono-pr16636-wasm-bugfix-and-update.diff && \
    export MONO_SOURCE_ROOT=/root/${mono_version} && \
    export make="make -j" && \
    git clone --progress https://github.com/godotengine/godot-mono-builds /root/godot-mono-builds && \
    cd /root/godot-mono-builds && \
    git checkout 710b275fbf29ddb03fd5285c51782951a110cdab && \
    python3 patch_emscripten.py && \
    python3 wasm.py configure --target=runtime && \
    python3 wasm.py make --target=runtime && \
    cd /root/${mono_version} && git clean -fdx && NOCONFIGURE=1 ./autogen.sh && \
    cd /root/godot-mono-builds && \
    python3 bcl.py make --product wasm && \
    cd /root && \
    rm -rf /root/${mono_version} /root/godot-mono-builds

CMD /bin/bash
