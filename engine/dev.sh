#!/usr/bin/env zsh

## colors for tput
# black=0
red=1
green=2
yellow=3
blue=4
# magenta=5
# cyan=6
# white=7
green() { printf "$(tput setaf $green)%s$(tput sgr0)" "$*" }
yellow() { printf "$(tput setaf $yellow)%s$(tput sgr0)" "$*" }
blue() { printf "$(tput setaf $blue)%s$(tput sgr0)" "$*" }

tee >(lorri watch | sed 's/^/[lorri] /' ) \
  >(./engine/serve.sh | sed 's/^/[http] /') \
  >(./engine/auto-build.sh | sed 's/^/[make] /') \
  >(sleep 1 && open 'http://127.0.0.1:3000')

