#!/usr/bin/env bash

cd "$(git rev-parse --show-toplevel)" || exit 1
echo "* org-publish"
emacs -nw \
  --load project.el \
  --eval "(progn (org-publish \"blog\") (evil-quit))"

echo "* org-publish [done]"
