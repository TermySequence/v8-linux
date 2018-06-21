#!/bin/bash

# Arguments: builddir

set -ex
cd v8

if [ -d "$1" ]; then rm -rf "$1"; fi

rm -rf tools/gn
rm -rf buildtools/linux64
rm -rf out out.gn

find . -name \*.pyc -delete
