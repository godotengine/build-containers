#!/bin/bash

if [ "${WINE_BITS}" == "64" ]; then
  export WINEPATH="/usr/x86_64-w64-mingw32/sys-root/mingw/bin/"
else
  export WINEPATH="/usr/i686-w64-mingw32/sys-root/mingw/bin/"
fi

echo -e '#!/bin/bash\n'"wine${WINE_BITS}"' $(dirname $0)/mono-sgen.exe "$@"' > mono/mini/mono
chmod +x mono/mini/mono

mkdir -p .bin
echo -e '#!/bin/bash\necho $@ | awk "{print \$NF}"' > .bin/cygpath
chmod +x .bin/cygpath
export PATH="$(pwd)/.bin/:$PATH"

./autogen.sh $@ --disable-boehm --with-mcs-docs=no HOST_PROFILE=win32
echo '#define HAVE_STRUCT_SOCKADDR_IN6 1' >> config.h
pushd mcs/jay
make -j CC=gcc
popd

for dir in external/roslyn-binaries/Microsoft.Net.Compilers/[0-9]*; do
  MONO_PATH="$(winepath -w $(pwd)/${dir});${MONO_PATH}"
done
export MONO_PATH

make -j
make install
