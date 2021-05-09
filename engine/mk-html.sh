#!/usr/bin/env bash
set -eu

cd "$(git rev-parse --show-toplevel)" || exit 1
template="$1"
orgfile="$2"
htmlfile="$3"

tocoption=""
if grep -ie '^#+options:' "$orgfile" | grep 'toc:t'>/dev/null; then
    tocoption="--toc"
fi

set -x
pandoc $tocoption \
       --template="$template" \
       --mathml \
       --from org \
       --to html5 \
       --standalone \
       $orgfile \
       --output "$htmlfile"
