#!/bin/bash
set -e
tmux \
  new-session './engine/serve.sh' \; \
  split-window './engine/auto-build.sh' \;

