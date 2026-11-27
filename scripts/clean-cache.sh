#!/usr/bin/env bash
set -e

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SPARSE_IMAGE="/Volumes/android/Astra build material/AstraBuild.sparseimage"

# Use the same OS lock as build.sh so cleanup cannot remove active build files.
if [ "${ASTRA_BUILD_CACHE_LOCK_HELD:-}" != "1" ]; then
    echo "==> Acquiring shared Astra build/cache lock..."
    exec /usr/bin/lockf -k -w /tmp/astra-build-cache.lock \
        /usr/bin/env ASTRA_BUILD_CACHE_LOCK_HELD=1 "$REPO_ROOT/scripts/clean-cache.sh" "$@"
fi

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
