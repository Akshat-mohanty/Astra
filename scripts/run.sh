#!/usr/bin/env bash
set -e

APP="/Applications/Astra.app"

if [ -d "$APP" ]; then
    echo "🚀 Launching Astra..."
    open "$APP"
else
    echo "❌ Error: Astra.app not found at $APP"
    exit 1
fi
