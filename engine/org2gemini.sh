#!/usr/bin/env bash

cd "$(git rev-parse --show-toplevel)" || exit 1

src="$1"
dst="$2"

./engine/org2gemini_step1.sh "$src" | \
  perl -pe 's#^email:\s+yann\@esposito.host\s*#$&=> /files/publickey.txt gpg\n#g;' | \
  perl -pe 's#\[\[([^]]*)\]\[([^]]*)\]\]#\n=> $1 $2#g;' | \
  perl -pe 's#=> file:([^ ]*)\.org#=> $1.gmi#g;' | \
  perl -pe 's#\[\[(file:)?([^]]*)\]\]#=> $2#g;' | \
  perl -pe 's#^\* *\n##' | \
  perl -pe 's#^\**[ ]*:.*:$##' | \
  perl -pe 's#^\s[- ]*$##;' > "$dst"

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
