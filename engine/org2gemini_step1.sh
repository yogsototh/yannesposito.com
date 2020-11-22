#!/usr/bin/env awk -f

BEGIN { IGNORECASE=1; }

{ skip=0; }

/^#\+(BEGIN|END)_SRC ?/i { gsub(/#\+(BEGIN|END)_SRC ?/,"```"); }
/^#\+(BEGIN|END)_[^ ]* ?/i { gsub(/#\+(BEGIN|END)_([^ ]*) ?/,"______"); }

/^#\+(macro|lang|language|options|startup):/ { skip=1; }
/{{{br}}}/ { gsub(/{{{br}}}/,""); }
/{{{pemail}}}/ { gsub(/{{{pemail}}}/,"yann@esposito.host"); }

/^#\+TITLE: / { gsub(/^#[^:]*: /,"# "); }
/^ *:[a-zA-Z_0-9]*:/ { skip=1; }
/^\* / { gsub(/^\* /,"# "); }
/^\*\* / { gsub(/^\*\* /,"## "); }
/^\*\*\* / { gsub(/^\*\*\* /,"### "); }

/@@html:/ { htmlskip = 1; }

!skip && /^#\+([^:]*):/ {
   x=$1;
   gsub(/^#\+/,"",x);
   x=tolower(x);
   gsub(/^#\+([^:]*):/,"",$0);
   $0=x" "$0;
}
/^- / { gsub(/^- /,"* "); }
!skip && !htmlskip{ 
  print;
}
/@@/ && !/@@html:/ { htmlskip = 0; }
/@@$/ { htmlskip = 0; }
