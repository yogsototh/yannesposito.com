#!/usr/bin/env zsh

rootdir=${0:h}
echo $rootdir

./clean.sh
./build.sh
./pre-deploy.sh
./sync.sh
