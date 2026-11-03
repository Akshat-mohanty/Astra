#!/usr/bin/env bash
set -e

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

echo "==> Building Astra app bundle..."
pnpm run bundle:app

APP_BUNDLE="$REPO_ROOT/target/debug/bundle/macos/Astra.app"

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

    echo "==> Astra.app installed and signed successfully!"
else
    echo "Error: Bundle not found at $APP_BUNDLE" >&2
    exit 1
fi
