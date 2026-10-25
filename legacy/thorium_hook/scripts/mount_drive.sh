#!/usr/bin/env bash
set -e

IMAGE_PATH="/Volumes/android/AstraBuild.sparseimage"
MOUNT_POINT="/Volumes/AstraBuild"

if [ -d "$MOUNT_POINT" ]; then
    echo "AstraBuild is already mounted at $MOUNT_POINT"
    exit 0
fi

if [ ! -f "$IMAGE_PATH" ]; then
    echo "Error: External drive not found or AstraBuild.sparseimage is missing at $IMAGE_PATH"
    echo "Please plug in your external drive."
    exit 1
fi

echo "Attaching AstraBuild container..."
hdiutil attach "$IMAGE_PATH"
echo "Mounted successfully at $MOUNT_POINT"
