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

let root_dir = if ($wall_dirs | is-not-empty) {
    $wall_dirs | first
} else if ($general_dirs | is-not-empty) {
    $general_dirs | first
} else {
    ""
}

if ($root_dir | is-empty) or not ($root_dir | path exists) {
    if (which notify-send | is-empty) == false {
        ^notify-send -u critical "Wallpaper Picker" "No wallpapers directory found."
    }
    exit 1
}

let files = (glob $"($root_dir)/**/*.{png,jpg,jpeg,webp,PNG,JPG,JPEG,WEBP}" | sort)

if ($files | is-empty) {
    if (which notify-send | is-empty) == false {
        ^notify-send -u critical "Wallpaper Picker" $"No images found in ($root_dir)"
    }
    exit 1
}

# 1. Discover subcategories
let categories = (
    $files
    | each { |f|
        let rel = ($f | str replace $"($root_dir)/" "")
        let parts = ($rel | split row "/")
        if ($parts | length) > 1 { $parts | first } else { null }
    }
    | compact
    | uniq
    | sort
)

# 2. Build menu with Quick Random actions followed by real image file paths for Quick Look previews
mut menu_entries = ["🎲 Random Wallpaper (All)"]

for cat in $categories {
    $menu_entries = ($menu_entries | append $"🎲 Random from ($cat)")
}

$menu_entries = ($menu_entries | append $files)

# 3. Present interactive picker in Vicinae
let selected = (
    $menu_entries
    | str join (char nl)
    | ^vicinae dmenu -p "Search wallpapers by name or category..."
    | str trim
)

if ($selected | is-empty) {
    exit 0
}

# 4. Resolve selected entry
let final_file = if $selected == "🎲 Random Wallpaper (All)" or $selected == "🎲 Random Wallpaper" {
    $files | shuffle | first
} else if ($selected | str starts-with "🎲 Random from ") {
    let cat = ($selected | str replace "🎲 Random from " "")
    let cat_files = (
        $files
        | where { |f|
            let rel = ($f | str replace $"($root_dir)/" "")
            let parts = ($rel | split row "/")
            ($parts | length) > 1 and ($parts | first) == $cat
        }
    )
    if ($cat_files | is-not-empty) {
        $cat_files | shuffle | first
    } else {
        $files | shuffle | first
    }
} else {
    $selected
}

if ($final_file | is-empty) or not ($final_file | path exists) {
    exit 0
}

# 5. Apply Wallpaper & Dynamic Expressive Theme
mkdir $"($env.HOME)/.cache"
ln -sf $final_file $"($env.HOME)/.cache/current_wallpaper"

if (which plasma-apply-wallpaperimage | is-empty) == false {
    plasma-apply-wallpaperimage $final_file
} else if (which awww | is-empty) == false {
    if (pgrep -x awww-daemon | is-empty) { job spawn { awww-daemon }; sleep 200ms }
    awww img $final_file --transition-type random --transition-fps 144 --transition-duration 1.5
} else if (which swww | is-empty) == false {
    if (pgrep -x swww-daemon | is-empty) { job spawn { swww-daemon }; sleep 200ms }
    swww img $final_file --transition-type random --transition-fps 144 --transition-duration 1.5
}

if (which matugen | is-empty) == false {
    matugen -t scheme-expressive image $final_file
    if (which notify-send | is-empty) == false {
        notify-send -u low "Wallpaper & Theme" $"Applied ($final_file | path basename)" -i $final_file
    }
}
