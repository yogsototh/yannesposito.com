#!/usr/bin/env zsh

rootdir=${0:h}
echo $rootdir

echo "Full Build"
./fullbuild.sh
echo -n "Publishing"
rsync --progress --partial -avHe ssh $rootdir/_site/ root@esy.fun:/var/www/her.esy.fun/ --delete
echo " [done]"
