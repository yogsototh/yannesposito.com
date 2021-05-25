#!/usr/bin/env zsh

autoload -U colors && colors
cd "$(git rev-parse --show-toplevel)" || exit 1
# Directory
webdir="_site"
indexfile="$webdir/index.html"
indexdir=".cache/rss"
tmpdir=$(mktemp -d)

echo "Publishing"

dateaccessor='.pubDate'
finddate(){ < $1 hxselect -c $dateaccessor }
# generate files with <DATE>-<FILENAME>.index
for fic in $indexdir/**/*.index; do
    d=$(finddate $fic)
    echo "${${fic:h}:t} [$d]"
    cp $fic $tmpdir/$d-${${fic:h}:t}.index
done

# for every post in reverse order
# generate the body (there is some logic to group by year)
previousyear=""
for fic in $(ls $tmpdir/*.index | sort -r); do
    d=$(finddate $fic)
    year=$( echo "$d" | perl -pe 's#(\d{4})-.*#$1#')
    if (( year != previousyear )); then
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
