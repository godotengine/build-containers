FROM fedora:40

WORKDIR /root

ENV DOTNET_NOLOGO=1
ENV DOTNET_CLI_TELEMETRY_OPTOUT=1

RUN dnf -y install --setopt=install_weak_deps=False \
      bash bzip2 curl file findutils gettext git make nano patch pkgconfig python3-pip unzip which xz \
      dotnet-sdk-8.0 && \
    pip install scons==4.8.0

CMD /bin/bash
