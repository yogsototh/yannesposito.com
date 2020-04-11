#!/usr/bin/env bash

cd "$(git rev-parse --show-toplevel)" || exit 1
echo -n "* Clean site cache"
find _site -not -path "_site/.gitignore" -mindepth 1 -delete
find _full -not -path "_full/.gitignore" -mindepth 1 -delete
find _optim -not -path "_optim/.gitignore" -mindepth 1 -delete
rm -rf _cache
echo " [done]"
