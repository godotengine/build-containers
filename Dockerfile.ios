FROM godot-fedora:latest

RUN dnf -y install automake autoconf clang gcc gcc-c++ gcc-objc gcc-objc++ cmake git libicu-devel libtool libxml2-devel llvm-devel make openssl-devel patch perl python scons xz yasm && \
    git clone https://github.com/tpoechtrager/cctools-port.git && \
    cd /root/cctools-port && \
    sed -i 's#./autogen.sh#libtoolize -c -i --force\n./autogen.sh#' usage_examples/ios_toolchain/build.sh && \
    usage_examples/ios_toolchain/build.sh /root/files/iPhoneOS11.2.sdk.tar.xz arm64 && \
    mkdir -p /root/ioscross/arm64 && \
    mv usage_examples/ios_toolchain/target/* /root/ioscross/arm64 && \
    mkdir /root/ioscross/arm64/usr && \
    ln -s /root/ioscross/arm64/bin /root/ioscross/arm64/usr/bin && \
    sed -i 's#^TRIPLE=.*#TRIPLE="x86_64-apple-darwin11"#' usage_examples/ios_toolchain/build.sh && \
    usage_examples/ios_toolchain/build.sh /root/files/iPhoneSimulator11.2.sdk.tar.xz x86_64 && \
    mkdir -p /root/ioscross/x86_64 && \
    mv usage_examples/ios_toolchain/target/* /root/ioscross/x86_64 && \
    mkdir /root/ioscross/x86_64/usr && \
    ln -s /root/ioscross/x86_64/bin /root/ioscross/x86_64/usr/bin

ENV OSXCROSS_IOS=not_nothing

CMD ['/bin/bash']
