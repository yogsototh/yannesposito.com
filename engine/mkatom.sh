#! /usr/bin/env zsh
# Aggregate the per-post Atom entries into _site/atom.xml (RFC 4287).
# The RSS 2.0 feed built by mkrss.sh stays alongside it; both are advertised in
# the page <head>, so readers pick whichever they prefer.

cd "$(git rev-parse --show-toplevel)" || exit 1
source ./engine/envvars.sh
# Directory
webdir="_site"
postsdir="$webdir/posts"
atomfile="$webdir/atom.xml"
indexdir=".cache/rss"

# maximal number of articles to put in the Atom file
maxarticles=20

# Atom Metas
atomtitle="yannesposito.com"
atomurl="https://yannesposito.com/atom.xml"
websiteurl="https://yannesposito.com"
atomsubtitle="yannesposito.com articles, mostly random personal thoughts"
atomlang="en"
atomauthorname="Yann Esposito"
atomauthoremail="yann@esposito.host"
atomlogo="https://yannesposito.com/img/FlatAvatar.png"
atomicon="https://yannesposito.com/favicon.ico"

finddate(){ < $1 grep -o '<updated>[^<]*</updated>' | head -n 1 | sed 's/<[^>]*>//g' }

sortkey() {
    # strip the RFC 3339 offset so entries sort on local time, like mkrss.sh
    echo "$1" | sed 's/\([+-][0-9][0-9]:[0-9][0-9]\|Z\)$//'
}

autoload -U colors && colors

typeset -a stamps
stamps=( )
tmpdir=$(mktemp -d)
for fic in $indexdir/**/*.atom; do
    atomdate=$(finddate $fic)
    echo -n "${${fic:h}:t} [$atomdate]"
    d=$(sortkey $atomdate)
    stamps=( "$d|$atomdate" $stamps )
    echo " [${fg[green]}OK${reset_color}]"
    cp $fic $tmpdir/$d-${${fic:h}:t}.atom
done
echo "Publishing"
n=1
for fic in $(ls $tmpdir/*.atom | sort -r | head -n $maxarticles ); do
    echo "$((n++)) ${fic:t}"
    cat $fic >> $tmpdir/atom
done

# Atom has a single <updated> for the feed. Use the newest entry date rather
# than the build time, so a rebuild without new content is not an update.
atommaxdate=$(for s in $stamps; do echo $s; done | sort -r | head -n 1 | cut -d'|' -f2)

{
cat <<END
<?xml version="1.0" encoding="utf-8"?>
<feed xmlns="http://www.w3.org/2005/Atom" xml:lang="${atomlang}">
  <title type="text">${atomtitle}</title>
  <subtitle type="text">${atomsubtitle}</subtitle>
  <id>${websiteurl}/</id>
  <link rel="self" type="application/atom+xml" href="${atomurl}"/>
  <link rel="alternate" type="text/html" href="${websiteurl}/"/>
  <link rel="alternate" type="application/rss+xml" href="${websiteurl}/rss.xml"/>
  <updated>${atommaxdate}</updated>
  <author>
    <name>${atomauthorname}</name>
    <email>${atomauthoremail}</email>
    <uri>${websiteurl}/</uri>
  </author>
  <logo>${atomlogo}</logo>
  <icon>${atomicon}</icon>
  <generator uri="${websiteurl}/">mkatom.sh</generator>
END
cat $tmpdir/atom
cat <<END
</feed>
END
} > "$atomfile"

rm -rf $tmpdir
echo "\* Atom [done]"
