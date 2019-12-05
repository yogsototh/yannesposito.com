#!/bin/zsh

classes=( $(cat _site/**/*.html | perl -p -e 's/class="?([a-zA-Z0-9-_]*)/\nCLASS: $1\n/g'|grep CLASS|sort -u|cut -d\   -f 2,2) )

chr() {
    [ "$1" -lt 26 ] || return 1
    printf "\\$(printf '%03o' $(( 97 + $1 )))"
}

ord() {
    LC_CTYPE=C printf '%d' "'$1"
}

shortName() {
    if [ "$1" -gt 25 ]; then
        print -- $(shortName $(( ( $1 / 26 ) - 1 )))$(shortName $(( $1 % 26 )))
    else
        chr $1
    fi
}

i=0;
typeset -A assoc
for c in $classes; do
    sn=$(shortName $i)
    print "$c $sn"
    assoc[$c]=$sn
    ((i++))
done

hmltreplace=''
cssreplace=''
for long in $classes; do
    htmlreplace="${htmlreplace}s/\(class=\"\?\)${long}/\$\{1\}${assoc[${long}]}/g;"
    cssreplace="${cssreplace}s/\(\\.\)${long}/\$\{1\}${assoc[${long}]}/g;"
done

print -- $htmlreplace
print -- $cssreplace

for fic in _site/**/*.html; do
    print -- $fic
    perl -pi -e $htmlreplace $fic;
done
for fic in _site/**/*.css; do
    echo $fic
    perl -pi -e $cssreplace $fic;
done
