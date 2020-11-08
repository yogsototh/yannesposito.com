#!/usr/bin/env bash

cd "$(git rev-parse --show-toplevel)" || exit 1

src="$1"
dst="$2"

./engine/org2gemini_step1.sh "$src" | perl -pe 's#\[\[([^]]*)\]\[([^]]*)\]\]#\n=> $1 $2#g;s#^\* *$##;s#=> file:([^ ]*)\.org#=> $1.gmi#g;s#\[\[(file:)?([^]]*)\]\]#=> $2#g' > "$dst"
