#!/usr/bin/env zsh

cd "$(git rev-parse --show-toplevel)" || exit 1
./engine/build.sh
./engine/sync.sh
./engine/ye-com-fastpublish.hs
