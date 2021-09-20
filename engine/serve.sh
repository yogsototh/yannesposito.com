#!/usr/bin/env bash

cd "$(git rev-parse --show-toplevel)" || exit 1

webdir="_site"
echo "Serving: $webdir on http://localhost:3077" && \
lighttpd -f ./engine/lighttpd.conf -D
