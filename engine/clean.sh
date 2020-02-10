#!/usr/bin/env bash

cd "$(git rev-parse --show-toplevel)" || exit 1
echo -n "* Clean site cache"
rm -rf _site
rm -rf _cache
echo " [done]"
