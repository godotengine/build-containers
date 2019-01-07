FROM godot-fedora:latest

ARG mono_version

RUN if [ -z "${mono_version}" ]; then echo -e "\n\nargument mono-version is mandatory!\n\n"; exit 1; fi

RUN dnf -y install cmake gcc gcc-c++ make which perl python curl bzip2 && dnf clean all && \
    curl https://download.mono-project.com/sources/mono/mono-${mono_version}.tar.bz2 | tar xj && \
    cd mono-${mono_version} && \
    ./configure --prefix=/usr --sysconfdir=/etc --localstatedir=/var/lib/mono --disable-boehm && make -j && make install && make distclean && \
    cd /root && \
    rm -rf mono-${mono_version} && \
    cert-sync /etc/pki/tls/certs/ca-bundle.crt && \
    rpm -ivh --nodeps https://download.mono-project.com/repo/centos7-stable/m/msbuild/msbuild-16.0+xamarinxplat.2018.09.26.17.53-0.xamarin.3.epel7.noarch.rpm \
                      https://download.mono-project.com/repo/centos7-stable/m/msbuild-libhostfxr/msbuild-libhostfxr-2.0.0.2017.07.06.00.01-0.xamarin.1.epel7.x86_64.rpm \
                      https://download.mono-project.com/repo/centos7-stable/m/msbuild/msbuild-sdkresolver-16.0+xamarinxplat.2018.09.26.17.53-0.xamarin.3.epel7.noarch.rpm \
                      https://download.mono-project.com/repo/centos7-stable/n/nuget/nuget-4.7.0.5148.bin-0.xamarin.1.epel7.noarch.rpm

