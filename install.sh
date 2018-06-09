#!/bin/bash

# Arguments: buildarch libdir incdir

set -ex
cd v8

v8arch=$1
libdir=$2
incdir=$3

somajor=6

pushd out.gn/$v8arch.release
# library first
mkdir -p $libdir
cp -a libv8*.so.$somajor $libdir
popd

# Now, headers
mkdir -p $incdir
install -pm 644 include/*.h $incdir
cp -a include/libplatform $incdir

# Make shared library links
pushd $libdir
ln -sf libv8.so.$somajor libv8.so
ln -sf libv8_libplatform.so.$somajor libv8_libplatform.so
ln -sf libv8_libbase.so.$somajor libv8_libbase.so
popd
