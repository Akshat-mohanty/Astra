#!/usr/bin/env bash
# Source this file to activate the Astra build environment:
# source scripts/env.sh

export ASTRA_BUILD_ROOT="/Volumes/AstraBuild"
export DEPOT_TOOLS_PATH="$ASTRA_BUILD_ROOT/depot_tools"

if [ ! -d "$ASTRA_BUILD_ROOT" ]; then
    echo "Warning: $ASTRA_BUILD_ROOT is not mounted. Run ./scripts/mount_drive.sh first."
else
    export PATH="$DEPOT_TOOLS_PATH/.cipd_bin:$DEPOT_TOOLS_PATH:/opt/homebrew/bin:$PATH"
    export VPX_DISABLE_PIC=1
    echo "Astra build environment activated."
    echo "  - gclient: $(which gclient 2>/dev/null || echo 'not found')"
    echo "  - gn:      $(which gn 2>/dev/null || echo 'not found')"
    echo "  - ninja:   $(which ninja 2>/dev/null || echo 'not found')"
fi
