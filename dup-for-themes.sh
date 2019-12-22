#!/usr/bin/env nix-shell
#!nix-shell -i zsh
#!nix-shell -I nixpkgs="https://github.com/NixOS/nixpkgs/archive/19.09.tar.gz"

webdir="_site"

debug () {
 print -- $* >/dev/null
}

if (($#>0)); then
    filelist=( $* )
else
    filelist=( $webdir/**/*.html(.) )
fi

trans(){
   local suff=$1;
   local fic=$2;
   cat $fic | perl -p -e 's#href="?/css/mk.css"?#href=/css/'$suff'.css#;s#(/?(index|archive|slides|about-me)).html#$1-'$suff'.html#g;s#(posts/[a-zA-Z0-9_-]*).html#$1-'$suff'.html#g;s#-'$suff'.html>mk#.html>mk#g' > ${fic:r}-${suff}.html
}

print -- "Duplicate HTML by themes"
for fic in $filelist; do
    if echo $fic|egrep -- '-(mk|min|sci|modern).html$'>/dev/null; then
        continue
    fi
    print -n -- "$fic "
    for suff in sci min modern; do
        trans $suff $fic
    done
    print "[OK]"
done
print "Duplicate HTML by theme [done]"
