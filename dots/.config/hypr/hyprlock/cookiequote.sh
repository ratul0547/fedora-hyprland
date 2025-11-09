#!/usr/bin/env bash

# Get a fortune cookie quote or fallback message
if command -v fortune &> /dev/null; then
    fortune -s 2>/dev/null || echo "Fortune favors the bold"
else
    echo "Fortune favors the bold"
fi
