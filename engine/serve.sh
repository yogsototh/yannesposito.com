#!/usr/bin/env bash

cd "$(git rev-parse --show-toplevel)" || exit 1
cd _site && sws -d --port 3001 .
