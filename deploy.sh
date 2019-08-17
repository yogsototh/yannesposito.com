#!/usr/bin/env zsh

rootdir=${0:h}
echo $rootdir

rsync --progress --partial -avHe ssh $rootdir/_site/ root@shoggoth1:/var/www/her.esy.fun/ --delete
