#!/usr/bin/env nu

# @vicinae.schemaVersion 1
# @vicinae.title Switch Theme
# @vicinae.mode silent
# @vicinae.icon 🎨

let choices = ["Dark Mode", "Light Mode", "Custom Hex"]
let selected = ($choices | str join (char nl) | ^vicinae dmenu -p "Select Theme..." | str trim)

match $selected {
    "Dark Mode" => {
        ^caelestia scheme set -m dark
        ^notify-send -u low "Theme Updated" "Switched to Dark Mode" -a "Caelestia"
    }
    "Light Mode" => {
        ^caelestia scheme set -m light
        ^notify-send -u low "Theme Updated" "Switched to Light Mode" -a "Caelestia"
    }
    "Custom Hex" => {
        let hex = (^vicinae dmenu -p "Enter hex (e.g. ff007f)..." | str trim | str replace -r '^#' '')
        if ($hex | is-not-empty) {
            ^caelestia scheme set -c $"#($hex)"
            ^notify-send -u low "Theme Updated" $"Applied accent: #($hex)" -a "Caelestia"
        }
    }
    _ => {}
}
