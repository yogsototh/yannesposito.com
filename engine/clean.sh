#!/usr/bin/env bash

cd "$(git rev-parse --show-toplevel)" || exit 1
echo -n "* Clean site cache"
find _site -mindepth 1 -not -path "_site/.gitignore" -delete
find _full -mindepth 1 -not -path "_full/.gitignore" -delete
find _optim -mindepth 1 -not -path "_optim/.gitignore" -delete
rm -rf _cache
echo " [done]"
