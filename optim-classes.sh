#!/bin/zsh

classes=( $( {cat _site/**/*.html | perl -p -e 's/class="?([a-zA-Z0-9_-]*)/\nCLASS: $1\n/g'; cat _site/**/*.css | perl -p -e 's/\.([a-zA-Z-_][a-zA-Z0-9-_]*)/\nCLASS: $1\n/g'}|grep CLASS|sort -u|cut -d\   -f 2,2|awk 'length($1)>2 {print length($1),$1}'|sort -n|cut -d\  -f 2,2) )

chr() {
    [ "$1" -lt 26 ] || return 1
    printf "\\$(printf '%03o' $(( 97 + $1 )))"
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
    print "$c -> $sn"
    assoc[$c]=$sn
    ((i++))
done


for fic in _site/**/*.html; do
    print -- $fic
    for long in $classes; do
        perl -pi  -e 's#class=("?)'${long}'#class=$1'${assoc[$long]}'#g' $fic
    done
done
for fic in _site/**/*.css; do
    echo $fic
    for long in $classes; do
        perl -pi  -e 's#\.'"${long}"'#.'"${assoc[$long]}"'#g' $fic
    done
done
