ARG img_version
FROM godot-mono:${img_version}

ARG mono_version

ENV EMSCRIPTEN_CLASSICAL=3.1.14
ENV EMSCRIPTEN_MONO=1.39.9

RUN if [ -z "${mono_version}" ]; then printf "\n\nArgument mono_version is mandatory!\n\n"; exit 1; fi && \
    # We need to downgrade to autoconf 2.69 from F35 as autoconf 2.71 from F36 breaks `--host wasm32`.
    dnf -y install --setopt=install_weak_deps=False \
      https://kojipkgs.fedoraproject.org//packages/autoconf/2.69/37.fc35/noarch/autoconf-2.69-37.fc35.noarch.rpm \
      https://kojipkgs.fedoraproject.org//packages/automake/1.16.2/5.fc35/noarch/automake-1.16.2-5.fc35.noarch.rpm && \
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
    python3 bcl.py make -j --product wasm && \
    cd /root && \
    rm -rf /root/${mono_version}

CMD /bin/bash
