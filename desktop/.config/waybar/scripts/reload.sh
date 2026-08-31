#!/usr/bin/env bash
# Cleanly terminate orphaned streaming helpers before sending reload signal
pkill -f "swaync-client -swb" 2>/dev/null || true
if systemctl --user is-active --quiet waybar.service; then
    systemctl --user reload waybar.service
elif pgrep -x waybar >/dev/null; then
    killall -SIGUSR2 waybar 2>/dev/null || true
else
    systemctl --user start waybar.service 2>/dev/null || waybar >/dev/null 2>&1 &
fi
