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
for xfic in $indexdir/**/*.xml; do
    postfile="$(echo "$xfic"|sed 's#^'$postsdir'/##')"
    blogfile="$(echo "$xfic"|sed 's#.xml$#.html#;s#^'$indexdir'/#posts/#')"
    printf "%-30s" $postfile
    d=$(finddate $xfic)
    echo -n " [$d]"
    rssdate=$(formatdate $d)
    title=$(findtitle $xfic)
    keywords=( $(findkeywords $xfic) )
    printf ": %-55s" "$title ($keywords)"
    categories=$(mkcategories $keywords)
    { printf "\\n<li>"
      printf "\\n<a href=\"%s\">%s</a>" "${blogfile}" "$title"
      printf "\\n<span class=\"pubDate\">%s</span>%s" "$d"
      printf "<span class=\"tags\">%s</span>" "$categories"
      printf "\\n</li>\\n\\n"
    } >>  "$tmpdir/${d}-$(basename $xfic).index"
    dates=( $d $dates )
    echo " [${fg[green]}OK${reset_color}]"
done

echo "Publishing"

# building the body

{ cat <<EOF
<nav>
<a href="/index.html">Home</a> |
<a href="/slides.html">Slides</a> |
<a href="/about-me.html">About</a>
<span class="details">
(<a href="https://gitea.esy.fun/yogsototh">code</a>
<a href="https://espial.esy.fun/u:yogsototh">bookmarks</a>
<a href="https://espial.esy.fun/u:yogsototh/notes">notes</a>)
</span>
</nav>
EOF
} >> $tmpdir/index

previousyear=""
for fic in $(ls $tmpdir/*.index | sort -r | head -n $maxarticles ); do
    echo "${fic:t}"
    year=$( echo "${fic:t}" | perl -pe 's#(\d{4})-.*#$1#')
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
{ cat <<EOF
</ul>
<hr/><a href="/Scratch/en/blog/">Archive of old articles (2008-2016)</a>
<p>Most popular:</p>
<ul>
<li><a href="/Scratch/en/blog/Learn-Vim-Progressively/">Learn Vim Progressively</a>
    <span class="pubDate">2011-08-25</span>
    <span class="tags">
      <span class="tag">vim</span>
    </span>
</li>
<li><a href="/Scratch/en/blog/Haskell-the-Hard-Way/">Learn Haskell Fast and Hard</a>
    <span class="pubDate">2012-02-08</span>
    <span class="tags">
      <span class="tag">haskell</span>
      <span class="tag">programming</span>
    </span>
</li>
<li><a href="http://yogsototh.github.io/Category-Theory-Presentation/categories.html">Category Theory Presentation</a>
    <span class="pubDate">2012-12-12</span>
    <span class="tags">
      <span class="tag">math</span>
      <span class="tag">computer science</span>
      <span class="tag">haskell</span>
    </span>
</li>
</ul>
EOF
} >> $tmpdir/index

title="Yann Esposito's Posts"
description="The index of my most recent articles."
author="Yann Esposito"
body=$(< $tmpdir/index)
date=$(LC_TIME=en_US date +'%Y-%m-%d')
# the pandoc templates use $x$ format, we replace it by just $x
# to be used with envsubst
template=$(< templates/post.html | \
    sed 's/\$(header-includes|table-of-content)\$//' | \
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
