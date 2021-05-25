#!/usr/bin/env zsh

cd "$(git rev-parse --show-toplevel)" || exit 1
# Directory
webdir="_site"
postsdir="$webdir/posts"
indexfile="$webdir/index.html"
indexdir=".cache/rss"

# maximal number of articles to put in the index homepage
maxarticles=1000

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
tmpdir=$(mktemp -d)

echo "Publishing"

# building the body


dateaccessor='.pubDate'
finddate(){ < $1 hxselect -c $dateaccessor }

previousyear=""
for fic in $indexdir/**/*.index; do
    d=$(finddate $fic)
    echo "${${fic:h}:t} [$d]"
    cp $fic $tmpdir/$d-${${fic:h}:t}.index
done

previousyear=""
for fic in $(ls $tmpdir/*.index | sort -r); do
    d=$(finddate $fic)
    echo "${fic:t}"
    year=$( echo "$d" | perl -pe 's#(\d{4})-.*#$1#')
    if (( year != previousyear )); then
        echo $year
        if (( previousyear > 0 )); then
            echo "</ul>" >> $tmpdir/index
        fi
        previousyear=$year
        echo "<h3 name=\"${year}\" >${year}</h3><ul>" >> $tmpdir/index
    fi
    cat $fic >> $tmpdir/index
done
echo "</ul>" >> $tmpdir/index

title="Y"
description="Most recent articles"
author="Yann Esposito"
body=$(< $tmpdir/index)
date=$(LC_TIME=en_US date +'%Y-%m-%d')

# A neat trick to use pandoc template within a shell script
# the pandoc templates use $x$ format, we replace it by just $x
# to be used with envsubst
template=$(< templates/index.html | \
    sed 's/\$\(header-includes\|table-of-content\)\$//' | \
    sed 's/\$if.*\$//' | \
    perl -pe 's#(\$[^\$]*)\$#$1#g' )
{
    export title
    export author
    export description
    export date
    export body
    echo ${template} | envsubst
} > "$indexfile"

rm -rf $tmpdir
echo "* HTML INDEX [done]"
