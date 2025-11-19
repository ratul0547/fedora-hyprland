#!/bin/bash
# Helper script to open images in a singleton imv instance
# Uses imv's Unix socket IPC to send images to existing instance

IMAGE="$(realpath "$1")"

# Find existing imv socket
SOCKET_DIR="${XDG_RUNTIME_DIR:-/tmp}"
SOCKET=$(find "$SOCKET_DIR" -maxdepth 1 -name "imv-*.sock" 2>/dev/null | head -n1)

if [ -n "$SOCKET" ] && [ -S "$SOCKET" ]; then
    # Socket exists - send to existing instance
    imv-msg "$SOCKET" close all 2>/dev/null || true
    imv-msg "$SOCKET" open "$IMAGE" 2>/dev/null || true
else
    # No existing instance - launch new one
    imv "$IMAGE" &
fi
