#!/bin/bash
# Helper script to open images in a singleton imv instance
# Uses imv's Unix socket IPC to send images to existing instance

IMAGE="$1"

# Find existing imv socket
SOCKET=$(ls ${XDG_RUNTIME_DIR:-/tmp}/imv-*.sock 2>/dev/null | head -n1)

if [ -n "$SOCKET" ]; then
    # Send to existing instance - close all first, then open new
    imv-msg "$SOCKET" close all 2>/dev/null
    imv-msg "$SOCKET" open "$IMAGE" 2>/dev/null
else
    # Launch new instance
    imv "$IMAGE" &
fi
