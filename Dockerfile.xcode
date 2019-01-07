FROM godot-fedora:latest

RUN dnf -y install autoconf automake libtool clang cmake fuse fuse-devel git patch make libxml2-devel libicu-devel compat-openssl10-devel bzip2-devel kmod xz cpio && \
    git clone https://github.com/mackyle/xar.git && \
    cd xar/xar && \
    ./autogen.sh --prefix=/usr && \
    make -j && make install && \
    cd /root && \
    git clone https://github.com/NiklasRosenstein/pbzx && \
    cd pbzx && \
    clang -O3 -llzma -lxar -I /usr/local/include pbzx.c -o pbzx

CMD mkdir -p /root/xcode && \
    cd /root/xcode && \
    xar -xf /root/files/Xcode_9.2.xip && \
    /root/pbzx/pbzx -n Content | cpio -i && \
    cp -r Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk /tmp/MacOSX10.13.sdk && \
    cp -r Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/include/c++/v1 /tmp/MacOSX10.13.sdk/usr/include/c++ && \
    mkdir -p mkdir -p /tmp/MacOSX10.13.sdk/usr/share/man && \
    cp -rf Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/share/man/man1 \
           Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/share/man/man3 \
           Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/share/man/man5 /tmp/MacOSX10.13.sdk/usr/share/man && \
    cd /tmp && \
    tar -cJf /root/files/MacOSX10.13.sdk.tar.xz MacOSX10.13.sdk && \
    rm -rf MacOSX10.13 && \
    cd /root/xcode && \
    cp -r Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk /tmp/iPhoneOS11.2.sdk && \
    cp -r Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/include/c++/v1 /tmp/iPhoneOS11.2.sdk/usr/include/c++ && \
    cd /tmp && \
    tar -cJf /root/files/iPhoneOS11.2.sdk.tar.xz iPhoneOS11.2.sdk && \
    rm -rf iPhoneOS11.2.sdk && \
    cd /root/xcode && \
    cp -r Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk /tmp/iPhoneOS11.2.sdk && \
    cp -r Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/include/c++/v1 /tmp/iPhoneOS11.2.sdk/usr/include/c++ && \
    cd /tmp && \
    tar -cJf /root/files/iPhoneSimulator11.2.sdk.tar.xz iPhoneOS11.2.sdk

