#!/usr/bin/env nu

# @vicinae.schemaVersion 1
# @vicinae.title Switch Theme Accent
# @vicinae.mode silent
# @vicinae.icon 🎨

let current_wall = (if ("~/.cache/current_wallpaper" | path exists) {
    "~/.cache/current_wallpaper" | path expand
} else {
    ""
})

if ($current_wall | is-empty) {
    ^notify-send -u critical "Theme Switcher" "No current wallpaper found in cache."
    exit 1
}

let raw_colors = (
    try {
        ^matugen image --show-source-colors $current_wall | lines | str trim | where ($it | str starts-with "#")
    } catch {
        []
    }
)

let base_choices = ["Dark Mode", "Light Mode", "Custom Hex"]
let color_choices = (
    $raw_colors
    | enumerate
    | each { |row|
        match $row.index {
            0 => $"($row.item) - Dominant Accent",
            1 => $"($row.item) - Vibrant Accent",
            2 => $"($row.item) - Secondary Accent",
            _ => $"($row.item) - Palette Accent ($row.index + 1)"
        }
    }
)

let all_choices = ($color_choices | append $base_choices)
let selected = ($all_choices | str join (char nl) | ^vicinae dmenu -p "Select Theme or Accent..." | str trim)

if ($selected | is-empty) {
    exit 0
}

if ($selected | str starts-with "#") {
    let hex = ($selected | split row " " | get 0)
    ^matugen hex $hex
    ^notify-send -u low "Theme Updated" $"Applied accent: ($hex)" -a "Matugen"
} else if $selected == "Dark Mode" {
    ^matugen -m dark image $current_wall
    ^notify-send -u low "Theme Updated" "Switched to Dark Mode" -a "Matugen"
} else if $selected == "Light Mode" {
    ^matugen -m light image $current_wall
    ^notify-send -u low "Theme Updated" "Switched to Light Mode" -a "Matugen"
} else if $selected == "Custom Hex" {
    let hex = (^vicinae dmenu -p "Enter hex (e.g. ff007f)..." | str trim | str replace -r '^#' '')
    if ($hex | is-not-empty) {
        ^matugen hex $"#($hex)"
        ^notify-send -u low "Theme Updated" $"Applied accent: #($hex)" -a "Matugen"
    }
}
