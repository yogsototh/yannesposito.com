#!/usr/bin/env zsh

cd "$(git rev-parse --show-toplevel)" || exit 1
webdir="_site"

[[ -d $webdir ]] || { echo "no $webdir directory"; exit 1 }

echo -n "Uploading website"
rsync --progress\
      --partial \
      --delete \
      --exclude '.git' \
      -avHe ssh ${webdir}/ root@esy.fun:/var/www/her.esy.fun/
echo " [done]"
