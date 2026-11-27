#!/usr/bin/env bash
set -e

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

# Serialize builds and cache cleanup across all Astra sessions on this Mac.
if [ "${ASTRA_BUILD_CACHE_LOCK_HELD:-}" != "1" ]; then
    echo "==> Acquiring shared Astra build/cache lock..."
    exec /usr/bin/lockf -k -w /tmp/astra-build-cache.lock \
        /usr/bin/env ASTRA_BUILD_CACHE_LOCK_HELD=1 "$REPO_ROOT/scripts/build.sh" "$@"
fi

# 1. Mount external storage build workspace if available
SPARSE_IMAGE="/Volumes/android/Astra build material/AstraBuild.sparseimage"
if [ ! -d "/Volumes/AstraBuild" ] && [ -f "$SPARSE_IMAGE" ]; then
    echo "==> Mounting external build workspace from $SPARSE_IMAGE..."
    diskutil image attach "$SPARSE_IMAGE" -mountOptions nobrowse 2>/dev/null || \
        hdiutil attach "$SPARSE_IMAGE" -nobrowse 2>/dev/null || true
fi

# 2. Redirect build cache to external storage if mounted
if [ -d "/Volumes/AstraBuild" ]; then
    mkdir -p "/Volumes/AstraBuild/target"
    if [ ! -L "$REPO_ROOT/target" ] || [ "$(readlink "$REPO_ROOT/target")" != "/Volumes/AstraBuild/target" ]; then
        echo "==> Linking target -> /Volumes/AstraBuild/target to save local disk space..."
        if [ -d "$REPO_ROOT/target" ] && [ ! -L "$REPO_ROOT/target" ]; then
            rm -rf "$REPO_ROOT/target"
        fi
        ln -sfn "/Volumes/AstraBuild/target" "$REPO_ROOT/target"
    fi
    export CARGO_TARGET_DIR="/Volumes/AstraBuild/target"
    echo "==> Using external build cache at $CARGO_TARGET_DIR"
fi

# Limit concurrent cargo compilation jobs to avoid saturating external USB I/O
export CARGO_BUILD_JOBS="${CARGO_BUILD_JOBS:-1}"

echo "==> Building Astra app bundle..."
pnpm run bundle:app

BUILD_TARGET_DIR="${CARGO_TARGET_DIR:-$REPO_ROOT/target}"
APP_BUNDLE="$BUILD_TARGET_DIR/debug/bundle/macos/Astra.app"

if [ -d "$APP_BUNDLE" ]; then
    IDENTITY="${APPLE_SIGNING_IDENTITY:-}"
    if [ -z "$IDENTITY" ]; then
        IDENTITY=$(security find-identity -v -p codesigning 2>/dev/null |
            sed -n 's/.*"\(Apple Development:[^"]*\)".*/\1/p' | head -n 1)
    fi
    if [ -z "$IDENTITY" ]; then
        IDENTITY="-"
        echo "==> No Apple Development certificate found; applying ad-hoc code signature..."
    else
        echo "==> Code-signing with identity: $IDENTITY..."
    fi

    ENTITLEMENTS_FLAG=()
    if [ -f "$REPO_ROOT/desktop/Entitlements.plist" ]; then
        ENTITLEMENTS_FLAG=(--entitlements "$REPO_ROOT/desktop/Entitlements.plist")
    fi

    codesign --force --deep --sign "$IDENTITY" "${ENTITLEMENTS_FLAG[@]}" --identifier app.astra "$APP_BUNDLE"

    echo "==> Installing Astra.app to /Applications/Astra.app..."
    rm -rf /Applications/Astra.app
    cp -R "$APP_BUNDLE" /Applications/Astra.app

    # Clear quarantine attribute if set
    xattr -cr /Applications/Astra.app 2>/dev/null || true

    # Keep a working backup on the external workspace if available
    if [ -d "/Volumes/AstraBuild" ]; then
        rm -rf "/Volumes/AstraBuild/Astra.app.working_backup" 2>/dev/null || true
        cp -R "/Applications/Astra.app" "/Volumes/AstraBuild/Astra.app.working_backup" 2>/dev/null || true
    fi

    echo "==> Astra.app installed and signed successfully!"
else
    echo "Error: Bundle not found at $APP_BUNDLE" >&2
    exit 1
fi
