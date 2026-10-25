#!/usr/bin/env bash
set -e

SRC_DIR="/Users/akshatmohanty/Astra"
APP_FRAMEWORKS="/Applications/Astra.app/Contents/Frameworks"
APP_MACOS="/Applications/Astra.app/Contents/MacOS"

echo "Compiling native Rust launcher..."
export PATH="$HOME/.cargo/bin:$PATH"
(cd "$SRC_DIR" && cargo build --release)
cp "$SRC_DIR/target/release/astra" "$APP_MACOS/Astra"
codesign -s - -f "$APP_MACOS/Astra"

echo "Compiling libastra_hook.dylib..."
clang -dynamiclib -O2 -fobjc-arc \
    -framework Cocoa -framework QuartzCore \
    -arch arm64 \
    -install_name "$APP_FRAMEWORKS/libastra_hook.dylib" \
    "$SRC_DIR/src/astra_hook.m" \
    -o "$APP_FRAMEWORKS/libastra_hook.dylib"

echo "Signing libastra_hook.dylib..."
codesign -s - -f "$APP_FRAMEWORKS/libastra_hook.dylib"

echo "Syncing newtab resources..."
cp -R "$SRC_DIR/src/newtab/"* "/Applications/Astra.app/Contents/Resources/newtab/"

echo "Patching pak..."
python3 "$SRC_DIR/scripts/patch_pak.py"

echo "Re-signing Astra.app..."
codesign --force --deep --sign - /Applications/Astra.app

echo "Build hook complete!"
