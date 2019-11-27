#!/usr/bin/env nix-shell
#!nix-shell -i zsh
#!nix-shell -I nixpkgs="https://github.com/NixOS/nixpkgs/archive/19.09.tar.gz"

webdir="_site"

debug () {
 print -- $* >/dev/null
}

type -a filelist
setopt extendedglob
if (($#>0)); then
    filelist=( $* )
else
    filelist=( $webdir/**/*.html(.) )
fi

tmp=$(mktemp)

for fic in $filelist; do
    if echo $fic|egrep -- '-(mk|min|sci|modern).html$'>/dev/null; then
        continue
    fi
    print -n -- "$fic "
    cp $fic $tmp; minify --mime text/html $tmp > $fic
    print "[OK]"
done
