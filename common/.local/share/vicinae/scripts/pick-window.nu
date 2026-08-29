#!/usr/bin/env nu

# @vicinae.schemaVersion 1
# @vicinae.title Switch Window
# @vicinae.mode silent
# @vicinae.icon 🪟

# 1. Fetch active windows from Hyprland
let raw_clients = (hyprctl clients -j | from json)

if ($raw_clients | is-empty) {
    notify-send -u low "Window Switcher" "No active windows found."
    exit 0
}

# 2. Icon lookup helper
def get_icon [class: string] {
    let c = ($class | str lowercase)
    if ($c | str contains "ghostty") or ($c | str contains "terminal") or ($c | str contains "foot") {
        "󰞷"
    } else if ($c | str contains "zed") or ($c | str contains "code") or ($c | str contains "nvim") {
        "󰅩"
    } else if ($c | str contains "zen") or ($c | str contains "firefox") or ($c | str contains "chrome") or ($c | str contains "brave") {
        "󰈹"
    } else if ($c | str contains "spotify") or ($c | str contains "fastpotify") or ($c | str contains "feishin") {
        ""
    } else if ($c | str contains "vesktop") or ($c | str contains "discord") {
        "󰙯"
    } else if ($c | str contains "steam") {
        "󰓓"
    } else if ($c | str contains "nautilus") or ($c | str contains "thunar") or ($c | str contains "yazi") {
        "󰉋"
    } else if ($c | str contains "btop") {
        "󰄛"
    } else {
        "󰣆"
    }
}

# 3. Format entries sorted by most recently focused (focusHistoryID)
let windows = (
    $raw_clients
    | where mapped == true and hidden == false
    | sort-by focusHistoryID
    | each { |w|
        let icon = (get_icon $w.class)
        let ws_raw = $w.workspace.name
        let ws_label = (if ($ws_raw | str starts-with "special:") {
            $ws_raw | str replace "special:" "󰄛 "
        } else {
            $"WS ($ws_raw)"
        })
        let title = (if ($w.title | is-empty) { $w.class } else { $w.title })
        let clean_title = ($title | str replace -a "\n" " ")
        {
            display: $"[($ws_label)]  ($icon)  ($clean_title)  —  ($w.class)"
            address: $w.address
            workspace: $ws_raw
        }
    }
)

# 4. Present in Vicinae interactive dmenu
let display_lines = ($windows | each { |w| $w.display } | str join (char nl))
let selection = (
    $display_lines
    | ^vicinae dmenu -p "Switch window..."
    | str trim
)

if ($selection | is-empty) {
    exit 0
}

# 5. Find target address and focus window via Hyprland Lua dispatch
let chosen = ($windows | where display == $selection | first)

if ($chosen != null) {
    if ($chosen.workspace | str starts-with "special:") {
        let ws_cmd = ('hl.dsp.focus({ workspace = "' + $chosen.workspace + '" })')
        hyprctl dispatch $ws_cmd
    }
    let win_cmd = ('hl.dsp.focus({ window = "address:' + $chosen.address + '" })')
    hyprctl dispatch $win_cmd
}
