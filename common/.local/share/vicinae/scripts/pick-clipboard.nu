#!/usr/bin/env nu

# @vicinae.schemaVersion 1
# @vicinae.title Clipboard History
# @vicinae.mode silent
# @vicinae.icon 📋

# 1. Fetch cliphist entries
let history_raw = (cliphist list | str trim)

if ($history_raw | is-empty) {
    notify-send -u low "Clipboard" "Clipboard history is empty."
    exit 0
}

# 2. Present interactive list in Vicinae dmenu
let selection = (
    $history_raw
    | ^vicinae dmenu -p "Search clipboard history..." -n "Clipboard History"
    | str trim
)

if ($selection | is-empty) {
    exit 0
}

# 3. Decode selected item and copy to system clipboard
$selection | cliphist decode | wl-copy
