FROM ubuntu:trusty

ARG mono_version

RUN if [ -z "${mono_version}" ]; then echo -e "\n\nargument mono-version is mandatory!\n\n"; exit 1; fi

RUN apt-get update && \
    apt-get -y install wget && \
    cd /root && \
    wget -O- 'https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x1E9377A2BA9EF27F' | apt-key add - && \
    wget -O- 'https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x8E51A6D660CD88D67D65221D90BD7EACED8E640A' | apt-key add - && \
    echo 'deb http://ppa.launchpad.net/ubuntu-toolchain-r/test/ubuntu trusty main' >> /etc/apt/sources.list && \
    echo 'deb http://ppa.launchpad.net/mc3man/trusty-media/ubuntu trusty main' >> /etc/apt/sources.list && \
    apt-get update && \
    apt-get install -y gcc-8 g++-8 libudev-dev libx11-dev libxcursor-dev libxrandr-dev libasound2-dev libpulse-dev \
            libfreetype6-dev libgl1-mesa-dev libglu1-mesa-dev libxi-dev libxinerama-dev git scons cmake perl make bzip2 yasm && \
    ln -sf /usr/bin/gcc-ranlib-8 /usr/bin/gcc-ranlib && \
    ln -sf /usr/bin/gcc-ar-8 /usr/bin/gcc-ar && \
    ln -sf /usr/bin/gcc-8 /usr/bin/gcc && \
    ln -sf /usr/bin/g++-8 /usr/bin/g++ && \
    wget -O- https://download.mono-project.com/sources/mono/mono-${mono_version}.tar.bz2 | tar xj && \
    cd mono-${mono_version} && \
    ./configure --prefix=/usr --sysconfdir=/etc --localstatedir=/var/lib/mono --disable-boehm --host=x86_64-linux-gnu && \
    make -j && \
    make install && \
    cert-sync /etc/ssl/certs/ca-certificates.crt && \
    wget https://download.mono-project.com/repo/ubuntu/pool/main/m/msbuild/msbuild_16.0+xamarinxplat.2018.09.26.17.53-0xamarin3+ubuntu1404b1_all.deb && \
    wget https://download.mono-project.com/repo/ubuntu/pool/main/c/core-setup/msbuild-libhostfxr_2.0.0.2017.07.06.00.01-0xamarin21+ubuntu1404b1_amd64.deb && \
    wget https://download.mono-project.com/repo/ubuntu/pool/main/m/msbuild/msbuild-sdkresolver_16.0+xamarinxplat.2018.09.26.17.53-0xamarin3+ubuntu1404b1_all.deb && \
    wget https://download.mono-project.com/repo/ubuntu/pool/main/n/nuget/nuget_4.7.0.5148.bin-0xamarin2+ubuntu1404b1_all.deb && \
    dpkg -i --force-all *.deb && \
    sed -i '/Depends.*mono/d' /var/lib/dpkg/status && \
    ln -s /usr/bin/mono /usr/bin/cli && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/ && \
    rm *.deb && \
    rm -rf /root/mono-${mono_version}

ENV MONO32_PREFIX=/usr
ENV MONO64_PREFIX=/usr

CMD ['/bin/bash']
