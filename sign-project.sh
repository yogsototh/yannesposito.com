#!/usr/bin/env bash

signer=yann@esposito.host

gpg --local-user $signer --output project.el.sig --detach-sign project.el
