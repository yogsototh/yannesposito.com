#!/usr/bin/env bash

cd "$(git rev-parse --show-toplevel)" || exit 1
echo "Copying to optim dir"
find _optim -mindepth 1 -delete && cp -r _site _optim
echo "Optim HTML size"
./engine/optim-html.sh
# echo "Gen themes clones"
# ./engine/dup-for-themes.sh
echo "Optim Classes accross CSS/HTML"
./engine/optim-classes.sh
echo "Update file size"
./engine/update-file-size.sh
echo "Building RSS"
./engine/mkrss.sh
