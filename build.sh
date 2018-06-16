#!/bin/bash

# Arguments: builddir buildarch cflags ldflags armfp

set -ex
cd v8

v8arch=${2:-x64}
builddir=${1:-out.gn/$v8arch.release}

split_cflags=
for i in $3; do split_cflags+="\"$i\", "; done
split_ldflags=
for j in $4; do split_ldflags+="\"$j\", "; done

v8conf="v8_target_cpu=\"$v8arch\" \
v8_static_library=true \
v8_extra_library_files=[] \
v8_experimental_extra_library_files=[] \
use_sysroot=false \
use_udev=false \
use_gold=false \
use_glib=false \
use_dbus=false \
use_custom_libcxx=false \
symbol_level=1 \
linux_use_bundled_binutils=false \
is_desktop_linux=true \
is_debug=false \
is_component_build=false \
is_clang=false \
distro_ldflags=[ $split_ldflags ] \
distro_cflags=[ \"-O2\", $split_cflags ]"

if [ "$5" ]; then
    v8conf="$v8conf arm_float_abi=\"$5\""
fi

export PATH=$(pwd)/depot_tools:$PATH
CHROMIUM_BUILDTOOLS_PATH=./buildtools/ gn gen $builddir --args="$v8conf"
mkdir -p $builddir/gen/shim_headers/icui18n_shim/third_party/icu/source/i18n/unicode
mkdir -p $builddir/gen/shim_headers/icuuc_shim/third_party/icu/source/common/unicode
ninja -vvv -C $builddir -j2
