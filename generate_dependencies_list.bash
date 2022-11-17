#!/bin/bash

# Generate a list of package dependencies to copy & paste into the Dockerfile 

# To get the list of libraries:
#   (inside docker): $ ldd losslesscut |grep not\ found | awk '{print $1}'
# To get the list of library packages on a Debian host with all of them installed:
#   $ ldd losslesscut | grep -v libffmpeg.so | awk '{print $3}' | xargs realpath | LC_ALL=C xargs dpkg -S 2>/dev/null | cut -d: -f1

if [[ -z $1 ]]; then
    echo "Usage: $0 <binary>" >&2
    exit 1
fi

ldd $1 \
    | grep -v libffmpeg.so \
    | awk '{print $3}' \
    | xargs realpath \
    | LC_ALL=C xargs dpkg -S 2>/dev/null \
    | cut -d: -f1 \
    | sort \
    | uniq \
    | sed -e 's/^/      /' -e 's/$/ \\/'
