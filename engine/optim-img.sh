#!/usr/bin/env zsh

src="$1"
dst="$2"

sizeof() {
    stat --format="%s" "$*"
}


convert "$src" -resize 800x800\> "$dst"

before=$(sizeof $src)

if [[ "${src:e}" == "gif" ]]; then
  after=$(sizeof $dst)
  dest=$dst
else
  cwebp "$dst" -quiet -o "$dst.webp"
  after=$(sizeof $dst.webp)
  dest=$dst.webp
fi


if (( before <= after )); then
  cp -f "$src" "$dst"
  print -- "[0%] cp $before => $before"
else
  gain=$(( ( (before - after) * 100 ) / before ))
  print -- "[$gain%] convert $before => $after"
fi

