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

# Set desktop wallpaper and generate matching dynamic theme
export def wallpaper [
    target?: string@"nu-complete wallpaper targets"         # Image path, category name, relative name, "random", or "list"
    category?: string@"nu-complete wallpaper categories"   # Category for random pick (case-insensitive, e.g. wallpaper random space)
    --type (-t): string@"nu-complete theme types" = "scheme-expressive" # Scheme profile
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

    # Handle "list" or empty argument
    if ($target | default "" | str lowercase) == "list" or ($target | is-empty) {
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

    let target_str = ($target | default "")
    let target_lower = ($target_str | str lowercase)

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
        awww img $resolved_path --transition-type wave --transition-fps 144 --transition-duration 1.5
    } else if (which swww | is-empty) == false {
        if (pgrep -x swww-daemon | is-empty) {
            job spawn { swww-daemon }
            sleep 200ms
        }
        swww img $resolved_path --transition-type wave --transition-fps 144 --transition-duration 1.5
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
        print ""
        print "Available Scheme Profiles:"
        print "  theme expressive    - Android Material You default"
        print "  theme fruit-salad   - Playful & high contrast"
        print "  theme vibrant       - Max saturation & vividness"
        print "  theme rainbow       - Full spectrum"
        print "  theme fidelity      - Strict image fidelity"
        print "  theme tonal-spot    - Classic Material"
        print "  theme monochrome    - Minimal grayscale"
        print ""
        print "Mode Controls:"
        print "  theme dark          - Dark mode"
        print "  theme light         - Light mode"
        print "  theme <#hex>        - Custom accent color"
        print ""
        print "Extracted Wallpaper Source Accents:"
        let raw_colors = (try { ^matugen image --show-source-colors $current_wall | lines | str trim | where ($it | str starts-with "#") } catch { [] })
        $raw_colors | enumerate | each { |r|
            let idx = $r.index + 1
            print $"  theme ($r.item)   - Source Accent ($idx)"
        }
        return
    }

    let style_str = ($style | default "")
    let style_lower = ($style_str | str lowercase)

    if ($style_str | str starts-with "#") {
        matugen color hex $style_str
        print $"✓ Applied accent color: ($style_str)"
    } else if $style_lower == "dark" {
        matugen -m dark -t scheme-expressive image $current_wall
        print "✓ Switched to Dark Mode (Expressive)"
    } else if $style_lower == "light" {
        matugen -m light -t scheme-expressive image $current_wall
        print "✓ Switched to Light Mode (Expressive)"
    } else {
        let stype = if ($style_lower | str starts-with "scheme-") {
            $style_lower
        } else {
            $"scheme-($style_lower)"
        }
        matugen -t $stype image $current_wall
        print $"✓ Applied theme profile: ($stype)"
    }
}
