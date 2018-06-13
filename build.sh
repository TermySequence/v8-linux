#!/bin/bash

# Arguments: buildarch cflags ldflags armfp

set -ex
cd v8

v8arch=${1:-x64}

v8conf="use_sysroot=false use_gold=false linux_use_bundled_binutils=false \
clang_use_chrome_plugins=false libcpp_is_static=true \
v8_use_external_startup_data=false v8_target_cpu=\"$v8arch\" is_clang=false"

if [ "$4" ]; then
    v8conf="$v8conf arm_float_abi=\"$4\""
fi

SPLITOPTFLAGS=""
for i in $2; do
	SPLITOPTFLAGS+="\"$i\", "
done
export SPLITOPTFLAGS

SPLITLDFLAGS=""
for j in $3; do
	SPLITLDFLAGS+="\"$j\", "
done
export SPLITLDFLAGS

pushd build/config/compiler
cp BUILD.gn.in BUILD.gn
sed -i "s|\"\$OPTFLAGS\"|$SPLITOPTFLAGS|g" BUILD.gn
sed -i "s|\"\$OPTLDFLAGS\"|$SPLITLDFLAGS|g" BUILD.gn
popd

cp -r gn tools
(cd tools/gn/ && ./bootstrap/bootstrap.py -s)
mkdir -p buildtools/linux64
cp -a out/Release/gn buildtools/linux64/gn

export PATH=$PATH:$(pwd)/depot_tools
CHROMIUM_BUILDTOOLS_PATH=./buildtools/ gn gen out.gn/$v8arch.release --args="$v8conf"
mkdir -p out.gn/$v8arch.release/gen/shim_headers/icui18n_shim/third_party/icu/source/i18n/unicode
mkdir -p out.gn/$v8arch.release/gen/shim_headers/icuuc_shim/third_party/icu/source/common/unicode
ninja -vvv -C out.gn/$v8arch.release -j2
