#!/usr/bin/env zsh
cd "$(git rev-parse --show-toplevel)" || exit 1
echo "Watching $PWD/src"
# fswatch --exclude='\\.#' src | while read event; do
fswatch --exclude='^.*\.#.*$' src | while read event; do
    echo "$event"
    ./build.sh fast
done
