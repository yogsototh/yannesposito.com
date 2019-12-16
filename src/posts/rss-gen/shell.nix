# { pkgs ? import <nixpkgs> {} }:
{ pkgs ? import (fetchTarball https://github.com/NixOS/nixpkgs/archive/19.09.tar.gz) {} }:
  pkgs.mkShell {
    buildInputs = [ pkgs.coreutils pkgs.html-xml-utils pkgs.zsh ];
  }
