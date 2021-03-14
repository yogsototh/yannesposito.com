#!/bin/sh

# mkdir -p _shake
# ghc --make app/Shakefile.hs -rtsopts -threaded -with-rtsopts=-I0 -outputdir=_shake -o _shake/build && _shake/build "$@"

cabal v2-run -- her-esy-fun "$@"
