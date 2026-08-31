#!/usr/bin/env nu

# @vicinae.schemaVersion 1
# @vicinae.title Select Wallpaper
# @vicinae.mode silent
# @vicinae.icon 🖼️

let xdg_pictures = if (which xdg-user-dir | is-not-empty) {
    try { ^xdg-user-dir PICTURES | str trim } catch { "" }
} else { "" }

let wall_dirs = [
    ($xdg_pictures | path join "Wallpapers"),
    "~/Pictures/Wallpapers",
    "~/Bilder/Wallpapers",
    "~/Wallpapers",
]
| where { |dir| ($dir | is-not-empty) and (($dir | path expand) | path exists) }
| each { |dir| $dir | path expand }
| uniq

let general_dirs = [
    $xdg_pictures,
    "~/Pictures",
    "~/Bilder",
]
| where { |dir| ($dir | is-not-empty) and (($dir | path expand) | path exists) }
| each { |dir| $dir | path expand }
| uniq

let wall_files = (
    $wall_dirs
    | each { |dir| glob $"($dir)/**/*.{png,jpg,jpeg,webp,PNG,JPG,JPEG,WEBP}" }
    | flatten
    | uniq
)

let files = if ($wall_files | is-not-empty) {
    $wall_files
} else {
    $general_dirs
    | each { |dir| glob $"($dir)/**/*.{png,jpg,jpeg,webp,PNG,JPG,JPEG,WEBP}" }
    | flatten
    | uniq
} | sort

if ($files | is-empty) {
    print -e "No wallpapers found in ~/Pictures/Wallpapers or ~/Bilder/Wallpapers"
    exit 1
}

let img = (
    $files
    | str join (char nl)
    | ^vicinae dmenu -p "Pick a wallpaper..."
    | str trim
)

if ($img | is-empty) {
    exit 0
}

let full_path = ($img | path expand)

# 1. Update cache symlink
mkdir $"($env.HOME)/.cache"
ln -sf $full_path $"($env.HOME)/.cache/current_wallpaper"

# 2. Update wallpaper depending on DE/compositor
if (which plasma-apply-wallpaperimage | is-empty) == false {
    plasma-apply-wallpaperimage $full_path
} else if (which awww | is-empty) == false {
    if (pgrep -x awww-daemon | is-empty) { job spawn { awww-daemon }; sleep 200ms }
    awww img $full_path --transition-type wave --transition-fps 144 --transition-duration 1.5
} else if (which swww | is-empty) == false {
    if (pgrep -x swww-daemon | is-empty) { job spawn { swww-daemon }; sleep 200ms }
    swww img $full_path --transition-type wave --transition-fps 144 --transition-duration 1.5
}

# 3. Extract Material 3 colors and generate theme (defaulting to Expressive)
if (which matugen | is-empty) == false {
    matugen -t scheme-expressive image $full_path
    if (which notify-send | is-empty) == false {
        notify-send -u low "Wallpaper & Theme" $"Applied ($full_path | path basename)" -i $full_path
    }
}
