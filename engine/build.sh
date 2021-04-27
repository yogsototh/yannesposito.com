#!/bin/zsh

cd "$(git rev-parse --show-toplevel)" || exit 1
make
