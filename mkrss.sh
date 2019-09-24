#!/usr/bin/env zsh

rsstpl="rss.tpl"
webdir="_site"
rssfile="$webdir/rss.xml"

formatdate() {
    local d=$1
    LC_TIME=en_US date --date $d +'%a, %d %b %Y %H:%M:%S %z'
}
finddate(){
    local fic="$1"
    grep 'article-date' < $fic | perl -pe 's#.*<span class="article-date">([^<]*)</span>.*#$1#'|egrep '[0-9]+-[0-9]+-[0-9]+'
}
getcontent(){
    local fic="$1"
    cat $fic | perl -pe 's#.*<(link|meta).*$##;s#<(img|input) ([^>]*[^/])>#<img $1/>#g' | hxselect '#content'
}

realname="Yann Esposito"
website="https://her.esy.fun"

tmpdir=$(mktemp -d)
for fic in $webdir/posts/**/*.html; do
    rssdate=$(formatdate $(finddate $fic))
    blogfile="$(echo $fic | perl -pe 's#.*?/posts/#/posts/#')"
    printf "\\n<item>\\n<title>%s</title>\\n<guid>%s%s</guid>\\n<pubDate>%s</pubDate>\\n<description><![CDATA[\\n%s\\n]]></description>\\n</item>\\n\\n" "$realname" "$website" "$blogfile" "$rssdate" "$(getcontent "$fic")" >>  "$tmpdir/rss"
done

sed "/<!-- LB -->/r $tmpdir/rss" "$rsstpl" > "$rssfile"
