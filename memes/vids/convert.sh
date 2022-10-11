#!/usr/bin/env zsh
ffmpeg -i $1 \
  -vcodec libx264 \
  -profile:v main \
  -level 3.1 \
  -preset medium \
  -crf 23 \
  -x264-params ref=4 \
  -acodec ac3_fixed \
  -movflags +faststart \
  ${1:r}.mp4
