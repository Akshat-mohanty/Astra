#!/usr/bin/env bash
set -e

MOUNT_POINT="/Volumes/AstraBuild"

if [ ! -d "$MOUNT_POINT" ]; then
    echo "AstraBuild is not currently mounted."
    exit 0
fi

echo "Detaching AstraBuild container safely..."
hdiutil detach "$MOUNT_POINT"
echo "Safely detached. You may now unplug your external drive if desired."
