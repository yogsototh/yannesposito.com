#!/usr/bin/env nix-shell
#!nix-shell -i zsh

rsstpl="rss.tpl"
webdir="_site"
rssfile="$webdir/rss.xml"

xmlize() {
    local fic="$1";
    hxclean $fic
}

formatdate() {
    local d=$1
    LC_TIME=en_US date --date $d +'%a, %d %b %Y %H:%M:%S %z'
}
finddate(){
    local fic="$1"
    cat $fic | hxselect -c '.article-date'
}
findtitle(){
    local fic="$1"
    cat $fic | hxselect -c 'h1'
}
getcontent(){
    local fic="$1"
    cat $fic | hxselect '#content'
}

realname="Yann Esposito"
website="https://her.esy.fun"

autoload -U colors && colors

tmpdir=$(mktemp -d)
for fic in $webdir/posts/**/*.html; do
    printf "%-40s" "$fic"
    xfic="$tmpdir/$fic.xml"
    mkdir -p $(dirname $xfic)
    xmlize $fic > $xfic
    d=$(finddate $xfic)
    echo -n " [$d]"
    rssdate=$(formatdate $d)
    title=$(findtitle $xfic)
    printf ": %-30s" "$title"
    blogfile="$(echo $fic | perl -pe 's#.*?/posts/#/posts/#')"
    printf "\\n<item>\\n<title>%s</title>\\n<guid>%s%s</guid>\\n<pubDate>%s</pubDate>\\n<description><![CDATA[\\n%s\\n]]></description>\\n</item>\\n\\n" "$title" "$website" "$blogfile" "$rssdate" "$(getcontent "$xfic")" >>  "$tmpdir/${d}-$(basename $fic).rss"
    echo " [${fg[green]}OK${reset_color}]"
done
for fic in $(ls $tmpdir/*.rss | sort -r); do
    # echo $fic
    cat $fic >> $tmpdir/rss
done

sed "/<!-- LB -->/r $tmpdir/rss" "$rsstpl" > "$rssfile"
rm -rf $tmpdir
echo "RSS Generated"
