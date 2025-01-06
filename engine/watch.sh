#!/usr/bin/env zsh
cd "$(git rev-parse --show-toplevel)" || exit 1
[[ -f ./engine/envvars.sh ]] || make ./engine/envvars.sh
source ./engine/envvars.sh
direnv reload
./engine/build.sh
echo "Watching $PWD/{src,templates}"
# fswatch --exclude='\\.#' src | while read event; do
fswatch --exclude='^.*\.#.*$' src engine templates | while read event; do
    echo "$event"
    ./engine/build.sh
done
