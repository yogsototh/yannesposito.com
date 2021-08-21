#!/bin/zsh

cd "$(git rev-parse --show-toplevel)" || exit 1
source ./engine/envvars.sh
make -j $(getconf _NPROCESSORS_ONLN)
