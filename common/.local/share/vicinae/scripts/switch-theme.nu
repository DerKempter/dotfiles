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
    if (which notify-send | is-empty) == false {
        ^notify-send -u critical "Theme Switcher" "No current wallpaper found in cache."
    }
    exit 1
}

let profile_choices = [
    "Profile: Expressive (Android Material You)",
    "Profile: Fruit Salad (Playful & High Contrast)",
    "Profile: Vibrant (Vivid & Saturated)",
    "Profile: Rainbow (Full Spectrum)",
    "Profile: Fidelity (Exact Image Colors)",
    "Profile: Content (Balanced Nuance)",
    "Profile: Tonal Spot (Classic Material)",
    "Profile: Monochrome (Minimal Grayscale)",
]

let raw_colors = (
    try {
        ^matugen image --show-source-colors $current_wall | lines | str trim | where ($it | str starts-with "#")
    } catch {
        []
    }
)

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

let base_choices = ["Mode: Dark Mode", "Mode: Light Mode", "Custom: Hex Color Code"]

let all_choices = ($profile_choices | append $color_choices | append $base_choices)
let selected = ($all_choices | str join (char nl) | ^vicinae dmenu -p "Select Theme Style or Accent..." | str trim)

if ($selected | is-empty) {
    exit 0
}

let notify = { |title, msg|
    if (which notify-send | is-empty) == false {
        ^notify-send -u low $title $msg -a "Matugen"
    }
}

if ($selected | str starts-with "Profile: ") {
    let type_map = {
        "Profile: Expressive (Android Material You)": "scheme-expressive",
        "Profile: Fruit Salad (Playful & High Contrast)": "scheme-fruit-salad",
        "Profile: Vibrant (Vivid & Saturated)": "scheme-vibrant",
        "Profile: Rainbow (Full Spectrum)": "scheme-rainbow",
        "Profile: Fidelity (Exact Image Colors)": "scheme-fidelity",
        "Profile: Content (Balanced Nuance)": "scheme-content",
        "Profile: Tonal Spot (Classic Material)": "scheme-tonal-spot",
        "Profile: Monochrome (Minimal Grayscale)": "scheme-monochrome",
    }
    let stype = ($type_map | get -i $selected | default "scheme-expressive")
    ^matugen -t $stype image $current_wall
    do $notify "Theme Updated" $"Applied ($selected | split row '(' | get 0 | str trim)"
} else if ($selected | str starts-with "#") {
    let hex = ($selected | split row " " | get 0)
    ^matugen color hex $hex
    do $notify "Theme Updated" $"Applied accent: ($hex)"
} else if $selected == "Mode: Dark Mode" {
    ^matugen -m dark -t scheme-expressive image $current_wall
    do $notify "Theme Updated" "Switched to Dark Mode"
} else if $selected == "Mode: Light Mode" {
    ^matugen -m light -t scheme-expressive image $current_wall
    do $notify "Theme Updated" "Switched to Light Mode"
} else if $selected == "Custom: Hex Color Code" {
    let hex = (^vicinae dmenu -p "Enter hex (e.g. ff007f)..." | str trim | str replace -r '^#' '')
    if ($hex | is-not-empty) {
        ^matugen color hex $"#($hex)"
        do $notify "Theme Updated" $"Applied accent: #($hex)"
    }
}
