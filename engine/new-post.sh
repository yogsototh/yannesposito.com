#!/usr/bin/env zsh

(( $# < 1 )) && {
   print -- "usage: ${0:t} title"
   exit 1
}

postsdir=src/posts
title="$*"
scrub=$(echo "$title" | tr '[:upper:]' '[:lower:]' | perl -pe 's/[^a-z0-9_]+/-/g;s/-+$//')

lastnumber () {
for d in "$postsdir"/*; do
    number=$(echo "${d:t}" | sed 's/-.*$//')
    echo "$number"
done | sort -n | tail -n 1
}

n=$(lastnumber)
newdir=$(printf "%04d-%s" $((n+1)) "$scrub")
dst="$postsdir/$newdir/index.org"
today=$(date +"[%Y-%m-%d]")

mkdir "${dst:h}"
cat > "$dst" <<EOF
#+title: $title
#+description:
#+keywords: blog static
#+author: Yann Esposito
#+email: yann@esposito.host
#+date: $today
#+lang: en
#+options: auto-id:t
#+startup: showeverything

EOF
