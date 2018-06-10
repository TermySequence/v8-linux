#!/bin/bash

set -ex
cd v8

rm -rf tools/gn
rm -f build/config/compiler/BUILD.gn

rm -rf buildtools/linux64
rm -rf out out.gn

find . -name \*.pyc -delete
