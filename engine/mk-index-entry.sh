#!/usr/bin/env zsh

cd "$(git rev-parse --show-toplevel)" || exit 1

xfic="$1"
dst="$2"

# Directory
webdir="_site"
postsdir="$webdir/posts"
indexdir=".cache/rss"

# HTML Accessors (similar to CSS accessors)
dateaccessor='.yyydate'
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
findkeywords(){ < $1 hxselect -c $keywordsaccessor | sed 's/,/ /g' }
mktaglist(){
    for keyword in $*; do
        printf "<span class=\"tag\">%s</span>" $keyword
    done | sed 's#><#>, <#g'
}

autoload -U colors && colors

postfile="$(echo "$xfic"|sed 's#^'$postsdir'/##')"
blogfile="$(echo "$xfic"|sed 's#.xml$#.html#;s#^'$indexdir'/#posts/#')"
printf "%-30s" $blogfile
d=$(finddate $xfic)
echo -n " [$d]"
rssdate=$(formatdate $d)
title=$(findtitle $xfic)
keywords=( $(findkeywords $xfic) )
printf ": %-55s" "$title ($keywords)"
taglist=$(mktaglist $keywords)
{ printf "\\n<li>"
  printf "\\n<span class=\"pubDate\">%s</span>" "$d"
  printf "\\n<a href=\"%s\">%s</a>" "${blogfile}" "$title"
  printf "\\n</li>\\n\\n"
} >> ${dst}.tmp

# overwrite only if the value in the index are different
if ! cmp -s ${dst} ${dst}.tmp; then
  echo " [${fg[yellow]}M${reset_color}]"
  mv -f ${dst}.tmp ${dst}
fi
echo " [${fg[green]}OK${reset_color}]"
