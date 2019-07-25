#!/usr/bin/env bash

emacs --load .project.el.gpg --eval '(progn (org-publish "blog" t) (evil-quit))'
