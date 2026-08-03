#!/usr/bin/env zsh
# Build a single Atom <entry> (RFC 4287) out of a cleaned post HTML file.
# Mirrors mk-rss-entry.sh, which produces the RSS 2.0 <item> for the same post.

cd "$(git rev-parse --show-toplevel)" || exit 1
source ./engine/envvars.sh
# Directory
webdir="_site"
postsdir="$webdir/posts"
indexdir=".cache/rss"

# file to handle
fic="$1"
dst="$2"

# Atom Metas
websiteurl="https://yannesposito.com"

# HTML Accessors (similar to CSS accessors)
dateaccessor='.yyydate'
contentaccessor='#content'
# title and keyword shouldn't be changed
titleaccessor='title'
keywordsaccessor='meta[name=keywords]::attr(content)'
summaryaccessor='meta[name=description]::attr(content)'

formatdate() {
    # Atom mandates RFC 3339 dates
    local d="$1"
    LC_TIME=en_US date --date $d +'%Y-%m-%dT%H:%M:%S%:z'
}

finddate(){ < $1 hxselect -c $dateaccessor | sed 's/\[//g;s/\]//g;s/ .*$//' }
# Titles are wrapped over several lines in the source HTML; collapse the
# whitespace so readers do not display a line break mid-title.
squash(){ tr '\n' ' ' | sed 's/  */ /g;s/^ //;s/ $//' }
findtitle(){ < $1 hxselect -c $titleaccessor | squash }
findsummary(){ < $1 hxselect -c $summaryaccessor | squash }
getcontent(){
    < $1 hxselect $contentaccessor | \
                  perl -pe 'use URI; $base="'$2'"; s# (href|src)="((?!https?://)[^"]*)"#" ".$1."=\"".URI->new_abs($2,$base)->as_string."\""#eig' }
findkeywords(){ < $1 hxselect -c $keywordsaccessor | sed 's/,/ /g' }

mkcategories(){
    for keyword in $*; do
        printf "\\n  <category term=\"%s\"/>" $keyword
    done
}

autoload -U colors && colors

# XML escaping. The & in a sed replacement means "the matched text", hence the
# backslashes: without them, < would be rewritten to <lt; instead of &lt;.
# printf, not echo: zsh's echo expands \n and \t, which mangles article bodies
# that show escape sequences verbatim (Emacs Lisp strings, printf examples).
protect() { printf '%s' "$*" | sed 's/&/\&amp;/g;s/</\&lt;/g;s/>/\&gt;/g' }

# CDATA sections cannot contain the ]]> sequence; split it across two sections.
cdataprotect() { printf '%s' "$*" | sed 's/]]>/]]]]><![CDATA[>/g' }

xfic="$fic"
postfile="$(echo "$fic"|sed 's#^'$postsdir'/##')"
blogfile="$(echo "$fic"|sed 's#.xml$#.html#;s#^'$indexdir'/#posts/#')"
printf "%-30s" $blogfile
d=$(finddate $xfic)
echo -n " [$d]"
atomdate=$(formatdate $d)
title=$(findtitle $xfic)
summary=$(findsummary $xfic)
keywords=( $(findkeywords $xfic) )
printf ": %-55s" "$title ($keywords)"
categories=$(mkcategories $keywords)
absoluteurl="${websiteurl}/${blogfile}"
[[ ! -d $(dirname $dst) ]] && mkdir -p $(dirname $dst)
{ printf "\\n<entry>"
  # type="text" is the point of Atom over RSS: it says unambiguously that the
  # escaped markup below is literal text, not markup to be rendered.
  printf "\\n  <title type=\"text\">%s</title>" "$(protect "$title")"
  printf "\\n  <id>%s</id>" "$absoluteurl"
  printf "\\n  <link rel=\"alternate\" type=\"text/html\" href=\"%s\"/>" "$absoluteurl"
  printf "\\n  <published>%s</published>" "$atomdate"
  printf "\\n  <updated>%s</updated>" "$atomdate"
  printf "%s" "$categories"
  [[ -n "$summary" ]] && \
      printf "\\n  <summary type=\"text\">%s</summary>" "$(protect "$summary")"
  # <content> vs <summary>: RSS conflates both into <description> and leaves
  # readers guessing whether they got an excerpt or the whole article.
  printf "\\n  <content type=\"html\"><![CDATA[\\n%s\\n]]></content>" \
      "$(cdataprotect "$(getcontent "$xfic" "$absoluteurl")")"
  printf "\\n</entry>\\n\\n"
} >  "${dst}"

echo " [${fg[green]}OK${reset_color}]"
