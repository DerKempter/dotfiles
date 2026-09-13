#!/usr/bin/env nu

# @vicinae.schemaVersion 1
# @vicinae.title Power & Session Menu
# @vicinae.mode silent
# @vicinae.icon ⏻

let options = [
    { label: "  Lock Screen",        action: "hyprlock" },
    { label: "󰤄  Suspend / Sleep",    action: "systemctl suspend" },
    { label: "󰜉  Restart / Reboot",    action: "systemctl reboot" },
    { label: "  Power Off / Shutdown", action: "systemctl poweroff" },
    { label: "󰗽  Log Out (Exit Hyprland)", action: "hyprctl dispatch exit" },
    { label: "󰒲  Hibernate",          action: "systemctl hibernate" },
]

let selection = (
    $options
    | each { |o| $o.label }
    | str join (char nl)
    | ^vicinae dmenu -p "Power & Session..."
    | str trim
)

if ($selection | is-empty) {
    exit 0
}

let chosen = ($options | where label == $selection | first)

if ($chosen != null) {
    job spawn { ^bash -c $chosen.action }
}
