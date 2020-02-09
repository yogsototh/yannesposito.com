#!/usr/bin/env bash

cd $(git rev-parse --show-toplevel)
cd _site && sws -d --port 3001 .
