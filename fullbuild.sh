#!/usr/bin/env bash

rm -rf _site
rm -rf _cache

emacs \
  --load project.el \
  --eval "(progn (delete-directory org-publish-timestamp-directory t) (org-publish \"blog\" t) (evil-quit))"

echo "Update file size"
./update-file-size.sh
echo "Gen themes clones"
./dup-for-themes.sh
echo "Building RSS"
./mkrss.sh
echo "RSS Built"
