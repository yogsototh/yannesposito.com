#!/usr/bin/env zsh
cd "$(git rev-parse --show-toplevel)" || exit 1
direnv reload
echo "Watching $PWD/{src,templates}"
# fswatch --exclude='\\.#' src | while read event; do
fswatch --exclude='^.*\.#.*$' src templates | while read event; do
    echo "$event"
    ./engine/build.sh fast
done
