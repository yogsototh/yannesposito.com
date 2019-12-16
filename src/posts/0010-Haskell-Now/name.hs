#! /usr/bin/env nix-shell
#! nix-shell -i runghc
#! nix-shell -p "ghc.withPackages (ps: [ ps.protolude ])"
#! nix-shell -I nixpkgs="https://github.com/NixOS/nixpkgs/archive/19.09.tar.gz"
main = do
    print "What is your name?"
    name <- getLine
    print ("Hello " ++ name ++ "!")
