# { pkgs ? import <nixpkgs> {} }:
{ pkgs ? import (fetchTarball https://github.com/NixOS/nixpkgs/archive/19.09-beta.tar.gz) {} }:
  pkgs.mkShell {
    buildInputs = [ pkgs.html-xml-utils ];
  }
