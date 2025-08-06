#!/usr/bin/env bash
set -eu

cd "$(git rev-parse --show-toplevel)" || exit 1
orgfile="$1"
pdffile="$2"

tocoption=""
if grep -ie '^#+options:' "$orgfile" | grep 'toc:t'>/dev/null; then
    tocoption="--toc"
fi

set -x
pandoc $tocoption \
       --from org \
       --to latex \
       --pdf-engine=xelatex \
       $orgfile \
       --output "$pdffile"
