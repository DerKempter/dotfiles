#!/usr/bin/env bash
# Cleanly terminate orphaned streaming helpers before sending SIGUSR2 to prevent deadlocks
pkill -f "swaync-client -swb" 2>/dev/null || true
killall -SIGUSR2 waybar 2>/dev/null || true
