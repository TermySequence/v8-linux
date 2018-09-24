#!/bin/bash

set -e

v8arch=${ARCH:-x64}
builddir=${BUILDDIR:-out.gn/$v8arch.release}

if [ "$JOBS" ]; then jobs="-j$JOBS"; fi
if [ "$VERBOSE" = 1 ]; then
    echo -e "Starting V8 build...\n" \
	 "ARCH=$ARCH\n" \
	 "BUILDDIR=$BUILDDIR\n" \
	 "CFLAGS=$CFLAGS\n" \
	 "LDFLAGS=$LDFLAGS\n" \
	 "CC=$CC\n" \
	 "CXX=$CXX\n" \
	 "LD=$LD\n" \
	 "AR=$AR\n" \
	 "ARMFP=$ARMFP\n" \
	 "JOBS=$JOBS"
    verbose=-v;
    set -x;
fi

split_cflags=
for i in $CFLAGS; do split_cflags+="\"$i\", "; done
split_ldflags=
for j in $LDFLAGS; do split_ldflags+="\"$j\", "; done

v8conf="v8_target_cpu=\"$v8arch\"
custom_toolchain=\"//build/toolchain/linux/unbundle:default\"
host_toolchain=\"//build/toolchain/linux/unbundle:default\"
v8_deprecation_warnings=true
v8_enable_gdbjit=false
v8_extra_library_files=[]
v8_experimental_extra_library_files=[]
v8_static_library=true
v8_untrusted_code_mitigations=false
v8_use_external_startup_data=true
v8_use_multi_snapshots=true
use_aura=false
use_custom_libcxx=false
use_dbus=false
use_gio=false
use_glib=false
use_gold=false
use_ozone=true
use_sysroot=false
use_udev=false
symbol_level=0
safe_browsing_mode=0
linux_use_bundled_binutils=false
is_desktop_linux=true
is_debug=false
is_component_build=false
is_clang=false
fieldtrial_testing_like_official_build=true
distro_ldflags=[ $split_ldflags ]
distro_cflags=[ \"-O2\", $split_cflags ]"

if [ "$ARMFP" ]; then
    v8conf="$v8conf arm_float_abi=\"$ARMFP\""
fi

cd v8
mkdir -p $builddir
../gn/out/gn gen $builddir --args="$v8conf"
mkdir -p $builddir/gen/shim_headers/icui18n_shim/third_party/icu/source/i18n/unicode
mkdir -p $builddir/gen/shim_headers/icuuc_shim/third_party/icu/source/common/unicode

# The job limit is intended to reduce memory usage
# (OOM's have been seen on distro build systems)
ninja $verbose -C $builddir $jobs
