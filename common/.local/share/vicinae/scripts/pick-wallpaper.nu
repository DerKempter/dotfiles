#!/usr/bin/env nu

# @vicinae.schemaVersion 1
# @vicinae.title Select Wallpaper
# @vicinae.mode silent
# @vicinae.icon 🖼️

let img = (
    glob ~/Pictures/Wallpapers/**/*.{png,jpg,jpeg,webp}
    | str join (char nl)
    | ^vicinae dmenu -p "Pick a wallpaper..."
    | str trim
)

if ($img | is-empty) {
    exit 0
}

let full_path = ($img | path expand)

# 1. Update hyprlock fast cache symlink
mkdir $"($env.HOME)/.cache"
ln -sf $full_path $"($env.HOME)/.cache/current_wallpaper"

# 2. Update wallpaper via awww/swww
if (which awww | is-empty) == false {
    if (pgrep -x awww-daemon | is-empty) { job spawn { awww-daemon }; sleep 200ms }
    awww img $full_path --transition-type wave --transition-fps 144 --transition-duration 1.5
} else if (which swww | is-empty) == false {
    if (pgrep -x swww-daemon | is-empty) { job spawn { swww-daemon }; sleep 200ms }
    swww img $full_path --transition-type wave --transition-fps 144 --transition-duration 1.5
}

# 3. Extract Material 3 colors and generate theme
if (which matugen | is-empty) == false {
    matugen image $full_path
    notify-send -u low "Wallpaper & Theme" $"Applied ($full_path | path basename)" -i $full_path
}
