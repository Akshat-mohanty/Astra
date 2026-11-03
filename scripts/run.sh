#!/usr/bin/env bash
set -e

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [ -d "/Applications/Astra.app" ]; then
    echo "==> Launching /Applications/Astra.app..."
    open /Applications/Astra.app
elif [ -d "$REPO_ROOT/target/debug/bundle/macos/Astra.app" ]; then
    echo "==> Launching $REPO_ROOT/target/debug/bundle/macos/Astra.app..."
    open "$REPO_ROOT/target/debug/bundle/macos/Astra.app"
else
    echo "==> Astra.app not found. Building now..."
    "$REPO_ROOT/scripts/build.sh"
    open /Applications/Astra.app
fi
