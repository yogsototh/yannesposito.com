#!/usr/bin/env bash

cd "$(git rev-parse --show-toplevel)" || exit 1
rootdir=${0:h}
echo "$rootdir"

./engine/clean.sh
./engine/build.sh
./engine/pre-deploy.sh
./engine/sync.sh
