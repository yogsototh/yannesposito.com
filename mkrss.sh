#!/usr/bin/env nix-shell
#!nix-shell -i zsh

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
findtitle(){
    local fic="$1"
    grep '<h1>' < $fic | perl -pe 's#.*<h1>([^<]*)</h1>.*#$1#'
}
getcontent(){
    local fic="$1"
    cat $fic | perl -pe 's#.*<(link|meta).*$##;s#<(img|input) ([^>]*[^/])>#<img $1/>#g' | hxselect '#content'
}

realname="Yann Esposito"
website="https://her.esy.fun"

autoload -U colors && colors

tmpdir=$(mktemp -d)
for fic in $webdir/posts/**/*.html; do
    printf "%-40s" "$fic"
    d=$(finddate $fic)
    echo -n " [$d]"
    rssdate=$(formatdate $d)
    title=$(findtitle $fic)
    printf ": %-30s" "$title"
    blogfile="$(echo $fic | perl -pe 's#.*?/posts/#/posts/#')"
    printf "\\n<item>\\n<title>%s</title>\\n<guid>%s%s</guid>\\n<pubDate>%s</pubDate>\\n<description><![CDATA[\\n%s\\n]]></description>\\n</item>\\n\\n" "$title" "$website" "$blogfile" "$rssdate" "$(getcontent "$fic")" >>  "$tmpdir/${d}-$(basename $fic).rss"
    echo " [${fg[green]}OK${reset_color}]"
done
for fic in $(ls $tmpdir/*.rss | sort -r); do
    # echo $fic
    cat $fic >> $tmpdir/rss
done

sed "/<!-- LB -->/r $tmpdir/rss" "$rsstpl" > "$rssfile"
rm -rf $tmpdir
echo "RSS Generated"
