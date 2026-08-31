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

# 1. Parse structured items and categories
let items = (
    $files
    | each { |f|
        let rel = ($f | str replace $"($root_dir)/" "")
        let parts = ($rel | split row "/")
        let cat = if ($parts | length) > 1 { $parts | first } else { "General" }
        let label = if ($parts | length) > 1 {
            $"📁 ($cat) / ($f | path basename)"
        } else {
            $"🖼️ ($f | path basename)"
        }
        { title: $label, full_path: $f, category: $cat, rel_path: $rel }
    }
)

let categories = ($items | where category != "General" | get category | uniq | sort)

# 2. Build quick actions
mut menu_entries = []

if ($items | length) > 1 {
    let total_count = ($items | length)
    $menu_entries = ($menu_entries | append {
        title: $"🎲 Random Wallpaper \(All ($total_count) images\)",
        action: "random_all",
        full_path: "",
        category: "Action"
    })
}

for cat in $categories {
    let cat_count = ($items | where category == $cat | length)
    $menu_entries = ($menu_entries | append {
        title: $"📁 Category: ($cat) \(($cat_count) images\)",
        action: $"filter_($cat)",
        full_path: "",
        category: "Filter"
    })
    $menu_entries = ($menu_entries | append {
        title: $"🎲 Random from ($cat)",
        action: $"random_($cat)",
        full_path: "",
        category: "Action"
    })
}

for item in $items {
    $menu_entries = ($menu_entries | append {
        title: $item.title,
        action: "select_file",
        full_path: $item.full_path,
        category: $item.category
    })
}

# 3. Present unified interactive picker in Vicinae
let selected_title = (
    $menu_entries
    | each { |e| $e.title }
    | str join (char nl)
    | ^vicinae dmenu -p "Search wallpapers or filter..."
    | str trim
)

if ($selected_title | is-empty) {
    exit 0
}

let picked_entry = ($menu_entries | where title == $selected_title | first)
if ($picked_entry == null) {
    exit 0
}

# 4. Resolve selected file based on action
mut final_file = ""

if $picked_entry.action == "random_all" {
    let chosen = ($items | shuffle | first)
    if ($chosen != null) { $final_file = $chosen.full_path }
} else if ($picked_entry.action | str starts-with "random_") {
    let cat = ($picked_entry.action | str replace "random_" "")
    let chosen = ($items | where category == $cat | shuffle | first)
    if ($chosen != null) { $final_file = $chosen.full_path }
} else if ($picked_entry.action | str starts-with "filter_") {
    let cat = ($picked_entry.action | str replace "filter_" "")
    let cat_items = ($items | where category == $cat)
    let sub_selected = (
        $cat_items
        | each { |i| $"🖼️ ($i.full_path | path basename)" }
        | str join (char nl)
        | ^vicinae dmenu -p $"Pick from ($cat)..."
        | str trim
    )
    if ($sub_selected | is-not-empty) {
        let chosen = ($cat_items | where { |i| $"🖼️ ($i.full_path | path basename)" == $sub_selected } | first)
        if ($chosen != null) { $final_file = $chosen.full_path }
    }
} else {
    $final_file = $picked_entry.full_path
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
    awww img $final_file --transition-type wave --transition-fps 144 --transition-duration 1.5
} else if (which swww | is-empty) == false {
    if (pgrep -x swww-daemon | is-empty) { job spawn { swww-daemon }; sleep 200ms }
    swww img $final_file --transition-type wave --transition-fps 144 --transition-duration 1.5
}

if (which matugen | is-empty) == false {
    matugen -t scheme-expressive image $final_file
    if (which notify-send | is-empty) == false {
        notify-send -u low "Wallpaper & Theme" $"Applied ($final_file | path basename)" -i $final_file
    }
}
