#!/usr/bin/env zsh

cd "$(git rev-parse --show-toplevel)" || exit 1
# Directory
webdir="_site"
postsdir="$webdir/posts"
indexfile="$webdir/index.html"

# maximal number of articles to put in the RSS file
maxarticles=10

# RSS Metas
rsstitle="her.esy.fun"
rssurl="https://her.esy.fun/rss.xml"
websiteurl="https://her.esy.fun"
rssdescription="her.esy.fun articles, mostly random personal thoughts"
rsslang="en"
rssauthor="yann@esposito.host (Yann Esposito)"
rssimgurl="https://her.esy.fun/img/FlatAvatar.png"

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
        printf "\\n<span class=\"tag\">%s</span>" $keyword
    done
}

autoload -U colors && colors

tmpdir=$(mktemp -d)
typeset -a dates
dates=( )
for fic in $postsdir/**/*.html; do
    if echo $fic|egrep -- '-(mk|min|sci|modern).html$'>/dev/null; then
        continue
    fi
    postfile="$(echo "$fic"|sed 's#^'$postsdir'/##')"
    blogfile="$(echo "$fic"|sed 's#^'$webdir'/##')"
    printf "%-30s" $postfile
    xfic="$tmpdir/$fic.xml"
    mkdir -p $(dirname $xfic)
    hxclean $fic > $xfic
    d=$(finddate $xfic)
    echo -n " [$d]"
    rssdate=$(formatdate $d)
    title=$(findtitle $xfic)
    keywords=( $(findkeywords $xfic) )
    printf ": %-55s" "$title ($keywords)"
    categories=$(mkcategories $keywords)
    absoluteurl="${websiteurl}/${blogfile}"
    { printf "\\n<li>"
      printf "\\n<a href=\"%s\">%s</a>" "${blogfile}" "$title"
      printf "\\n<span class=\"pubDate\">%s</span>%s" "$rssdate"
      printf "<span class=\"tags\">%s</span>" "$categories"
      printf "\\n</li>\\n\\n"
    } >>  "$tmpdir/${d}-$(basename $fic).index"
    dates=( $d $dates )
    echo " [${fg[green]}OK${reset_color}]"
done
echo "Publishing"
for fic in $(ls $tmpdir/*.index | sort -r | head -n $maxarticles ); do
    echo "${fic:t}"
    cat $fic >> $tmpdir/index
done

rssmaxdate=$(formatdate $(for d in $dates; do echo $d; done | sort -r | head -n 1))
rssbuilddate=$(formatdate $(date))
title="Index"
description="Index of latest posts."
author="Yann Esposito"
{
cat <<END
<!DOCTYPE html>
<html lang="en">
    <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <title>$title</title>
        <meta name="author" content="$author">
        <link rel="stylesheet" href="/css/y.css"/>
        <link rel="alternate" type="application/rss+xml" href="/rss.xml" />
        <link rel="icon" href="/favicon.ico">
    </head>
    <body>
        <div id="labels">
            <div class="content">
                <span id="logo">
                    <a href="/">
                        <svg width="5em" viewBox="0 0 64 64">
                            <circle cx="32" cy="32" r="30" stroke="var(--b2)" stroke-width="2" fill="var(--b03)"/>
                            <circle cx="32" cy="32" r="12" stroke="var(--r)" stroke-width="2" fill="var(--o)"/>
                            <circle cx="32" cy="32" r="6" stroke-width="0" fill="var(--y)"/>
                            <ellipse cx="32" cy="14" rx="14" ry="8" stroke-width="0" fill="var(--b3)"/>
                        </svg>
                    </a>
            </div>
        </div>
        <div class="main">
            <div id="preamble" class="status">
                <div class="content">
                    <h1>$title</h1>
                    <div class="meta">
                        <span class="yyydate">$date</span> on
                        <a href="https://her.esy.fun">
                            <span class="author">$author</span>'s blog</a>
                    </div>
                    <div class="abstract">
                        $description
                    </div>
                </div>
            </div>
            <div id="content">
END
cat $tmpdir/index
cat <<END
            </div>
            <div id="postamble" class="status">
                <div class="content">
                    <nav>
                        <a href="/index.html">Home</a> |
                        <a href="/slides.html">Slides</a> |
                        <a href="/about-me.html">About</a>
                        <span class="details"> (<a href="https://gitea.esy.fun/yogsototh">code</a>
                            <a href="https://espial.esy.fun/u:yogsototh">bookmarks</a>
                            <a href="https://espial.esy.fun/u:yogsototh/notes">notes</a>)</span> |
                        <a href="#preamble">↑ Top ↑</a>
                    </nav>
                </div>
            </div>
        </div>
    </body>
</html>
END
} > "$indexfile"

rm -rf $tmpdir
echo "* RSS [done]"
