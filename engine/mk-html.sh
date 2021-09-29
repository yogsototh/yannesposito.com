#!/usr/bin/env bash
set -eu

cd "$(git rev-parse --show-toplevel)" || exit 1
template="$1"
luafilter="$2"
luafilterimg="$3"
orgfile="$4"
htmlfile="$5"

tocoption=""
if grep -ie '^#+options:' "$orgfile" | grep 'toc:t'>/dev/null; then
    tocoption="--toc"
fi

set -x
pandoc $tocoption \
       --template="$template" \
       --lua-filter="$luafilter" \
       --lua-filter="$luafilterimg" \
       --mathml \
       --from org \
       --to html5 \
       --standalone \
       $orgfile \
       --output "$htmlfile"
