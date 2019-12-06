#!/bin/zsh

webdir="_site"

retrieve_classes_in_html () {
    cat $webdir/**/*.html(N) | \
        perl -pe 's/class="?([a-zA-Z0-9_-]*)/\nCLASS: $1\n/g'
}

retrieve_classes_in_css () {
    cat $webdir/**/*.css(N) | \
        perl -pe 's/\.([a-zA-Z-_][a-zA-Z0-9-_]*)/\nCLASS: $1\n/g'
}

classes=( $( {retrieve_classes_in_html; retrieve_classes_in_css}| \
                 egrep "^CLASS: [^ ]*$" |\
                 sort -u | \
                 awk 'length($2)>2 && $2 != "web-file-size" {print length($2),$2}'|\
                 sort -rn | \
                 awk '{print $2}') )

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
    print -- "$c -> $sn"
    assoc[$c]=$sn
    ((i++))
done

htmlreplacer=''
cssreplacer=''
for long in $classes; do
    htmlreplacer=$htmlreplacer's#class=("?)'${long}'#class=$1'${assoc[$long]}'#g;'
    cssreplacer=$cssreplacer's#\.'${long}'#.'${assoc[$long]}'#g;'
done

sizeof() {
    stat --format="%s" "$*"
}

for fic in $webdir/**/*.{html,xml}(N); do
    before=$(sizeof $fic)
    print -n -- "$fic ($before"
    perl -pi -e $htmlreplacer $fic
    after=$(sizeof $fic)
    print -- " => $after [$(( ((before - after) * 100) / before  ))])"
done
for fic in $webdir/**/*.css(N); do
    before=$(sizeof $fic)
    print -n -- "$fic ($before"
    perl -pi  -e $cssreplacer $fic
    after=$(sizeof $fic)
    print -- " => $after [$(( ((before - after) * 100) / before  ))])"
done
