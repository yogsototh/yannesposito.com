#!/usr/bin/env zsh

cd "$(git rev-parse --show-toplevel)" || exit 1
# Directory
webdir="_optim"
postsdir="$webdir/posts"
rssfile="$webdir/gem-atom.xml"

# maximal number of articles to put in the RSS file
maxarticles=10

# RSS Metas
rsstitle="her.esy.fun"
rssurl="gemini://her.esy.fun/gem-atom.xml"
websiteurl="gemini://her.esy.fun"
rssdescription="her.esy.fun articles, mostly random personal thoughts"
rsslang="en"
rssauthor="yann@esposito.host (Yann Esposito)"
rssimgurl="gemini://her.esy.fun/img/FlatAvatar.png"

# title and keyword shouldn't be changed

formatdate() {
    # format the date for RSS
    local d=$1
    LC_TIME=en_US date --date $d +'%a, %d %b %Y %H:%M:%S %z'
}

finddate(){ < $1 | awk '/^date: /' | head -n1 | perl -pe 's/^.*\[//;s/ .*$//;' }
findtitle(){ < $1 | head -n1 | perl -pe 's/^# //' }
getcontent(){
    < $1 perl -pe 'use URI; $base="'$2'"; s# (href|src)="((?!https?://)[^"]*)"#" ".$1."=\"".URI->new_abs($2,$base)->as_string."\""#eig' }
findkeywords(){ < $1 | awk '/^keywords: /' | head -n1 | perl -pe 's/^[^:]\s+//' }
mkcategories(){
    for keyword in $*; do
        printf "\\n<category>%s</category>" $keyword
    done
}

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
    categories=$(mkcategories $keywords)
    absoluteurl="${websiteurl}/${blogfile}"
    { printf "\\n<item>"
      printf "\\n<title>%s</title>" "$title"
      printf "\\n<guid>%s</guid>" "$absoluteurl"
      printf "\\n<pubDate>%s</pubDate>%s" "$rssdate"
      printf "%s" "$categories"
      printf "\\n<description><![CDATA[\\n%s\\n]]></description>" "$(getcontent "$xfic" "$absoluteurl")"
      printf "\\n</item>\\n\\n"
    } >>  "$tmpdir/${d}-$(basename $fic).rss"
    dates=( $d $dates )
    echo " [${fg[green]}OK${reset_color}]"
done
echo "Publishing"
for fic in $(ls $tmpdir/*.rss | sort -r | head -n $maxarticles ); do
    echo "${fic:t}"
    cat $fic >> $tmpdir/rss
done

rssmaxdate=$(formatdate $(for d in $dates; do echo $d; done | sort -r | head -n 1))
rssbuilddate=$(formatdate $(date))
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
  <lastBuildDate>$rssbuilddate</lastBuildDate>
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

rm -rf $tmpdir
echo "* Gemini Atom [done]"
