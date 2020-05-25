{ pkgs ? import (fetchTarball https://github.com/NixOS/nixpkgs/archive/20.03.tar.gz) {} }:
let
  haskellDeps = ps : with ps; [
    shake
  ];
  pkgs1909 = import (fetchTarball https://github.com/NixOS/nixpkgs/archive/19.09.tar.gz) {};
  ghc = pkgs.haskellPackages.ghcWithPackages haskellDeps;
in
pkgs.mkShell {
    buildInputs = with pkgs;
      [cacert
        coreutils
        html-xml-utils
        zsh
        perl
        perlPackages.URI
        minify
        niv
        ghc
        pkgs1909.haskellPackages.sws
        haskellPackages.shake
      ];
  }
