ARG img_version
FROM godot-mono:${img_version}

ARG mono_version

ENV EMSCRIPTEN_CLASSICAL=2.0.15
ENV EMSCRIPTEN_MONO=1.39.9

RUN if [ -z "${mono_version}" ]; then printf "\n\nArgument mono_version is mandatory!\n\n"; exit 1; fi && \
    dnf -y install --setopt=install_weak_deps=False \
      java-openjdk && \
    git clone --branch ${EMSCRIPTEN_CLASSICAL} --progress https://github.com/emscripten-core/emsdk emsdk_${EMSCRIPTEN_CLASSICAL} && \
    cp -r emsdk_${EMSCRIPTEN_CLASSICAL} emsdk_${EMSCRIPTEN_MONO} && \
    emsdk_${EMSCRIPTEN_CLASSICAL}/emsdk install ${EMSCRIPTEN_CLASSICAL} && \
    emsdk_${EMSCRIPTEN_CLASSICAL}/emsdk activate ${EMSCRIPTEN_CLASSICAL} && \
    emsdk_${EMSCRIPTEN_MONO}/emsdk install ${EMSCRIPTEN_MONO} && \
    emsdk_${EMSCRIPTEN_MONO}/emsdk activate ${EMSCRIPTEN_MONO} && \
    source /root/emsdk_${EMSCRIPTEN_MONO}/emsdk_env.sh && \
    cp -a /root/files/${mono_version} /root && \
    cd /root/${mono_version} && \
    export MONO_SOURCE_ROOT=/root/${mono_version} && \
    cd /root/${mono_version}/godot-mono-builds && \
    python3 patch_emscripten.py && \
    python3 wasm.py configure -j --target=runtime && \
    python3 wasm.py make -j --target=runtime && \
    cd /root/${mono_version} && git clean -fdx && NOCONFIGURE=1 ./autogen.sh && \
    cd /root/${mono_version}/godot-mono-builds && \
    python3 bcl.py make -j --product wasm && \
    cd /root && \
    rm -rf /root/${mono_version}

CMD /bin/bash
