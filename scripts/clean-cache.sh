#!/usr/bin/env bash
set -e

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SPARSE_IMAGE="/Volumes/android/Astra build material/AstraBuild.sparseimage"

echo "==> Cleaning Astra build cache..."

# 1. Mount if needed to clean
if [ ! -d "/Volumes/AstraBuild" ] && [ -f "$SPARSE_IMAGE" ]; then
    diskutil image attach "$SPARSE_IMAGE" -mountOptions nobrowse 2>/dev/null || \
        hdiutil attach "$SPARSE_IMAGE" -nobrowse 2>/dev/null || true
fi

# 2. Clear target build cache on the external workspace
if [ -d "/Volumes/AstraBuild/target" ]; then
    echo "==> Removing intermediate build artifacts from /Volumes/AstraBuild/target..."
    rm -rf /Volumes/AstraBuild/target/*
    echo "==> Build cache cleared."
fi

# 3. Clean any local target if exists
if [ -d "$REPO_ROOT/target" ] && [ ! -L "$REPO_ROOT/target" ]; then
    rm -rf "$REPO_ROOT/target"
fi

# 4. Eject external volume so it does not stay on Desktop
if [ -d "/Volumes/AstraBuild" ]; then
    echo "==> Ejecting /Volumes/AstraBuild..."
    diskutil eject "/Volumes/AstraBuild" 2>/dev/null || true
fi

echo "==> Done! Build cache deleted and external workspace unmounted."
echo "==> /Applications/Astra.app remains installed and fully usable on your Mac."
