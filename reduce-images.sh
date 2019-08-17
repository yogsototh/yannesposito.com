#!/usr/bin/env zsh
for fic in src/**/*.{jpg,png,gif}(N.); do
    tmp="temp.${fic:e}"
    echo "$fic"
    cp $fic $tmp
    convert $tmp -resize 800x800\> $fic
    rm $tmp
done
