#!/usr/bin/env bash
# gamemode-daemon.sh - Manual daemon start for GameMode (optional)
# Some games or launchers may need GameMode started manually.

GAMEMODE=$(command -v gamemoded 2>/dev/null || command -v gamemode 2>/dev/null)

if [ -z "$GAMEMODE" ]; then
    echo "GameMode not found. Install via: sudo pacman -S gamemode"
    exit 1
fi

echo "Starting GameMode daemon..."
"$GAMEMODE" &
sleep 1
echo "GameMode daemon started (PID: $!)"