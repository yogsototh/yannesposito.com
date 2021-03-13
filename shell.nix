let
  sources = import ./nix/sources.nix;
  pkgs = import sources.nixpkgs {};
  pkgs1909 = import (fetchTarball https://github.com/NixOS/nixpkgs/archive/19.09.tar.gz) {};
  haskellDeps = ps : with ps; [
    shake
    pandoc
    data-default
    protolude
    pkgs1909.haskellPackages.sws
    stache
  ];
  ghc = pkgs.haskellPackages.ghcWithPackages haskellDeps;
in
pkgs.mkShell {
    buildInputs = with pkgs;
      [ cacert
        coreutils
        entr
        html-xml-utils
        zsh
        perl
        perlPackages.URI
        minify
        niv
        git
        direnv
# ghc
# haskellPackages.shake
        tmux
        # for emacs dev
        ripgrep
      ];
  }
