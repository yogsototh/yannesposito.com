#!/usr/bin/env zsh

rootdir=${0:h}
echo $rootdir

echo "Full Build"
./fullbuild.sh
echo -n "Publishing"
./sync.sh
echo " [done]"
