#! /usr/bin/env zsh

cd "$(git rev-parse --show-toplevel)" || exit 1
source ./engine/envvars.sh
# Directory
webdir="_site"
postsdir="$webdir/posts"
rssfile="$webdir/rss.xml"
indexdir=".cache/rss"

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
dateaccessor='pubDate'

formatdate() {
    # format the date for RSS
    local d="$1"
    # echo "DEBUG DATE: $d" >&2
    LC_TIME=en_US date --date $d +'%a, %d %b %Y %H:%M:%S %z'
}

isodate() {
    # format the date for sorting
    local d="$1"
    # echo "DEBUG DATE: $d" >&2
    LC_TIME=en_US date --date "$d" +'%Y-%m-%dT%H:%M:%S'
}

finddate(){ < $1 hxselect -c $dateaccessor }

autoload -U colors && colors

typeset -a dates
dates=( )
tmpdir=$(mktemp -d)
for fic in $indexdir/**/*.rss; do
    rssdate=$(finddate $fic)
    echo -n "${${fic:h}:t} [$rssdate]"
    d=$(isodate $rssdate)
    dates=( $d $dates )
    echo " [${fg[green]}OK${reset_color}]"
    cp $fic $tmpdir/$d-${${fic:h}:t}.rss
done
echo "Publishing"
n=1
for fic in $(ls $tmpdir/*.rss | sort -r | head -n $maxarticles ); do
    echo "$((n++)) ${fic:t}"
    cat $fic >> $tmpdir/rss
done

rssmaxdate=$(formatdate $(for d in $dates; do echo $d; done | sort -r | head -n 1))
rssbuilddate=$(formatdate $(date -I))
{
cat <<END
<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0"
	   xmlns:content="http://purl.org/rss/1.0/modules/content/"
	   xmlns:wfw="http://wellformedweb.org/CommentAPI/"
	   xmlns:dc="http://purl.org/dc/elements/1.1/"
	   xmlns:atom="http://www.w3.org/2005/Atom"
	   xmlns:sy="http://purl.org/rss/1.0/modules/syndication/"
	   xmlns:slash="http://purl.org/rss/1.0/modules/slash/"
	   xmlns:georss="http://www.georss.org/georss"
     xmlns:geo="http://www.w3.org/2003/01/geo/wgs84_pos#"
     xmlns:media="http://search.yahoo.com/mrss/"><channel>
  <title>${rsstitle}</title>
  <atom:link href="${rssurl}" rel="self" type="application/rss+xml" />
  <link>${websiteurl}</link>
  <description><![CDATA[${rssdescription}]]></description>
  <language>${rsslang}</language>
  <pubDate>${rssmaxdate}</pubDate>
  <lastBuildDate>${rssbuilddate}</lastBuildDate>
  <generator>mkrss.sh</generator>
  <webMaster>${rssauthor}</webMaster>
  <image>
    <url>${rssimgurl}</url>
    <title>${rsstitle}</title>
    <link>${websiteurl}</link>
  </image>
END
cat $tmpdir/rss
cat <<END
</channel>
</rss>
END
} > "$rssfile"

# HACK TO UPDATE OLD RSS FEEDS
legacyenrss="$webdir/Scratch/en/blog/feed/feed.xml"
legacyfrrss="$webdir/Scratch/fr/blog/feed/feed.xml"
mkdir -p "${legacyenrss:h}"
mkdir -p "${legacyfrrss:h}"
cp -f "$rssfile" "$legacyenrss"
cp -f "$rssfile" "$legacyfrrss"

rm -rf $tmpdir
echo "\* RSS [done]"
