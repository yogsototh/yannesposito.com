#!/usr/bin/env zsh

cd "$(git rev-parse --show-toplevel)" || exit 1
# Directory
webdir="_site"
postsdir="$webdir/posts"
indexfile="$webdir/index.gmi"

# maximal number of articles to put in the RSS file
maxarticles=100

# RSS Metas
rsstitle="her.esy.fun"
websiteurl="gemini://her.esy.fun"
rssdescription="her.esy.fun articles, mostly random personal thoughts"
rsslang="en"
rssauthor="yann@esposito.host (Yann Esposito)"

# title and keyword shouldn't be changed

formatdate() {
    # format the date for RSS
    local d=$1
    LC_TIME=en_US date --date $d +'%Y-%m-%d'
}

finddate(){ < $1 | awk '/^date: /' | head -n1 | perl -pe 's/^.*\[//;s/ .*$//;' }
findtitle(){ < $1 | head -n1 | perl -pe 's/^# //' }
getcontent(){
    < $1 perl -pe 'use URI; $base="'$2'"; s# (href|src)="((?!https?://)[^"]*)"#" ".$1."=\"".URI->new_abs($2,$base)->as_string."\""#eig' }
findkeywords(){ < $1 | awk '/^keywords: /' | head -n1 | sed 's/keywords: //' }

autoload -U colors && colors

tmpdir=$(mktemp -d)
typeset -a dates
dates=( )
for fic in $postsdir/**/*.gmi; do
    postfile="$(echo "$fic"|sed 's#^'$postsdir'/##')"
    blogfile="$(echo "$fic"|sed 's#^'$webdir'/##')"
    printf "%-30s" $postfile
    xfic="$fic"
    d=$(finddate $xfic)
    echo -n " [$d]"
    rssdate=$(formatdate $d)
    title=$(findtitle $xfic)
    keywords=( $(findkeywords $xfic) )
    printf ": %-55s" "$title ($keywords)"
    absoluteurl="${websiteurl}/${blogfile}"
    {
      printf "=> %s %s: %s [%s]\n" "$absoluteurl" "$rssdate" "$title" "$keywords"
    } >>  "$tmpdir/${d}-$(basename $fic).gmi"
    dates=( $d $dates )
    echo " [${fg[green]}OK${reset_color}]"
done
echo "Publishing"
for fic in $(ls $tmpdir/*.gmi | sort -r | head -n $maxarticles ); do
    echo "${fic:t}"
    cat $fic >> $tmpdir/gmi
done

rssmaxdate=$(formatdate $(for d in $dates; do echo $d; done | sort -r | head -n 1))
rssbuilddate=$(formatdate $(date))
{
cat <<END
    ,---,
   / <=> \\
  (  (O)  )
   \\     /
    '---'
  YOGSOTOTH

The index of my articles.
I talk about programming and sometime movies.
Some articles are only intended for gemini.
Enjoy!

END
cat $tmpdir/gmi
} > "$indexfile"

rm -rf $tmpdir
echo "* Gemini Index [done]"
