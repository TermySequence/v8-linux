#!/bin/bash

arg=$1
set -e

vers=6.9.427.27
gn_vers=091169beda92aff21ded3e9dfb392ea12b10c0e0

if [ "$arg" = "--help" ]; then
    echo 'Usage: update.sh [--fetch|--sync]'
    exit
fi
if [ ! -x update.sh ]; then
    echo 'Run me from the v8-linux directory' 1>&2
    exit 1
fi

if [ "$arg" = "--fetch" ]; then
    rm -rf scratch
    mkdir scratch
    pushd scratch

    # gn
    git clone https://gn.googlesource.com/gn

    # v8
    mkdir v8-root
    cd v8-root
    fetch v8

    popd
    arg="--sync"
fi
if [ "$arg" = "--sync" ]; then
    pushd scratch

    # gn
    (cd gn; git checkout $gn_vers)

    # v8
    cd v8-root/v8
    git checkout $vers
    gclient sync
    cd ../..
    mv v8-root/v8 .

    popd
fi

echo Removing old copy
rm -rf v8 gn
echo Copying pristine source
cp -r scratch/v8 scratch/gn .

# Generate last_commit_position.h for gn
echo Generating gn/last_commit_position.h
pushd gn
desc=$(git describe HEAD --match initial-commit)
echo "#define LAST_COMMIT_POSITION \"$desc\"" >tools/gn/last_commit_position.h
popd

# Exclusions
echo Processing exclusions
# Remove .gitignore files
find gn v8 -type f -name .gitignore -delete
# Remove .git folders
find gn v8 -type d -name .git -print -prune | xargs rm -r
# Remove *all* binary files
find gn v8 -type f -size +0c -print0 | perl -n0 -e 'chomp; print "$_\0" if -B' | xargs -0 rm
# Remove checksums
find gn v8 -type f -name \*.sha1 -delete

pushd gn
find . -name \*_unittest.cc -delete
rm -r util/test
rm -r tools/gn/format_test_data
rm build/full_test.py
rm -r infra
rm -r docs
popd

pushd v8
rm -r build/config/chromecast
rm -r build/chromeos
rm -r build/config/chromeos
rm -r build/config/aix
rm -r build/toolchain/aix
rm -r build/android
rm -r build/toolchain/android
rm -r build/fuchsia
rm -r build/config/fuchsia
rm -r build/toolchain/fuchsia
rm -r build/config/nacl
rm -r build/toolchain/nacl
rm -r build/linux
rm -r buildtools/third_party
rm -r buildtools/clang_format
rm -r buildtools/checkdeps

pushd build/secondary/third_party
for i in *; do
    if [ $i != catapult ]; then rm -r $i; fi
done
popd

rm -r infra
rm -r ChangeLog

# No tests except torque file
pushd test
for i in *; do
    if [ $i != torque ]; then rm -r $i; fi
done
popd

# ICU source only
pushd third_party/icu
for i in *; do
    if [ $i != source -a -d $i ]; then rm -r $i; fi
done
cd source
for i in *; do
    if [ $i != i18n -a $i != common ]; then rm -r $i; fi
done
cd common
for i in *; do
    if [ $i != unicode ]; then rm -r $i; fi
done
cd ../i18n
for i in *; do
    if [ $i != unicode ]; then rm -r $i; fi
done
popd

pushd third_party
for i in *; do
    if [ $i = icu ]; then continue; fi
    if [ $i = antlr4 ]; then continue; fi
    if [ $i = googletest ]; then continue; fi
    if [ $i = inspector_protocol ]; then continue; fi
    rm -rf $i
done
popd

pushd tools
for i in *; do
    if [ $i = generate_shim_headers ]; then continue; fi
    if [ $i = testrunner ]; then continue; fi
    if [ -d $i ]; then rm -r $i; fi
done
popd

rm -r benchmarks

popd

git add gn v8
git commit -m "Upstream $vers with exclusions

gn: $gn_vers" -- gn v8
