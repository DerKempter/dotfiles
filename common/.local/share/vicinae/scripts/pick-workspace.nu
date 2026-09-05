#!/usr/bin/env nu

# @vicinae.schemaVersion 1
# @vicinae.title Switch Workspace
# @vicinae.mode silent
# @vicinae.icon 🗂️

# 1. Fetch current Hyprland state
let raw_workspaces = (hyprctl workspaces -j | from json)
let raw_clients = (hyprctl clients -j | from json)
let active_ws = (hyprctl activeworkspace -j | from json | get -o name)

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
    } else if ($c | str contains "equibop") or ($c | str contains "vesktop") or ($c | str contains "discord") {
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

# 3. Known Special Workspaces list
let special_defs = [
    { id: "special:music", name: "music", title: "Music", icon: "", desc: "Fastpotify / Music Player" }
    { id: "special:sysmon", name: "sysmon", title: "Sysmon", icon: "󰄛", desc: "btop / System Monitor" }
    { id: "special:communication", name: "communication", title: "Communication", icon: "󰙯", desc: "Discord / Equibop" }
    { id: "special:todo", name: "todo", title: "Todo", icon: "󰠲", desc: "Todo / Tasks Workspace" }
    { id: "special:special", name: "specialws", title: "Scratchpad", icon: "󰄛", desc: "General Scratchpad" }
]

# 4. Build standard numbered workspaces (1..10)
let numbered_entries = (
    1..10
    | each { |num|
        let ws_str = ($num | into string)
        let ws_info = ($raw_workspaces | where name == $ws_str | get -o 0)
        let clients_in_ws = ($raw_clients | where workspace.name == $ws_str and mapped == true)
        
        let client_summary = (
            if ($clients_in_ws | is-empty) {
                "Empty"
            } else {
                $clients_in_ws
                | each { |c|
                    let ico = (get_icon $c.class)
                    let name = (if ($c.initialTitle | is-empty) { $c.class } else { $c.initialTitle })
                    $"($ico) ($name)"
                }
                | uniq
                | str join "   "
            }
        )
        
        let status = (if $active_ws == $ws_str { " ● Active" } else { "" })
        let mon = (if $ws_info != null { $" [($ws_info.monitor)]" } else { "" })

        {
            display: $"[Workspace ($num)]($mon)  ($client_summary)($status)"
            target: $ws_str
            is_special: false
            special_name: ""
            active: ($active_ws == $ws_str)
            has_clients: ($clients_in_ws | is-not-empty)
        }
    }
)

# 5. Build special workspaces
let special_entries = (
    $special_defs
    | each { |sp|
        let clients_in_ws = ($raw_clients | where workspace.name == $sp.id and mapped == true)
        let client_summary = (
            if ($clients_in_ws | is-empty) {
                $sp.desc
            } else {
                $clients_in_ws
                | each { |c|
                    let ico = (get_icon $c.class)
                    let name = (if ($c.initialTitle | is-empty) { $c.class } else { $c.initialTitle })
                    $"($ico) ($name)"
                }
                | uniq
                | str join "   "
            }
        )
        let status = (if $active_ws == $sp.id { " ● Active" } else { "" })

        {
            display: $"[󰄛 ($sp.title)]  ($sp.icon)  ($client_summary)($status)"
            target: $sp.id
            is_special: true
            special_name: $sp.name
            active: ($active_ws == $sp.id)
            has_clients: ($clients_in_ws | is-not-empty)
        }
    }
)

# Combine: Active/Populated workspaces first, then special workspaces, then empty numbered workspaces
let populated = ($numbered_entries | where has_clients == true)
let empty = ($numbered_entries | where has_clients == false)
let all_workspaces = ($populated | append $special_entries | append $empty)

# 6. Present in Vicinae interactive dmenu
let display_lines = ($all_workspaces | each { |w| $w.display } | str join (char nl))
let selection = (
    $display_lines
    | ^vicinae dmenu -p "Switch workspace..."
    | str trim
)

if ($selection | is-empty) {
    exit 0
}

# 7. Focus target workspace or invoke special workspace launcher
let chosen = ($all_workspaces | where display == $selection | first)

if ($chosen != null) {
    if $chosen.is_special {
        # Trigger Hyprland's native toggle function to spawn configured apps (e.g. vesktop, fastpotify, btop)
        let eval_cmd = ("require('utils.functions').toggle('" + $chosen.special_name + "')()")
        hyprctl eval $eval_cmd
    } else {
        let cmd = ('hl.dsp.focus({ workspace = "' + $chosen.target + '" })')
        hyprctl dispatch $cmd
    }
}
