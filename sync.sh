#!/usr/bin/env zsh

rootdir=${0:h}
echo $rootdir

echo -n "Uploading website"
rsync --progress --partial -avHe ssh $rootdir/_site/ root@esy.fun:/var/www/her.esy.fun/ --delete
echo " [done]"
