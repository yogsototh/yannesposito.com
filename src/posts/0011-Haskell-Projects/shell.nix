let
     config = { allowBroken = true; };
in
   { nixpkgs ? import (fetchGit {
     name = "nixos-release-19.09";
     url = "https://github.com/NixOS/nixpkgs";
     # obtained via
     # git ls-remote https://github.com/nixos/nixpkgs master
     ref = "refs/heads/nixpkgs-19.09-darwin";
     rev = "d5291756487d70bc336e33512a9baf9fa1788faf";
   }) { inherit config; } }:
   let
     inherit (nixpkgs) pkgs;
     inherit (pkgs) haskellPackages;

     haskellDeps = ps: with ps; [
       base
       protolude
       containers
     ];

     ghc = haskellPackages.ghcWithPackages haskellDeps;

     nixPackages = [
       ghc
       pkgs.gdb
       # haskellPackages.haskell-overridez
       haskellPackages.summoner
       haskellPackages.summoner-tui
       haskellPackages.cabal-install
       haskellPackages.ghcid
     ];
   in
   pkgs.stdenv.mkDerivation {
     name = "env";
     buildInputs = nixPackages;
     shellHook = ''
        export PS1="\n\[[hs:\033[1;32m\]\W\[\033[0m\]]> "
     '';
   }
