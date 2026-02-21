#!/bin/bash
# Transmission post-download script to wrap single-file torrents into a folder
# For Radarr compatibility

# Arguments from Transmission
TORRENT_ID="$1"
TORRENT_NAME="$2"
TORRENT_PATH="$3"
TORRENT_IS_COMPLETED="$4"

# Only run on completed downloads
if [ "$TORRENT_IS_COMPLETED" != "1" ]; then
    exit 0
fi

# Full path to torrent
DOWNLOAD_DIR="$TORRENT_PATH/$TORRENT_NAME"

# Check if the torrent is a single file
FILE_COUNT=$(find "$DOWNLOAD_DIR" -maxdepth 1 -type f | wc -l)

if [ "$FILE_COUNT" -eq 1 ]; then
    FILE_NAME=$(find "$DOWNLOAD_DIR" -maxdepth 1 -type f)
    
    # Create a folder with the torrent name if it doesn't exist
    TARGET_FOLDER="$TORRENT_PATH/$TORRENT_NAME"
    mkdir -p "$TARGET_FOLDER"
    
    # Move the file into the folder
    mv "$FILE_NAME" "$TARGET_FOLDER/"
    
    echo "Wrapped single file '$FILE_NAME' into folder '$TARGET_FOLDER'"
fi

exit 0