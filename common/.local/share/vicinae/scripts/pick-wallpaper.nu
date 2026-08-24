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

if ($img | is-not-empty) {
    ^caelestia wallpaper -f $img
}
