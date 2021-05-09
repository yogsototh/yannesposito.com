#!/usr/bin/env bash
set -eu

cd "$(git rev-parse --show-toplevel)" || exit 1
css="$1"
template="$2"
orgfile="$3"
htmlfile="$4"

tocoption=""
if grep -ie '^#+options:' "$orgfile" | grep 'toc:t'>/dev/null; then
    tocoption="--toc"
fi

set -x
pandoc -c "$css" $tocoption \
       --template="$template" \
       --mathml \
       --from org \
       --to html5 \
       --standalone \
       $orgfile \
       --output "$htmlfile"
