#!/usr/bin/env bash
set -e

source "/Users/akshatmohanty/Astra/scripts/env.sh"
cd /Volumes/AstraBuild/chromium/src

echo "Compiling Astra browser (stabilized with -j 3 for smooth disk I/O)..."
ninja -j 3 -C out/Astra chrome

echo ""
echo "Build complete!"
echo "App bundle located at: /Volumes/AstraBuild/chromium/src/out/Astra/Chromium.app"
echo "You can launch it using: ./scripts/run.sh"
