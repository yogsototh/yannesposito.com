#!/usr/bin/env nix-shell
#!nix-shell -i zsh
#!nix-shell -I nixpkgs="https://github.com/NixOS/nixpkgs/archive/19.09.tar.gz"

cd "$(git rev-parse --show-toplevel)" || exit 1
webdir="_site"

sizeof() {
    stat --format="%s" "$*"
}

debug () {
 print -- $* >/dev/null
}

toh () {
    numfmt --to=iec $*
}

tmpdir=$(mktemp -d)

type -a filelist
if (($#>0)); then
    filelist=( $* )
else
    filelist=( $webdir/**/*.html(.) )
fi

for fic in $filelist; do
    print -n -- "$fic   "

    htmlsize=$(sizeof $fic)
    debug HTML: $htmlsize

    xfic=$tmpdir/$fic
    mkdir -p $(dirname $xfic)
    hxclean $fic > $xfic

    images=( $( < $xfic hxselect -i -c -s '\n' 'img::attr(src)' | sed 's/^\.\.\///' ) )
    imgsize=0
    nbimg=0
    for i in $images; do
        ((nbimg++))
        isize=$( sizeof ${fic:h}/$i )
        debug $i '=>' $isize
        (( imgsize += isize ))
    done
    debug IMG: $imgsize

    css=( $( < $xfic hxselect -i -c -s '\n' 'link[rel=stylesheet]::attr(href)'))
    csssize=0
    for i in $css; do
        isize=$( sizeof $webdir/$i )
        debug $i '=>' $isize
        (( csssize += isize ))
    done
    debug CSS: $csssize
    total=$(( htmlsize + imgsize + csssize ))
    sizeinfos=$(print -- "Size: $(toh $total) (HTML: $(toh $htmlsize), CSS: $(toh $csssize), IMG: $(toh $imgsize))")
    print -- $sizeinfos
    perl -pi -e 's#(<div class="?web-file-size"?>)[^<]*(</div>)#$1'"$sizeinfos"'$2#' $fic
done
rm -rf $tmpdir
