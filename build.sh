#!/usr/bin/env bash

emacs --load .project.el.gpg --eval '(progn (delete-directory org-publish-timestamp-directory t) (org-publish "blog" t) (evil-quit))'
