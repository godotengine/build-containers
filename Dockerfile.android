FROM godot-fedora:latest

RUN dnf -y install scons java-1.8.0-openjdk-devel ncurses-compat-libs unzip which gcc gcc-c++ && \
    curl -LO https://dl.google.com/android/repository/sdk-tools-linux-4333796.zip && \
    unzip sdk-tools-linux-4333796.zip && \
    rm sdk-tools-linux-4333796.zip && \
    yes | tools/bin/sdkmanager --licenses && \
    tools/bin/sdkmanager ndk-bundle 'platforms;android-23' 'build-tools;19.1.0' 'build-tools;28.0.3' 'platforms;android-28' 

ENV ANDROID_HOME=/root/
ENV ANDROID_NDK_ROOT=/root/ndk-bundle/

CMD ['/bin/bash']
