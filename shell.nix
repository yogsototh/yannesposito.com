let
  sources = import ./nix/sources.nix;
  pkgs = import sources.nixpkgs {};
  haskellDeps = ps : with ps; [
    protolude
    turtle
    ansi-terminal
  ];
  ghc = pkgs.haskellPackages.ghcWithPackages haskellDeps;
in
pkgs.mkShell {
    buildInputs = with pkgs;
      [ cacert
        coreutils
        entr
        pandoc
        html-xml-utils # hxselect
        zsh
        perl
        perlPackages.URI
        minify
        niv
        git
        direnv
        ghc
        tmux
        # for emacs dev
        ripgrep
        nodePackages.http-server
        lighttpd
      ];
  }
