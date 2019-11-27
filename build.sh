#!/usr/bin/env bash

emacs \
  --load project.el \
  --eval "(progn (org-publish \"blog\" t) (evil-quit))"

echo "Update file size"
./update-file-size.sh
echo "Gen themes clones"
./dup-for-themes.sh
echo "Building RSS"
./mkrss.sh
echo "RSS Built"
