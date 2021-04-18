#!/usr/bin/env zsh

(($#<3)) && {
  print "usage: $0:t SUB DOMAIN PORT"
  exit 1
} >&2

SUB="$1"
DOMAIN="$2"
PORT="$3"

m4 -D SUB=$SUB -D DOMAIN=$DOMAIN -D PORT=$PORT reverse-proxy-template.m4 > $SUB.$DOMAIN
