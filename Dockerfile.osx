ARG mono_version
FROM godot-mono:${mono_version}
ARG mono_version

RUN if [ -z "${mono_version}" ]; then echo -e "\n\nargument mono-version is mandatory!\n\n"; exit 1; fi

RUN dnf -y install automake autoconf bzip2-devel clang git libicu-devel libtool libxml2-devel llvm-devel make openssl-devel patch scons xz bzip2 yasm && dnf clean all && \
    git clone https://github.com/tpoechtrager/osxcross.git && \
    cd /root/osxcross && \
    ln -s /root/files/MacOSX10.13.sdk.tar.xz /root/osxcross/tarballs && \
    UNATTENDED=1 ./build.sh ;\
    cd /root && \
    git clone https://github.com/tpoechtrager/apple-libtapi.git && \
    cd apple-libtapi && \
    INSTALLPREFIX=/root/osxcross/target ./build.sh && ./install.sh && \
    cd /root && \
    git clone https://github.com/tpoechtrager/cctools-port.git && \
    cd cctools-port/cctools/ && \
    ./configure --prefix=/root/osxcross/target --target=x86_64-apple-darwin17 --with-libtapi=/root/osxcross/target && \
    make -j && make install && \
    cd /root && \
    ln -fs /root/osxcross/target/bin/x86_64-apple-darwin17-install_name_tool /root/osxcross/target/bin/install_name_tool && \
    ln -fs /root/osxcross/target/bin/x86_64-apple-darwin17-ar /root/osxcross/target/bin/ar && \
    cd /root/osxcross/ && \
    ./build_compiler_rt.sh && \
    export CLANG_LIB_DIR=$(clang -print-search-dirs | grep "libraries: =" | tr '=' ' ' | tr ':' ' ' | awk '{print $2}') && \
    mkdir -p ${CLANG_LIB_DIR}/include && \
    mkdir -p ${CLANG_LIB_DIR}/lib/darwin && \
    cp -rv /root/osxcross/build/compiler-rt/include/sanitizer ${CLANG_LIB_DIR}/include && \
    cp -v /root/osxcross/build/compiler-rt/build/lib/darwin/*.a ${CLANG_LIB_DIR}/lib/darwin && \
    cp -v /root/osxcross/build/compiler-rt/build/lib/darwin/*.dylib ${CLANG_LIB_DIR}/lib/darwin && \
    curl https://download.mono-project.com/sources/mono/mono-${mono_version}.tar.bz2 | tar xj && \
    cd mono-${mono_version} && \
    patch -p1 < /root/files/patches/fix-mono-configure.diff && \
    export PATH=/root/osxcross/target/bin:$PATH && \
    export CMAKE=/root//osxcross/target/bin/x86_64-apple-darwin17-cmake && \
    ./autogen.sh --prefix=/root/dependencies/mono \
        --build=x86_64-linux-gnu \
        --host=x86_64-apple-darwin17 \
        --disable-boehm \
        --disable-mcs-build \
        --with-tls=pthread \
        --disable-dtrace \
        --disable-executables \
        mono_cv_uscore=yes \
        _lt_dar_can_shared=yes \
        CC=o64-clang \
        CXX=o64-clang++ && \
    make -j && \
    make install && \
    rm -f /root/dependencies/mono/bin/mono /root/dependencies/mono/bin/mono-sgen && \
    ln -s /usr/bin/mono /root/dependencies/mono/bin/mono && \
    ln -s /usr/bin/mono-sgen /root/dependencies/mono/bin/mono-sgen && \
    ln -sf /usr/lib/mono/* /root/dependencies/mono/lib/mono ;\
    cp -rvp /etc/mono /root/dependencies/mono/etc && \
    cp /root/files/mono-config-macosx /root/dependencies/mono/etc/config && \
    rm -rf /root/mono-${mono_version} /root/apple-libtapi /root/cctools-port

ENV MONO64_PREFIX=/root/dependencies/mono
ENV OSXCROSS_ROOT=/root/osxcross

CMD ['/bin/bash']
