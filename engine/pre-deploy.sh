#!/usr/bin/env bash

cd "$(git rev-parse --show-toplevel)" || exit 1
echo "Optim HTML size"
./engine/optim-html.sh
echo "Gen themes clones"
./engine/dup-for-themes.sh
echo "Optim Classes accross CSS/HTML"
./engine/optim-classes.sh
echo "Update file size"
./engine/update-file-size.sh
echo "Building RSS"
./engine/mkrss.sh
