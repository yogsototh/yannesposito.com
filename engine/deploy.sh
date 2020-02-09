#!/usr/bin/env zsh

cd $(git rev-parse --show-toplevel)
rootdir=${0:h}
echo $rootdir

./engine/clean.sh
./engine/build.sh
./engine/pre-deploy.sh
./engine/sync.sh
