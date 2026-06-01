export def "git histogram" [
    --limit: int = -1 # Number of recent commits to analyze
] {
    let delimiter = "»¦«"
    let format = (
        [ "%h" "%aN" "%s" "%aD" ] | str join $delimiter
    )

    ^git log --max-count=($limit) --pretty=($format)
    | lines
    | split column $delimiter sha1 committer desc merged_at
    | histogram committer merger
}

export def parse-scraper [path: path] {
    if not ($path | path exists) {
        error make {msg: $"File not found: ($path)"}
    }

    # Using the 'slurp' Perl method to handle the multi-line merging
    # Then applying the optional regex for the dealer ID
    awk '/^[0-9]{4}-[0-9]{2}-[0-9]{2}/ { if (line) print line; line = $0; next } { line = line " " $0 } END { print line }' $path
    | lines
    | parse --regex '(?<date>\d{4}-\d{2}-\d{2}) (?<time>\d{2}:\d{2}:\d{2}) \[(?<context>[\w-]+)(?:: (?<dealer>\d+))?\] (?<level>\w+): (?<message>.*)'
    | upsert dealer { |row| if ($row.dealer | is-empty) { null } else { $row.dealer | into int } }
    | collect
}

export def fix-anims [] {
    # Force KWin to unhook the crashed instance
    dbus-send --session --dest=org.kde.KWin --type=method_call /Effects org.kde.kwin.Effects.unloadEffect string:"kwin6_effect_aura_glow" | ignore

    # Give KWin time to garbage collect
    sleep 200ms

    # Reinitialize the effect
    dbus-send --session --dest=org.kde.KWin --type=method_call /Effects org.kde.kwin.Effects.loadEffect string:"kwin6_effect_aura_glow" | ignore

    print "Aura Glow state reset."
}

# Download, extract, and execute the installation script for Aerion Email Client automatically
export def update-aerion [] {
    let url = "https://github.com/hkdb/aerion/releases/latest/download/aerion-linux-amd64.tar.gz"
    let temp_dir = (mktemp -d -t "aerion-upgrade.XXXXXX")
    let archive_path = ($temp_dir | path join "aerion.tar.gz")
    
    print $"(ansi green)Downloading latest Aerion release from GitHub...(ansi reset)"
    try {
        http get $url | save -f $archive_path
    } catch {
        rm -rf $temp_dir
        error make {msg: "Failed to download Aerion archive. Verify your internet connection."}
    }

    print $"(ansi green)Extracting archive...(ansi reset)"
    tar -xzf $archive_path -C $temp_dir

    # Find the install.sh script anywhere inside the extracted files
    let installer_paths = (glob $"($temp_dir)/**/install.sh")
    if ($installer_paths | is-empty) {
        rm -rf $temp_dir
        error make {msg: "install.sh not found in the extracted archive."}
    }
    let installer = ($installer_paths | first)
    let install_dir = ($installer | path dirname)

    print $"(ansi green)Running installer script (requires sudo)...(ansi reset)"
    # Change context and execute the installer
    with-env { PWD: $install_dir } {
        sudo bash ./install.sh
    }

    print $"(ansi green)Cleaning up temporary files...(ansi reset)"
    rm -rf $temp_dir
    
    print $"(ansi green)🎉 Aerion has been upgraded successfully!(ansi reset)"
}

