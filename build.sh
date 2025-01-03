#!/bin/sh
set -e
HERE="$(dirname "$(readlink -f "$0")")"
cd "$HERE"

WITH_UPX=1
VENDOR_UPX=1

platform="$(uname -s)"
platform_arch="$(uname -m)"
export MAKEFLAGS="-j$(nproc)"

if [ "$platform" == "Linux" ]
    then
        export CFLAGS="-static"
        export LDFLAGS='--static'
    else
        echo "= WARNING: your platform does not support static binaries."
        echo "= (This is mainly due to non-static libc availability.)"
        exit 1
fi

if [ -x "$(which apk 2>/dev/null)" ]
    then
        apk add git gcc make musl-dev autoconf automake libtool ninja \
            linux-headers meson cmake pkgconfig libcap-dev \
            libxslt clang patch upx bash-completion
fi

if [ "$WITH_UPX" == 1 ]
    then
        if [[ "$VENDOR_UPX" == 1 || ! -x "$(which upx 2>/dev/null)" ]]
            then
                upx_ver=4.2.4
                case "$platform_arch" in
                   x86_64) upx_arch=amd64 ;;
                   aarch64) upx_arch=arm64 ;;
                esac
                wget https://github.com/upx/upx/releases/download/v${upx_ver}/upx-${upx_ver}-${upx_arch}_linux.tar.xz
                tar xvf upx-${upx_ver}-${upx_arch}_linux.tar.xz
                mv upx-${upx_ver}-${upx_arch}_linux/upx /usr/bin/
                rm -rf upx-${upx_ver}-${upx_arch}_linux*
        fi
fi

if [ -d build ]
    then
        echo "= removing previous build directory"
        rm -rf build
fi

# if [ -d release ]
#     then
#         echo "= removing previous release directory"
#         rm -rf release
# fi

echo "=  create build and release directory"
mkdir -p build
mkdir -p release

(cd build

export CFLAGS="$CFLAGS -Os -g0 -ffunction-sections -fdata-sections -fvisibility=hidden -fmerge-all-constants"
export LDFLAGS="$LDFLAGS -Wl,--gc-sections -Wl,--strip-all"

echo "= build static deps"
(export CC=gcc

[ -d "/usr/lib/$platform_arch-linux-gnu" ] && \
    libdir="/usr/lib/$platform_arch-linux-gnu/"||\
    libdir="/usr/lib/"

echo "= build libcap lib"
(git clone git://git.kernel.org/pub/scm/libs/libcap/libcap.git && cd libcap/libcap
make libcap.a
mv -fv libcap.a $libdir)
)

echo "= download bubblewrap"
git clone https://github.com/containers/bubblewrap.git
bubblewrap_version="$(cd bubblewrap && git describe --long --tags|sed 's/^v//;s/\([^-]*-g\)/r\1/;s/-/./g')"
bubblewrap_dir="${HERE}/build/bubblewrap-${bubblewrap_version}"
mv "bubblewrap" "bubblewrap-${bubblewrap_version}"
echo "= bubblewrap v${bubblewrap_version}"

echo "= build bubblewrap"
(cd "${bubblewrap_dir}"
export CC=gcc

patch<"$HERE/caps.patch"
meson build -D selinux=disabled
ninja -C build bwrap.p/bubblewrap.c.o bwrap.p/bind-mount.c.o bwrap.p/network.c.o bwrap.p/utils.c.o
(cd build && \
"$CC" $CFLAGS $LDFLAGS -o bwrap bwrap.p/bubblewrap.c.o bwrap.p/bind-mount.c.o bwrap.p/network.c.o bwrap.p/utils.c.o \
    -static -L/usr/lib -lcap)
)

echo "= extracting bubblewrap binaries and libraries"
mv -fv "${bubblewrap_dir}"/build/bwrap "$HERE"/release/bwrap-${platform_arch}
)

echo "= build super-strip"
(cd build && git clone https://github.com/aunali1/super-strip.git && cd super-strip
make
mv -fv sstrip /usr/bin/)

echo "= super-strip release binaries"
sstrip release/*-"${platform_arch}"

if [[ "$WITH_UPX" == 1 && -x "$(which upx 2>/dev/null)" ]]
    then
        echo "= upx compressing"
        find release -name "*-${platform_arch}"|\
        xargs -I {} upx --force-overwrite -9 --best {} -o {}-upx
fi

if [ "$NO_CLEANUP" != 1 ]
    then
        echo "= cleanup"
        rm -rfv build
fi

echo "= bubblewrap done"
