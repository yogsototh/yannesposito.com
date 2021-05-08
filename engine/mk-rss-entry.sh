#!/usr/bin/env zsh

cd "$(git rev-parse --show-toplevel)" || exit 1
# Directory
webdir="_site"
postsdir="$webdir/posts"
indexdir=".cache/rss"

# file to handle
fic="$1"
dst="$2"

# RSS Metas
websiteurl="https://her.esy.fun"

# HTML Accessors (similar to CSS accessors)
dateaccessor='.yyydate'
contentaccessor='#content'
# title and keyword shouldn't be changed
titleaccessor='title'
keywordsaccessor='meta[name=keywords]::attr(content)'

formatdate() {
    # format the date for RSS
    local d="$1"
    # echo "DEBUG DATE: $d" >&2
    LC_TIME=en_US date --date $d +'%a, %d %b %Y %H:%M:%S %z'
}

finddate(){ < $1 hxselect -c $dateaccessor | sed 's/\[//g;s/\]//g;s/ .*$//' }
findtitle(){ < $1 hxselect -c $titleaccessor }
getcontent(){
    < $1 hxselect $contentaccessor | \
                  perl -pe 'use URI; $base="'$2'"; s# (href|src)="((?!https?://)[^"]*)"#" ".$1."=\"".URI->new_abs($2,$base)->as_string."\""#eig' }
findkeywords(){ < $1 hxselect -c $keywordsaccessor | sed 's/,/ /g' }

mkcategories(){
    for keyword in $*; do
        printf "\\n<category>%s</category>" $keyword
    done
}

autoload -U colors && colors

postfile="$(echo "$fic"|sed 's#^'$postsdir'/##')"
blogfile="$(echo "$fic"|sed 's#^'$webdir'/##')"
printf "%-30s" $postfile
xfic="${dst:r}.xml"
hxclean $fic > $xfic
d=$(finddate $xfic)
echo -n " [$d]"
rssdate=$(formatdate $d)
title=$(findtitle $xfic)
keywords=( $(findkeywords $xfic) )
printf ": %-55s" "$title ($keywords)"
categories=$(mkcategories $keywords)
absoluteurl="${websiteurl}/${blogfile}"
mkdir -p $(dirname $dst)
{ printf "\\n<item>"
  printf "\\n<title>%s</title>" "$title"
  printf "\\n<guid>%s</guid>" "$absoluteurl"
  printf "\\n<pubDate>%s</pubDate>%s" "$rssdate"
  printf "%s" "$categories"
  printf "\\n<description><![CDATA[\\n%s\\n]]></description>" "$(getcontent "$xfic" "$absoluteurl")"
  printf "\\n</item>\\n\\n"
} >  "$dst"
echo " [${fg[green]}OK${reset_color}]"
