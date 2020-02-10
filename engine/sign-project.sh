#!/usr/bin/env bash

cd "$(git rev-parse --show-toplevel)" || exit 1
signer=yann@esposito.host

gpg --local-user $signer --output project.el.sig --detach-sign project.el
