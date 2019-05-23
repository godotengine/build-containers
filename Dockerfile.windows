ARG mono_version
FROM godot-mono:${mono_version}
ARG mono_version

RUN if [ -z "${mono_version}" ]; then echo -e "\n\nargument mono-version is mandatory!\n\n"; exit 1; fi

RUN dnf -y install scons mingw32-gcc mingw32-gcc-c++ mingw32-winpthreads-static mingw64-gcc mingw64-gcc-c++ mingw64-winpthreads-static yasm && dnf clean all && \
    rpm -Uvh --replacepkgs /root/files/mingw-binutils-generic-2.30-5.fc29.godot.x86_64.rpm \
                           /root/files/mingw64-binutils-2.30-5.fc29.godot.x86_64.rpm \
                           /root/files/mingw32-binutils-2.30-5.fc29.godot.x86_64.rpm && \
    curl https://download.mono-project.com/sources/mono/mono-${mono_version}.tar.bz2 | tar xj && \
    cd mono-${mono_version} && \
    ./configure --prefix=/root/dependencies/mono-64 --host=x86_64-w64-mingw32 --disable-boehm --disable-mcs-build --disable-executables && \
    echo '#define HAVE_STRUCT_SOCKADDR_IN6 1' >> config.h && \
    make -j && \
    make install && \
    make distclean && \
    cp /root/dependencies/mono-64/bin/libMonoPosixHelper.dll /root/dependencies/mono-64/bin/MonoPosixHelper.dll && \
    rm -f /root/dependencies/mono-64/bin/mono /root/dependencies/mono-64/bin/mono-sgen && \
    ln -s /usr/bin/mono /root/dependencies/mono-64/bin/mono && \
    ln -s /usr/bin/mono-sgen /root/dependencies/mono-64/bin/mono-sgen && \
    ln -sf /usr/lib/mono/* /root/dependencies/mono-64/lib/mono || /bin/true && \
    cp -rvp /etc/mono /root/dependencies/mono-64/etc && \
    ./configure --prefix=/root/dependencies/mono-32 --host=i686-w64-mingw32 --disable-boehm --disable-mcs-build --disable-executables && \
    echo '#define HAVE_STRUCT_SOCKADDR_IN6 1' >> config.h && \
    make -j && \
    make install && \
    make distclean && \
    cp /root/dependencies/mono-32/bin/libMonoPosixHelper.dll /root/dependencies/mono-32/bin/MonoPosixHelper.dll && \
    rm -f /root/dependencies/mono-32/bin/mono /root/dependencies/mono-32/bin/mono-sgen && \
    ln -s /usr/bin/mono /root/dependencies/mono-32/bin/mono && \
    ln -s /usr/bin/mono-sgen /root/dependencies/mono-32/bin/mono-sgen && \
    ln -sf /usr/lib/mono/* /root/dependencies/mono-32/lib/mono || /bin/true && \
    cp -rvp /etc/mono /root/dependencies/mono-32/etc && \
    rm -rf /root/mono-${mono_version}

ENV MONO32_PREFIX=/root/dependencies/mono-32
ENV MONO64_PREFIX=/root/dependencies/mono-64

CMD ['/bin/bash']
