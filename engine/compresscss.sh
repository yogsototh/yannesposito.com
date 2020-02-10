#!/usr/bin/env nix-shell
#!nix-shell -i bash
#!nix-shell -I nixpkgs="https://github.com/NixOS/nixpkgs/archive/19.09.tar.gz"
#!nix-shell -p minify

# nix-shell -p nodePackages.clean-css

minify "$1" > "$2"
