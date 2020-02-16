#!/usr/bin/env bash

cd "$(git rev-parse --show-toplevel)" || exit 1

if (( $# == 0 )); then
    webdir="_site"
else
    webdir="$1"
fi

cd $webdir && \
echo "Serving: $webdir" && \
sws -d --port 3001 .
