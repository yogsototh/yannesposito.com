#!/usr/bin/env zsh

src="$1"
dst="$2"

sizeof() {
    stat --format="%s" "$*"
}

amount=0.33
s1=$( echo "100 * $amount" | bc -l )
s2=$( echo "100 / $amount" | bc -l )
# convert "$src" -resize 800x800\> -scale $s1% -scale $s2% -quality 50 "$dst"
convert "$src" -resize 800x800\> -ordered-dither o8x8,6 -colors 15 -quality 50 "$dst"

before=$(sizeof $src)
after=$(sizeof $dst)
gain=$(( ( (before - after) * 100 ) / before ))
print -- "$before => $after [$gain%])"
