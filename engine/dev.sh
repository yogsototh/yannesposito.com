#!/usr/bin/env zsh

tee >(lorri watch) >(./engine/serve.sh) >(./engine/auto-build.sh) >(sleep 1 && open 'http://127.0.0.1:3000')

