#!/usr/bin/env bash

export LC_ALL=C
pushd "${0%/*}" &>/dev/null

PLATFORM=$(uname -s)
OPERATING_SYSTEM=$(uname -o || echo "-")

if [ $OPERATING_SYSTEM == "Android" ]; then
  export CC="clang -D__ANDROID_API__=26"
  export CXX="clang++ -D__ANDROID_API__=26"
fi

if [ -z "$LLVM_DSYMUTIL" ]; then
    if command -v llvm-dsymutil &>/dev/null; then
        LLVM_DSYMUTIL=llvm-dsymutil
    else
        LLVM_DSYMUTIL=dsymutil
    fi
fi

if [ -z "$JOBS" ]; then
    JOBS=$(nproc 2>/dev/null || ncpus 2>/dev/null || echo 1)
fi

set -e

function verbose_cmd
{
    echo "$@"
    eval "$@"
}

function git_clone_repository
{
    local url=$1
    local branch=$2
    local directory

    directory=$(basename $url)
    directory=${directory/\.git/}

    if [ -n "$CCTOOLS_IOS_DEV" ]; then
        rm -rf $directory
        cp -r $CCTOOLS_IOS_DEV/$directory .
        return
    fi

    if [ ! -d $directory ]; then
        local args=""
        test "$branch" = "master" && args="--depth 1"
        git clone $url $args
    fi

    pushd $directory &>/dev/null

    git reset --hard
    git clean -fdx
    git checkout $branch
    git pull origin $branch

    popd &>/dev/null
}


if [ $# -lt 1 ]; then
    echo "usage: $0 <target cpu>" 1>&2
    echo "i.e. $0 arm64" 1>&2
    exit 1
fi

TARGET_CPU="$1"
if [ "$TARGET_CPU" != "arm64" ] && [ "$TARGET_CPU" != "x86_64" ]; then
    echo "target cpu must be either 'arm64' or 'x86_64'" 1>&2
    exit 1
fi

if [ "$TARGET_CPU" == "arm64" ]; then
    TRIPLE="arm-apple-darwin11"
else
    TRIPLE="x86_64-apple-darwin11"
fi

TARGETDIR="$PWD/target"

if [ -d $TARGETDIR ]; then
    echo "cleaning up ..."
    rm -rf $TARGETDIR
fi

mkdir -p $TARGETDIR
mkdir -p $TARGETDIR/bin

echo ""
echo "*** building wrapper ***"
echo ""

OK=0

set +e
version=$(echo "$($LLVM_DSYMUTIL --version 2>&1)" | grep -oP 'LLVM version \K[^\s]+')

if [ $? -eq 0 ]; then
    major_version=$(echo "$version" | awk -F'\\.' '{print $1}')
    minor_version=$(echo "$version" | awk -F'\\.' '{print $2}')
    if ((major_version > 3 || (major_version == 3 && minor_version >= 8))); then
        OK=1

        if [ "$LLVM_DSYMUTIL" == "llvm-dsymutil" ]; then
            ln -sf "$(command -v $LLVM_DSYMUTIL)" "$TARGETDIR/bin/dsymutil"
        fi
    fi
fi
set -e

if [ $OK -ne 1 ]; then
    echo "int main(){return 0;}" | cc -xc -O2 -o $TARGETDIR/bin/dsymutil -
fi

pushd $TARGETDIR/bin &>/dev/null
ln -sf $TRIPLE-lipo lipo
popd &>/dev/null

verbose_cmd cc -O2 -Wall -Wextra -pedantic wrapper.c \
    -DTARGET_CPU=\"\\\"${TARGET_CPU}\\\"\" \
    -o $TARGETDIR/bin/$TRIPLE-clang

pushd $TARGETDIR/bin &>/dev/null
verbose_cmd ln -sf $TRIPLE-clang $TRIPLE-clang++
popd &>/dev/null

rm -rf tmp
mkdir -p tmp

echo ""
echo "*** building ldid ***"
echo ""

pushd tmp &>/dev/null
git_clone_repository https://github.com/tpoechtrager/ldid.git master
pushd ldid &>/dev/null
make INSTALLPREFIX=$TARGETDIR -j$JOBS install
popd &>/dev/null
popd &>/dev/null

echo ""
echo "*** building apple-libdispatch ***"
echo ""

pushd tmp &>/dev/null
git_clone_repository https://github.com/tpoechtrager/apple-libdispatch.git main
pushd apple-libdispatch &>/dev/null
mkdir -p build
pushd build &>/dev/null
CC=clang CXX=clang++ \
    cmake .. -DCMAKE_BUILD_TYPE=RELEASE -DCMAKE_INSTALL_PREFIX=$TARGETDIR
make install -j$JOBS
popd &>/dev/null
popd &>/dev/null
popd &>/dev/null

echo ""
echo "*** building apple-libtapi ***"
echo ""

pushd tmp &>/dev/null
git_clone_repository https://github.com/tpoechtrager/apple-libtapi.git 1300.6.5
pushd apple-libtapi &>/dev/null
INSTALLPREFIX=$TARGETDIR ./build.sh
./install.sh
popd &>/dev/null
popd &>/dev/null

echo ""
echo "*** building cctools / ld64 ***"
echo ""

pushd ../../cctools &>/dev/null
git clean -fdx &>/dev/null || true
popd &>/dev/null

pushd tmp &>/dev/null
mkdir -p cctools
pushd cctools &>/dev/null
../../../../cctools/configure \
    --target=$TRIPLE \
    --prefix=$TARGETDIR \
    --with-libtapi=$TARGETDIR \
    --with-libdispatch=$TARGETDIR \
    --with-libblocksruntime=$TARGETDIR
make -j$JOBS && make install
popd &>/dev/null
popd &>/dev/null


echo ""
echo "*** all done ***"
