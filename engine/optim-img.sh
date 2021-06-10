#!/usr/bin/env zsh

src="$1"
dst="$2"

sizeof() {
    stat --format="%s" "$*"
}

convert "$src" -resize 800x800\> -quality 50 "$dst"

before=$(sizeof $src)
after=$(sizeof $dst)

if (( before <= after )); then
  cp -f "$src" "$dst"
  print -- "[0%] cp $before => $before"
else
  gain=$(( ( (before - after) * 100 ) / before ))
  print -- "[$gain%] convert $before => $after"
fi

