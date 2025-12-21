#!/usr/bin/env zsh

autoload -U colors && colors

src="$1"
dst="$2"

sizeof() {
    stat --format="%s" "$*"
}


magick "$src" -resize 860x860\> "$dst"

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
  print -- "${fg[red]}[ 0%]${reset_color} (${src:t}) cp $before => $before"
else
  gain=$(( ( (before - after) * 100 ) / before ))
  if (( gain < 10 )) then
     print -n -- "${fg[red]}[ $gain%]${reset_color} (${src:t}) "
  elif (( gain < 20 )) then
       print -n -- "${fg[yellow]}[$gain%]${reset_color} (${src:t}) "
  else
      print -n -- "${fg[green]}[$gain%]${reset_color} "
  fi
  print -- "convert $before => $after"
fi

