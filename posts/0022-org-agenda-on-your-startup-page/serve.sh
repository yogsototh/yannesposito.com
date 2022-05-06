#! /user/bin/env nix-shell
#! nix-shell shell.nix -i bash
webdir="_site"
port="$(grep server.port ./lighttpd.conf|sed 's/[^0-9]*//')"
echo "Serving: $webdir on http://localhost:$port" && \
lighttpd -f ./lighttpd.conf -D
