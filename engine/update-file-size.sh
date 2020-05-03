#!/usr/bin/env nix-shell
#!nix-shell -i zsh
#!nix-shell -I nixpkgs="https://github.com/NixOS/nixpkgs/archive/19.09.tar.gz"

cd "$(git rev-parse --show-toplevel)" || exit 1
webdir="_optim"

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
    
    gzhtmlsize=$( gzip -c $fic|wc -c )
    debug GZHTML: $gzhtmlsize

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
    gzcsssize=0
    for i in $css; do
        isize=$( sizeof $webdir/$i )
        gzisize=$( gzip -c $webdir/$i | wc -c )
        debug $i '=>' $isize
        (( csssize += isize ))
        (( gzcsssize += gzisize ))
    done
    debug CSS: $csssize
    debug GZCSS: $gzcsssize
    total=$(( htmlsize + imgsize + csssize ))
    gztotal=$(( gzhtmlsize + imgsize + gzcsssize ))
    # the space is important before the toh total
    sizeinfos=$(print -- " $(toh $total) (html $(toh $htmlsize), css $(toh $csssize)")
    gzsizeinfos=$(print -- " $(toh $gztotal) (html $(toh $gzhtmlsize), css $(toh $gzcsssize)")
    if ((imgsize>0)); then
        sizeinfos="$sizeinfos, img $(toh $imgsize))"
        gzsizeinfos="$gzsizeinfos, img $(toh $imgsize))"
    else
        sizeinfos="$sizeinfos)"
        gzsizeinfos="$gzsizeinfos)"
    fi
    print -- $sizeinfos
    perl -pi -e 's#(<div class="?web-file-size"?>)[^<]*(</div>)#$1'"$sizeinfos"'$2#;s#(<div class="?gzweb-file-size"?>)[^<]*(</div>)#$1'"$gzsizeinfos"'$2#' $fic
done
rm -rf $tmpdir
