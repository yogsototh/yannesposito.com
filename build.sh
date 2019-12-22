#!/usr/bin/env bash

echo "* org-publish"
emacs \
  --load project.el \
  --eval "(progn (org-publish \"blog\") (evil-quit))"

echo "* org-publish [done]"
