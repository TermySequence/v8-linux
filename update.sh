#!/bin/bash

set -e

vers=6.7.18
tools_vers=7e7a454f9afdddacf63e10be48f0eab603be654e
base_vers=2d35e4d
gn_vers=f833e90

if [ "$1" = "--help" ]; then
    echo 'Usage: update.sh [--fetch]'
    exit
fi

if [ ! -x update.sh ]; then
    echo 'Run me from the v8-linux directory' 1>&2
    exit 1
fi

if [ "$1" = "--fetch" ]; then
    rm -rf scratch
    mkdir scratch
    pushd scratch

    # v8
    mkdir v8-tmp
    cd v8-tmp
    fetch v8
    cd v8
    git checkout $vers
    gclient sync
    cd ../..
    mv v8-tmp/v8 .

    # depot_tools
    if [ -z "$tools_vers" ]; then
        git clone --depth=1 https://chromium.googlesource.com/chromium/tools/depot_tools.git
        tools_vers=HEAD
    else
        git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git
    fi
    mkdir -p v8/depot_tools
    (cd depot_tools; git archive "$tools_vers") | tar xf - -C v8/depot_tools

    # chromium_base
    if [ -z "$base_vers" ]; then
        git clone --depth=1 https://chromium.googlesource.com/chromium/src/base
        base_vers=HEAD
    else
        git clone https://chromium.googlesource.com/chromium/src/base
    fi
    mkdir -p v8/base
    (cd base; git archive "$base_vers") | tar xf - -C v8/base

    # gn
    if [ -z "$gn_vers" ]; then
        git clone --depth=1 https://chromium.googlesource.com/chromium/src/tools/gn
        gn_vers=HEAD
    else
        git clone https://chromium.googlesource.com/chromium/src/tools/gn
    fi
    mkdir -p v8/tools/gn
    (cd gn; git archive "$gn_vers") | tar xf - -C v8/tools/gn

    popd
fi

rm -rf v8
cp -r scratch/v8 .

# Exclusions
pushd v8
# Remove .gitignore files
find . -type f -name .gitignore -delete
# Remove .git folders
find . -type d -name .git -print -prune | xargs rm -rf
# Remove *all* binary files
find . -type f -size +0c -print0 | perl -n0 -e 'chomp($a = $_); print if -B $a' | xargs -0 rm

rm -rf depot_tools/man
rm -f depot_tools/ninja*
rm -rf depot_tools/recipes
rm -rf depot_tools/testing_support
rm -rf depot_tools/tests
rm -rf depot_tools/third_party
rm -rf depot_tools/win_toolchain
rm -rf depot_tools/zsh-goodies

rm -rf build/android
rm -rf build/fuschia
rm -rf build/linux
rm -rf build/mac
rm -rf build/win

# No tests
rm -rf test

# ICU source only
pushd third_party/icu
for i in *; do
    if [ "$i" != source -a -d "$i" ]; then rm -rf "$i"; fi
done
cd source
for i in *; do
    if [ "$i" != i18n -a "$i" != common ]; then rm -rf "$i"; fi
done
popd

rm -rf third_party/binutils
rm -rf third_party/depot_tools
rm -rf third_party/googletest
rm -rf third_party/instrumented_libraries
rm -rf third_party/llvm-build

rm -rf tools/clang
rm -rf tools/luci-go
rm -rf tools/profviz
rm -rf tools/swarming_client
rm -rf tools/gyp/test

popd

git add v8
git commit -m "Upstream $vers with exclusions

tools: $tools_vers
base:  $base_vers
gn:    $gn_vers" -- v8
