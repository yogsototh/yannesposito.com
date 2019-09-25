#!/usr/bin/env zsh

rootdir=${0:h}
echo $rootdir

echo "Building RSS"
./mkrss.sh
echo "RSS Built"
echo -n "Publishing"
rsync --progress --partial -avHe ssh $rootdir/_site/ root@shoggoth1:/var/www/her.esy.fun/ --delete
echo " [done]"
