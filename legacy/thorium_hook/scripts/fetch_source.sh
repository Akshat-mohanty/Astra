#!/usr/bin/env bash
set -e

SOURCE_DIR="/Volumes/AstraBuild/chromium"
mkdir -p "$SOURCE_DIR"
cd "$SOURCE_DIR"

source "/Users/akshatmohanty/Astra/scripts/env.sh"

echo "Resuming Chromium source sync with git-lfs enabled..."
gclient sync --nohooks --no-history

echo "Chromium source sync complete!"
