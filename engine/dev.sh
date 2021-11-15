#!/usr/bin/env zsh

cd "$(git rev-parse --show-toplevel)" || exit 1
source ./engine/envvars.sh

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

pipegreen() {while read line; do green $line; done}
pipeyellow() {while read line; do yellow $line; done}
pipeblue() {while read line; do blue $line; done}

tee >(lorri watch | sed 's/^/[lorri] /' | pipegreen ) \
  >(./engine/serve.sh | sed 's/^/[http] /' | pipeyellow) \
  >(./engine/auto-build.sh | sed 's/^/[make] /' | pipeblue) \
  >(sleep 1 && open 'http://127.0.0.1:3000')
