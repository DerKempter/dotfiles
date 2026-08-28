# Desktop wallpaper and dynamic theming helper
export def wallpaper [img_path: path] {
    let full_path = ($img_path | path expand)
    if not ($full_path | path exists) {
        print -e $"Error: Image '($full_path)' does not exist."
        return
    }

    # 1. Update hyprlock fast cache symlink
    mkdir $"($env.HOME)/.cache"
    ln -sf $full_path $"($env.HOME)/.cache/current_wallpaper"

    # 2. Update wallpaper with smooth transition
    if (which swww | is-empty) == false {
        swww img $full_path --transition-type wave --transition-fps 144 --transition-duration 1.5
    }

    # 3. Extract Material 3 colors with Matugen (triggers post_process hooks for Waybar, SwayNC, Hyprland, Ghostty)
    if (which matugen | is-empty) == false {
        matugen image $full_path
        print $"✓ Dynamic theme generated and applied from ($full_path | path basename)"
    }
}
