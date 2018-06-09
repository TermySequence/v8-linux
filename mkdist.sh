#!/bin/bash

if [ -z "$1" ]; then
    echo "Usage: mkdist.sh <commit>" 1>&2
    exit 1
fi

package=$(awk '/^PackageName:/ {print $2}' LICENSE.spdx)
version=$(awk '/^PackageVersion:/ {print $2}' LICENSE.spdx)
name="${package}-${version}"

git archive --prefix=${name}/ $1 | xz > ${name}.tar.xz || exit 3

echo Success
