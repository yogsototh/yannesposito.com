#!/usr/bin/env bash

echo "Optim HTML size"
./optim-html.sh
echo "Gen themes clones"
./dup-for-themes.sh
echo "Optim Classes accross CSS/HTML"
./optim-classes.sh
echo "Update file size"
./update-file-size.sh
echo "Building RSS"
./mkrss.sh
