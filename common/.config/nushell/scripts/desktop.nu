# Desktop wallpaper and dynamic theming helper
export def wallpaper [img_path: path] {
    let full_path = ($img_path | path expand)
    if not ($full_path | path exists) {
        print -e $"Error: Image '($full_path)' does not exist."
        return
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
        matugen image $full_path
        print $"✓ Dynamic theme generated and applied from ($full_path | path basename)"
        if (which notify-send | is-empty) == false {
            notify-send -u low "Wallpaper & Theme" $"Applied ($full_path | path basename)" -i $full_path
        }
    }
}
