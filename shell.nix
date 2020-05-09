# { pkgs ? import <nixpkgs> {} }:
{ pkgs ? import (fetchTarball https://github.com/NixOS/nixpkgs/archive/19.09.tar.gz) {} }:
  let my_aspell = pkgs.aspellWithDicts(p: with p; [en fr]);
  in
  pkgs.mkShell {
    buildInputs = [ pkgs.coreutils
                    pkgs.html-xml-utils
                    pkgs.zsh
                    pkgs.perl
                    pkgs.perlPackages.URI
                    pkgs.minify
                    pkgs.haskellPackages.sws
                    pkgs.cacert
                  ];
  }
