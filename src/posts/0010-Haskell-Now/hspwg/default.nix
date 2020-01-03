{ nixpkgs ? import ./nixpkgs.nix
, compiler ? "default"
, doBenchmark ? false }:
let
  inherit (nixpkgs) pkgs;
  name = "hspwg";
  haskellPackages = pkgs.haskellPackages;
  variant = if doBenchmark
            then pkgs.haskell.lib.doBenchmark
            else pkgs.lib.id;
  drv = haskellPackages.callCabal2nix name ./. {};
in
{
  my_project = drv;
  shell = haskellPackages.shellFor {
    # generate hoogle doc
    withHoogle = true;
    packages = p: [drv];
    # packages dependencies (by default haskellPackages)
    buildInputs = with haskellPackages;
      [ apply-refact
        hlint
        stylish-haskell
        hasktags
        hoogle
        ghcid
        cabal-install
        cabal2nix
        hindent
        # # if you want to add some system lib like ncurses
        # # you could by writing it like:
        # pkgs.ncurses
      ];
    # nice prompt for the nix-shell
    shellHook = ''
     export PS1="\n[${name}:\033[1;32m\]\W\[\033[0m\]]> "
  '';
  };
}
