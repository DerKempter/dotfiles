# Desktop wallpaper and dynamic theming helper

def get-wallpaper-root [] {
    let xdg_pictures = if (which xdg-user-dir | is-not-empty) {
        try { ^xdg-user-dir PICTURES | str trim } catch { "" }
    } else { "" }

    let wall_dirs = [
        ($xdg_pictures | path join "Wallpapers"),
        "~/Pictures/Wallpapers",
        "~/Bilder/Wallpapers",
        "~/Wallpapers",
        $xdg_pictures,
        "~/Pictures",
        "~/Bilder",
    ]
    | where { |dir| ($dir | is-not-empty) and (($dir | path expand) | path exists) }
    | each { |dir| $dir | path expand }
    | uniq

    $wall_dirs | first | default ""
}

# Completions for wallpaper targets (files, categories, actions)
def "nu-complete wallpaper targets" [] {
    let root = (get-wallpaper-root)
    if ($root | is-empty) { return [] }
    let files = (glob $"($root)/**/*.{png,jpg,jpeg,webp,PNG,JPG,JPEG,WEBP}" | sort)

    let base_options = [
        { value: "random", description: "Pick a random wallpaper" },
        { value: "pick", description: "Interactive fuzzy picker with live terminal preview" },
        { value: "preview", description: "Show terminal preview of current or specified wallpaper" },
        { value: "list", description: "List all wallpapers and categories" },
    ]

    let categories = (
        $files
        | each { |f|
            let rel = ($f | str replace $"($root)/" "")
            let parts = ($rel | split row "/")
            if ($parts | length) > 1 { $parts | first } else { null }
        }
        | compact
        | uniq
        | sort
        | each { |cat| { value: $cat, description: $"Category: ($cat)" } }
    )

    let wallpapers = (
        $files
        | each { |f|
            let rel = ($f | str replace $"($root)/" "")
            { value: $rel, description: ($f | path basename) }
        }
    )

    $base_options | append $categories | append $wallpapers
}

# Completions for wallpaper categories
def "nu-complete wallpaper categories" [] {
    let root = (get-wallpaper-root)
    if ($root | is-empty) { return [] }
    glob $"($root)/**/*.{png,jpg,jpeg,webp,PNG,JPG,JPEG,WEBP}"
    | each { |f|
        let rel = ($f | str replace $"($root)/" "")
        let parts = ($rel | split row "/")
        if ($parts | length) > 1 { $parts | first } else { null }
    }
    | compact
    | uniq
    | sort
}

# Completions for theme scheme profiles
def "nu-complete theme types" [] {
    [
        { value: "expressive", description: "Android Material You default (vibrant & complementary)" },
        { value: "fruit-salad", description: "Playful & punchy high-contrast" },
        { value: "vibrant", description: "Maximum saturation & vividness" },
        { value: "rainbow", description: "Full spectrum palette" },
        { value: "fidelity", description: "Strict image color fidelity" },
        { value: "content", description: "Nuanced image content colors" },
        { value: "tonal-spot", description: "Classic balanced Material You" },
        { value: "monochrome", description: "Minimal grayscale" },
    ]
}

# Completions for theme switcher
def "nu-complete theme styles" [] {
    let profiles = (nu-complete theme types)
    let modes = [
        { value: "dark", description: "Switch to Dark Mode" },
        { value: "light", description: "Switch to Light Mode" },
    ]
    let current_wall = (if ("~/.cache/current_wallpaper" | path exists) { "~/.cache/current_wallpaper" | path expand } else { "" })
    let colors = if ($current_wall | is-not-empty) {
        try {
            ^matugen image --show-source-colors $current_wall
            | lines
            | str trim
            | where ($it | str starts-with "#")
            | enumerate
            | each { |r|
                let idx = $r.index + 1
                { value: $r.item, description: $"Extracted source accent ($idx)" }
            }
        } catch { [] }
    } else { [] }

    $profiles | append $modes | append $colors
}

# Helper to render a clean ANSI text preview with chafa (avoids GPU overlay persistence)
def render-image-preview [img_path: string, size: string = "50x20"] {
    if (which chafa | is-empty) or not ($img_path | path exists) { return }
    try {
        ^chafa --format=symbols -s $size $img_path
    } catch { }
}

# Set desktop wallpaper and generate matching dynamic theme
export def wallpaper [
    target?: string@"nu-complete wallpaper targets"         # Image path, category name, relative name, "random", "pick", "preview", or "list"
    category?: string@"nu-complete wallpaper categories"   # Category or target for random/preview
    --type (-t): string@"nu-complete theme types" = "scheme-expressive" # Scheme profile
    --pick (-p)                                             # Interactive fuzzy picker with live terminal preview
] {
    let root = (get-wallpaper-root)
    let files = if ($root | is-not-empty) {
        glob $"($root)/**/*.{png,jpg,jpeg,webp,PNG,JPG,JPEG,WEBP}" | sort
    } else {
        []
    }

    # Normalize scheme type if short name was given
    let stype = if ($type | str starts-with "scheme-") {
        $type
    } else {
        $"scheme-($type)"
    }

    let target_str = ($target | default "")
    let target_lower = ($target_str | str lowercase)

    # Handle interactive fuzzy picker with live preview
    if $pick or $target_lower == "pick" or $target_lower == "select" or $target_lower == "fzf" {
        if ($files | is-empty) {
            print -e "No wallpapers found."
            return
        }
        if (which fzf | is-empty) {
            print -e "Error: fzf is not installed. Install fzf for interactive wallpaper selection."
            return
        }

        let preview_cmd = if (which chafa | is-not-empty) {
            "chafa --format=symbols -s 50x25 {} 2>/dev/null"
        } else {
            "file {}"
        }

        let chosen = (
            $files
            | str join (char nl)
            | ^fzf --preview=$preview_cmd --preview-window=right:50% --header="[Enter] Apply Wallpaper | [Esc] Cancel"
            | str trim
        )

        if ($chosen | is-empty) {
            return
        }

        wallpaper $chosen --type $stype
        return
    }

    # Handle "preview" subcommand
    if $target_lower == "preview" {
        let prev_target = if ($category | is-not-empty) {
            $category
        } else if ("~/.cache/current_wallpaper" | path exists) {
            "~/.cache/current_wallpaper" | path expand
        } else {
            ""
        }

        if ($prev_target | is-empty) {
            print -e "No wallpaper specified and no current wallpaper found."
            return
        }

        let direct = ($prev_target | path expand)
        let resolved = if ($direct | path exists) {
            $direct
        } else {
            # Find in wallpapers
            let match = ($files | where { |f| ($f | str lowercase) | str contains ($prev_target | str lowercase) } | first)
            $match | default ""
        }

        if ($resolved | is-empty) or not ($resolved | path exists) {
            print -e $"Error: Could not find wallpaper matching '($prev_target)'."
            return
        }

        print $"Previewing: ($resolved | path basename)"
        render-image-preview $resolved "55x20"
        return
    }

    # Handle "list" or empty argument
    if $target_lower == "list" or ($target | is-empty) {
        if ($files | is-empty) {
            print -e "No wallpapers found."
            return
        }
        print $"Wallpapers Directory: ($root)"
        print ""
        let table_data = (
            $files | each { |f|
                let rel = ($f | str replace $"($root)/" "")
                let parts = ($rel | split row "/")
                let cat = if ($parts | length) > 1 { $parts | first } else { "General" }
                { Category: $cat, File: ($f | path basename), Path: $rel }
            }
        )
        return $table_data
    }

    # Handle "random"
    mut resolved_path = ""
    if $target_lower == "random" {
        if ($files | is-empty) {
            print -e "No wallpapers found."
            return
        }
        if ($category | is-not-empty) {
            let cat_lower = ($category | str lowercase)
            let cat_files = ($files | where { |f|
                let rel = ($f | str replace $"($root)/" "")
                let parts = ($rel | split row "/")
                ($parts | length) > 1 and (($parts | first | str lowercase) == $cat_lower)
            })
            if ($cat_files | is-empty) {
                print -e $"No wallpapers found in category '($category)'"
                return
            }
            $resolved_path = ($cat_files | shuffle | first)
        } else {
            $resolved_path = ($files | shuffle | first)
        }
    } else {
        # 1. Check direct absolute or expanded path
        let direct = ($target_str | path expand)
        if ($direct | path exists) and not ($direct | path type | str contains "dir") {
            $resolved_path = $direct
        } else if ($root | is-not-empty) {
            # 2. Check if target matches a category case-insensitively (e.g. `wallpaper space` -> random from space)
            let cat_match = ($files | where { |f|
                let rel = ($f | str replace $"($root)/" "")
                let parts = ($rel | split row "/")
                ($parts | length) > 1 and (($parts | first | str lowercase) == $target_lower)
            })

            if ($cat_match | is-not-empty) {
                $resolved_path = ($cat_match | shuffle | first)
            } else {
                # 3. Check relative path or filename case-insensitively
                let file_match = ($files | where { |f|
                    let rel = ($f | str replace $"($root)/" "")
                    let rel_lower = ($rel | str lowercase)
                    let base_lower = ($f | path basename | str lowercase)
                    $rel_lower == $target_lower or $base_lower == $target_lower or ($rel_lower | str ends-with $target_lower)
                })

                if ($file_match | is-not-empty) {
                    $resolved_path = ($file_match | first)
                }
            }
        }
    }

    if ($resolved_path | is-empty) or not ($resolved_path | path exists) {
        print -e $"Error: Could not find wallpaper matching '($target_str)'."
        return
    }

    # 1. Update cache symlink
    mkdir $"($env.HOME)/.cache"
    ln -sf $resolved_path $"($env.HOME)/.cache/current_wallpaper"

    # 2. Update wallpaper with smooth transition (supports plasma, awww, or swww)
    if (which plasma-apply-wallpaperimage | is-empty) == false {
        plasma-apply-wallpaperimage $resolved_path
    } else if (which awww | is-empty) == false {
        if (pgrep -x awww-daemon | is-empty) {
            job spawn { awww-daemon }
            sleep 200ms
        }
        awww img $resolved_path --transition-type random --transition-fps 144 --transition-duration 1.5
    } else if (which swww | is-empty) == false {
        if (pgrep -x swww-daemon | is-empty) {
            job spawn { swww-daemon }
            sleep 200ms
        }
        swww img $resolved_path --transition-type random --transition-fps 144 --transition-duration 1.5
    }

    # 3. Extract Material 3 colors with Matugen
    if (which matugen | is-empty) == false {
        matugen -t $stype image $resolved_path
        print $"✓ Dynamic ($stype) theme generated and applied from ($resolved_path | path basename)"
        if (which notify-send | is-empty) == false {
            notify-send -u low "Wallpaper & Theme" $"Applied ($stype) from ($resolved_path | path basename)" -i $resolved_path
        }
    }
}

# Switch theme style, profile, or accent on the current wallpaper
export def theme [
    style?: string@"nu-complete theme styles" # e.g. expressive, fruit-salad, vibrant, fidelity, tonal-spot, monochrome, dark, light, or #hex
] {
    let current_wall = (if ("~/.cache/current_wallpaper" | path exists) {
        "~/.cache/current_wallpaper" | path expand
    } else {
        ""
    })

    if ($current_wall | is-empty) {
        print -e "Error: No current wallpaper found in ~/.cache/current_wallpaper"
        return
    }

    if ($style | is-empty) {
        print $"Current wallpaper: ($current_wall | path basename)"
        print $"Theme profiles: expressive, fruit-salad, vibrant, rainbow, fidelity, content, tonal-spot, monochrome"
        print $"Modes: dark, light"
        print "Source accent colors:"
        try {
            ^matugen image --show-source-colors $current_wall
        } catch { }
        return
    }

    let input_style = ($style | str lowercase)

    # 1. Dark / Light mode toggle
    if $input_style == "dark" or $input_style == "light" {
        ^matugen -m $input_style image $current_wall
        print $"✓ Switched to ($input_style) mode"
        return
    }

    # 2. Custom Hex color accent override
    if ($style | str starts-with "#") {
        ^matugen color hex ($style | str replace "#" "")
        print $"✓ Applied accent color ($style)"
        return
    }

    # 3. Scheme type profile
    let stype = if ($input_style | str starts-with "scheme-") {
        $input_style
    } else {
        $"scheme-($input_style)"
    }

    ^matugen -t $stype image $current_wall
    print $"✓ Applied theme profile ($stype)"
}
