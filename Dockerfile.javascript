ARG img_version
FROM godot-mono:${img_version}

ARG mono_version

RUN if [ -z "${mono_version}" ]; then printf "\n\nArgument mono_version is mandatory!\n\n"; exit 1; fi && \
    dnf -y install --setopt=install_weak_deps=False \
      java-openjdk && \
    git clone --progress https://github.com/emscripten-core/emsdk && \
    cd emsdk && \
    git checkout 1.39.9 && \
    ./emsdk install 1.39.9 && \
    ./emsdk activate 1.39.9 && \
    echo "source /root/emsdk/emsdk_env.sh" >> /root/.bashrc && \
    source /root/emsdk/emsdk_env.sh && \
    cp -a /root/files/${mono_version} /root && \
    cd /root/${mono_version} && \
    patch -p1 < /root/files/patches/mono-emscripten-1.39.9.patch && \
    export MONO_SOURCE_ROOT=/root/${mono_version} && \
    cd /root/${mono_version}/godot-mono-builds && \
    sed -i patch_emscripten.py -e "/emscripten-pr-8457.diff/d" && \
    python3 patch_emscripten.py && \
    python3 wasm.py configure -j --target=runtime && \
    python3 wasm.py make -j --target=runtime && \
    cd /root/${mono_version} && git clean -fdx && NOCONFIGURE=1 ./autogen.sh && \
    cd /root/${mono_version}/godot-mono-builds && \
    python3 bcl.py make -j --product wasm && \
    cd /root && \
    rm -rf /root/${mono_version}

CMD /bin/bash
