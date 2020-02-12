#!/usr/bin/env bash

cd "$(git rev-parse --show-toplevel)" || exit 1
echo -n "* Clean site cache"
find _site -mindepth 1 -delete
rm -rf _cache
echo " [done]"
