#!/usr/bin/env bash

cd "$(git rev-parse --show-toplevel)" || exit 1

src="$1"
dst="$2"

./engine/org2gemini_step1.sh "$src" | \
  perl -pe 's#^email:\s+yann\@esposito.host\s*#$&=> /files/publickey.txt gpg\n#g;' | \
  perl -pe 's# ?\[\[([^]]*)\]\[([^]]*)\]\]#\n\n=> $1 $2\n#g;' | \
  perl -pe 's#=> file:([^ ]*)\.org#=> $1.gmi#g;' | \
  perl -pe 's#=> file:([^ ]*)#=> $1#g;' | \
  perl -pe 's#\[\[(file:)?([^]]*)\]\]#=> $2#g;' | \
  perl -pe 's#^\* *\n\n##' | \
  # remove lines with a single special char
  perl -pe 's#^\s*[-\*\+\.]\s*$##' | \
  perl -pe 's#^\**[ ]*:.*:$##' | \
  perl -pe 's#^\s[- ]*$#\n#;' > "$dst"

{ echo ""
  echo "=> /index.gmi Home"
  echo "=> /gem-atom.xml Feed"
  echo "=> /slides.gmi Slides"
  echo "=> /about-me.gmi About"
  echo ""
  echo "=> https://gitea.esy.fun code"
  echo "=> https://espial.esy.fun/u:yogsototh bookmarks"
  echo "=> https://espial.esy.fun/u:yogsototh/notes notes"
} >> "$dst"
