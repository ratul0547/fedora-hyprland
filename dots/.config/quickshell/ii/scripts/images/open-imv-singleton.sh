#!/bin/bash
# Helper script to open images in a singleton imv instance
# Kills any existing imv process before launching new one

IMAGE="$1"

# Kill any existing imv process
pkill -x imv 2>/dev/null

# Launch new imv instance
imv "$IMAGE" &
