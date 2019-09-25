#!/usr/bin/env bash

emacs --load project.el --eval '(progn (delete-directory org-publish-timestamp-directory t) (org-publish "blog" nil) (evil-quit))'
