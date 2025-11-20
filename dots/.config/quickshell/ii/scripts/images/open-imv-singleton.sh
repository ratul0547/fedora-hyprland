#!/bin/bash
# Helper script to open images in a singleton imv instance
# Kills any existing imv process before launching new one

IMAGE="$1"

# Check if image file exists
if [ ! -f "$IMAGE" ]; then
    exit 1
fi

# Kill any existing imv process and wait for it to terminate
pkill -x imv 2>/dev/null
sleep 0.1

# Launch new imv instance
imv "$IMAGE" >/dev/null 2>&1 &
