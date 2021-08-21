#!/usr/bin/env zsh
cd "$(git rev-parse --show-toplevel)" || exit 1
source ./engine/envvars.sh
xfic="$1"
dst="$2"

# Directory
indexdir=".cache/rss"

# HTML Accessors (similar to CSS accessors)
dateaccessor='.yyydate'
# title and keyword shouldn't be changed
titleaccessor='title'
keywordsaccessor='meta[name=keywords]::attr(content)'

finddate(){ < $1 hxselect -c $dateaccessor | sed 's/\[//g;s/\]//g;s/ .*$//' }
findtitle(){ < $1 hxselect -c $titleaccessor }
findkeywords(){ < $1 hxselect -c $keywordsaccessor | sed 's/,/ /g' }

autoload -U colors && colors

blogfile="$(echo "$xfic"|sed 's#.xml$#.html#;s#^'$indexdir'/#posts/#')"
printf "%-30s" $blogfile
d=$(finddate $xfic)
echo -n " [$d]"
title=$(findtitle $xfic)
keywords=( $(findkeywords $xfic) )
printf ": %-55s" "$title ($keywords)"
{ printf "\\n<li>"
  printf "\\n<span class=\"pubDate\">%s</span>" "$d"
  printf "\\n<a href=\"%s\">%s</a>" "${blogfile}" "$title"
  printf "\\n</li>\\n\\n"
} > ${dst}

echo " [${fg[green]}OK${reset_color}]"
