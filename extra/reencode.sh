#!/bin/bash

DIR="$1"

if [ -z "$DIR" ]; then
  echo "Usage: ./reencode.sh /path/to/library"
  exit 1
fi

MAX_SECONDS=$((6*60*60))
START=$(date +%s)

find "$DIR" -type f -name "*.mkv" | while read file; do
  NOW=$(date +%s)
  ELAPSED=$(( NOW - START ))

  if [ $ELAPSED -ge $MAX_SECONDS ]; then
    break
  fi

  echo "Checking: $file"

  video_codec=$(ffprobe -v error -select_streams v:0 \
    -show_entries stream=codec_name \
    -of default=noprint_wrappers=1:nokey=1 "$file")

  audio_codec=$(ffprobe -v error -select_streams a:0 \
    -show_entries stream=codec_name \
    -of default=noprint_wrappers=1:nokey=1 "$file")

  echo "Video: $video_codec | Audio: $audio_codec"

  if [[ "$video_codec" == "h264" && "$audio_codec" == "ac3" ]]; then
    echo "Already compatible. Skipping."
    continue
  fi

  tmp="${file%.mkv}.tmp.mkv"

  # Decide what needs re-encoding
  if [[ "$video_codec" != "h264" ]]; then
    echo "Re-encoding VIDEO + audio if needed..."
    ffmpeg -y -i "$file" \
      -threads 4 \
      -map 0 \
      -c:v libx264 \
      -preset medium \
      -crf 18 \
      -pix_fmt yuv420p \
      -profile:v high \
      -level 4.1 \
      -c:a ac3 -b:a 384k \
      -c:s copy \
      -loglevel error -stats \
      "$tmp"
  else
    echo "Copying video, converting audio only..."
    ffmpeg -y -i "$file" \
      -threads 4 \
      -map 0 \
      -c:v copy \
      -c:a ac3 -b:a 384k \
      -c:s copy \
      -loglevel error -stats \
#      -loglevel error \
      "$tmp"
  fi

  if [ $? -eq 0 ]; then
    echo "Success. Replacing original."
    mv "$tmp" "$file"
  else
    echo "Error occurred. Keeping original."
    rm -f "$tmp"
  fi

done
