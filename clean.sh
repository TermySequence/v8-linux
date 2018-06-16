#!/bin/bash

set -ex
cd v8

rm -rf tools/gn
rm -rf buildtools/linux64
rm -rf out out.gn

find . -name \*.pyc -delete
