# Desktop wallpaper and dynamic theming helper

# Set desktop wallpaper and generate matching dynamic theme
export def wallpaper [
    img_path: path
    --type (-t): string = "scheme-expressive" # Scheme type (scheme-expressive, scheme-fruit-salad, scheme-vibrant, scheme-rainbow, scheme-fidelity, scheme-tonal-spot, scheme-monochrome)
] {
    let full_path = ($img_path | path expand)
    if not ($full_path | path exists) {
        print -e $"Error: Image '($full_path)' does not exist."
        return
    }

    # Normalize scheme type if short name was given
    let stype = if ($type | str starts-with "scheme-") {
        $type
    } else {
        $"scheme-($type)"
    }

    # 1. Update cache symlink
    mkdir $"($env.HOME)/.cache"
    ln -sf $full_path $"($env.HOME)/.cache/current_wallpaper"

    # 2. Update wallpaper with smooth transition (supports plasma, awww, or swww)
    if (which plasma-apply-wallpaperimage | is-empty) == false {
        plasma-apply-wallpaperimage $full_path
    } else if (which awww | is-empty) == false {
        if (pgrep -x awww-daemon | is-empty) {
            job spawn { awww-daemon }
            sleep 200ms
        }
        awww img $full_path --transition-type wave --transition-fps 144 --transition-duration 1.5
    } else if (which swww | is-empty) == false {
        if (pgrep -x swww-daemon | is-empty) {
            job spawn { swww-daemon }
            sleep 200ms
        }
        swww img $full_path --transition-type wave --transition-fps 144 --transition-duration 1.5
    }

    # 3. Extract Material 3 colors with Matugen
    if (which matugen | is-empty) == false {
        matugen -t $stype image $full_path
        print $"✓ Dynamic ($stype) theme generated and applied from ($full_path | path basename)"
        if (which notify-send | is-empty) == false {
            notify-send -u low "Wallpaper & Theme" $"Applied ($stype) from ($full_path | path basename)" -i $full_path
        }
    }
}

# Switch theme style, profile, or accent on the current wallpaper
export def theme [
    style?: string # e.g. expressive, fruit-salad, vibrant, fidelity, tonal-spot, monochrome, dark, light, or #hex
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

    if ($style | str starts-with "#") {
        matugen color hex $style
        print $"✓ Applied accent color: ($style)"
    } else if $style == "dark" {
        matugen -m dark -t scheme-expressive image $current_wall
        print "✓ Switched to Dark Mode (Expressive)"
    } else if $style == "light" {
        matugen -m light -t scheme-expressive image $current_wall
        print "✓ Switched to Light Mode (Expressive)"
    } else {
        let stype = if ($style | str starts-with "scheme-") {
            $style
        } else {
            $"scheme-($style)"
        }
        matugen -t $stype image $current_wall
        print $"✓ Applied theme profile: ($stype)"
    }
}
