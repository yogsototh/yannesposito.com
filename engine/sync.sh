#!/usr/bin/env zsh

cd $(git rev-parse --show-toplevel)
rootdir=${0:h}
echo $rootdir

echo -n "Uploading website"
rsync --progress --partial -avHe ssh $rootdir/_site/ root@esy.fun:/var/www/her.esy.fun/ --delete
echo " [done]"
