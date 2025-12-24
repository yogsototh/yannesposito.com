{
  description = "her.esy.fun - Personal static website generator";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        haskellDeps = ps: with ps; [
          protolude
          turtle
          ansi-terminal
        ];

        ghc = pkgs.haskellPackages.ghcWithPackages haskellDeps;
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            # Core utilities
            cacert
            coreutils
            gnumake
            git

            # Build and content processing
            pandoc
            html-xml-utils  # hxselect, hxclean
            minify

            # Shell and scripting
            zsh
            perl
            perlPackages.URI

            # Haskell environment
            ghc

            # Image processing
            imagemagick     # magick command
            libwebp         # cwebp command

            # File watching and development
            entr
            fswatch
            direnv
            tmux

            # Web serving
            lighttpd
            nodePackages.http-server

            # Deployment
            rsync

            # Search and utilities
            ripgrep
          ];

          shellHook = ''
            echo "her.esy.fun development environment"
            echo ""
            echo "Available tools:"
            echo "  make        - $(make --version | head -1)"
            echo "  pandoc      - $(pandoc --version | head -1)"
            echo "  ghc         - $(ghc --version)"
            echo "  imagemagick - $(magick --version | head -1)"
            echo ""
            echo "Commands:"
            echo "  make        - Build the entire site"
            echo "  make serve  - Serve site locally"
            echo "  make watch  - Watch for changes and rebuild"
            echo "  make help   - Show all available commands"
            echo ""
          '';
        };
      }
    );
}
