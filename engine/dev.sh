#!/usr/bin/env zsh
cd "$(git rev-parse --show-toplevel)" || exit 1
tmux \
    new-session './engine/auto-build.sh' \; \
    split-window './engine/serve.sh' \; \
    split-window 'lorri watch' \; \
    select-layout even-vertical
