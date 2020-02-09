#!/usr/bin/env bash

cd $(git rev-parse --show-toplevel)
echo -n "* Clean site cache"
rm -rf _site
rm -rf _cache
echo " [done]"
