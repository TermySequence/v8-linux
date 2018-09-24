#!/bin/bash

set -e

if [ "$JOBS" ]; then jobs="-j$JOBS"; fi
if [ "$VERBOSE" = 1 ]; then
    echo -e "Starting V8_gn build...\n" \
	 "CC=$CC\n" \
	 "CXX=$CXX\n" \
	 "LD=$LD\n" \
	 "AR=$AR"
    verbose=-v;
    set -x;
fi

# Ignore external flags, this is only a build tool
export CFLAGS=
export CXXFLAGS=
export LDFLAGS=

cd gn
python2 build/gen.py --no-sysroot --no-last-commit-position

# The job limit is intended to reduce memory usage
# (OOM's have been seen on distro build systems)
ninja $verbose -C out $jobs
