ARG img_version
FROM godot-fedora:${img_version}

ENV GODOT_SDK_LINUX_X86_64=/root/x86_64-godot-linux-gnu_sdk-buildroot
ENV GODOT_SDK_LINUX_X86=/root/i686-godot-linux-gnu_sdk-buildroot
ENV GODOT_SDK_LINUX_ARMHF=/root/arm-godot-linux-gnueabihf_sdk-buildroot
ENV BASE_PATH=${PATH}

RUN dnf -y install --setopt=install_weak_deps=False \
      libxcrypt-compat yasm && \
    curl -LO https://downloads.tuxfamily.org/godotengine/toolchains/linux/2021-02-11/x86_64-godot-linux-gnu_sdk-buildroot.tar.bz2 && \
    tar xf x86_64-godot-linux-gnu_sdk-buildroot.tar.bz2 && \
    rm -f x86_64-godot-linux-gnu_sdk-buildroot.tar.bz2 && \
    cd x86_64-godot-linux-gnu_sdk-buildroot && \
    ./relocate-sdk.sh && \
    rm -f bin/{aclocal*,auto*,libtool*,m4} && \
    cd /root && \
    curl -LO https://downloads.tuxfamily.org/godotengine/toolchains/linux/2021-02-11/arm-godot-linux-gnueabihf_sdk-buildroot.tar.bz2 && \
    tar xf arm-godot-linux-gnueabihf_sdk-buildroot.tar.bz2 && \
    rm -f arm-godot-linux-gnueabihf_sdk-buildroot.tar.bz2 && \
    cd arm-godot-linux-gnueabihf_sdk-buildroot && \
    ./relocate-sdk.sh && \
    rm -f bin/{aclocal*,auto*,libtool*,m4} && \
    cd /root && \
    curl -LO https://downloads.tuxfamily.org/godotengine/toolchains/linux/2021-02-11/i686-godot-linux-gnu_sdk-buildroot.tar.bz2 && \
    tar xf i686-godot-linux-gnu_sdk-buildroot.tar.bz2 && \
    rm -f i686-godot-linux-gnu_sdk-buildroot.tar.bz2 && \
    cd i686-godot-linux-gnu_sdk-buildroot && \
    ./relocate-sdk.sh && \
    rm -f bin/{aclocal*,auto*,libtool*,m4}

CMD /bin/bash
