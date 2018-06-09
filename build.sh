#!/bin/bash

# Arguments: buildarch cflags ldflags ninja armabi

set -ex
cd v8

v8arch=${1:-x64}
ninja=${4:-/usr/bin/ninja}
armabi=${5:hard}

v8conf="use_sysroot=false use_gold=false linux_use_bundled_binutils=false \
is_component_build=true clang_use_chrome_plugins=false libcpp_is_static=true \
v8_use_external_startup_data=false v8_target_cpu=\"$v8arch\" is_clang=false \
arm_float_abi=\"$armabi\""

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

sed -i "s|\"\$OPTFLAGS\"|$SPLITOPTFLAGS|g" build/config/compiler/BUILD.gn
sed -i "s|\"\$OPTLDFLAGS\"|$SPLITLDFLAGS|g" build/config/compiler/BUILD.gn

(cd tools/gn/ && ./bootstrap/bootstrap.py -s)
rm -rf buildtools/linux64/gn*
cp -a out/Release/gn buildtools/linux64/gn

rm -rf depot_tools/ninja
ln -s "$ninja" depot_tools/ninja

export PATH=$PATH:$(pwd)/depot_tools
CHROMIUM_BUILDTOOLS_PATH=./buildtools/ gn gen out.gn/$v8arch.release --args="$v8conf"
mkdir -p out.gn/$v8arch.release/gen/shim_headers/icui18n_shim/third_party/icu/source/i18n/unicode
mkdir -p out.gn/$v8arch.release/gen/shim_headers/icuuc_shim/third_party/icu/source/common/unicode
depot_tools/ninja -vvv -C out.gn/$v8arch.release -j2
