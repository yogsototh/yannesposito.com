#!/usr/bin/env zsh

set -e # fail on first error
set -u # fail if a variable is not set

cd "$(git rev-parse --show-toplevel)" || exit 1
rootdir="${0:h}"
echo "$rootdir"

./engine/build.sh full
./engine/sync.sh
