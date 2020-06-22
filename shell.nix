{ pkgs ? import (fetchTarball https://github.com/NixOS/nixpkgs/archive/20.03.tar.gz) {} }:
let
  pkgs1909 = import (fetchTarball https://github.com/NixOS/nixpkgs/archive/19.09.tar.gz) {};
  haskellDeps = ps : with ps; [
    shake
    pandoc
    data-default
    protolude
    pkgs1909.haskellPackages.sws
  ];
  ghc = pkgs.haskellPackages.ghcWithPackages haskellDeps;
in
pkgs.mkShell {
    buildInputs = with pkgs;
      [ cacert
        coreutils
        html-xml-utils
        zsh
        perl
        perlPackages.URI
        minify
        niv
        ghc
        git
        direnv
        haskellPackages.shake
      ];
  }
