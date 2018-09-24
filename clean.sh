#!/bin/bash

v8arch=${ARCH:-x64}
builddir=${BUILDDIR:-out.gn/$v8arch.release}

set -ex

pushd v8
rm -rf $builddir
rm -rf out.gn
find . -name \*.pyc -delete
popd

pushd gn
rm -rf out
popd
