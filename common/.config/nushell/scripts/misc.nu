# Prints a standardized error message to stderr.
# Default (interactive): Prints a clean single-line error message without double-logging or terminating the shell session.
# Script/Automation (--code or --fatal): Raises a Nushell error exception with a specific error/status code for CI/scripts.
export def nu-fail [
    msg: string,
    --code (-c): string = "", # Optional custom error code (e.g., "1", "127", or "ERR_GIT_DIRTY")
    --fatal (-f)              # Shortcut to throw a fatal exception (equivalent to --code "1")
] {
    let err_code = if ($code | is-not-empty) { $code } else if $fatal { "1" } else { "" }

    if ($err_code | is-empty) {
        print -e $"(ansi red_bold)Error:(ansi reset) (ansi red)($msg)(ansi reset)"
    } else {
        error make { msg: $msg, code: $err_code }
    }
}

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
        nu-fail $"File not found: ($path)" -c "ENOENT"
        return
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
export def update-aerion [
    --pre-release (-p) # Pass this flag to include pre-releases/testing builds
] {
    let repo = "hkdb/aerion"
    let temp_dir = (mktemp -d -t "aerion-upgrade.XXXXXX")
    let archive_path = ($temp_dir | path join "aerion.tar.gz")

    let download_url = if $pre_release {
        print $"(ansi yellow)Fetching latest pre-release metadata from GitHub...(ansi reset)"
        # Fetch releases list from GitHub API (sorted descending by creation date)
        let releases = (http get $"https://api.github.com/repos/($repo)/releases")
        if ($releases | is-empty) {
            rm -rf $temp_dir
            error make { msg: "No releases found on GitHub." }
        }

        # The first release in the array is the most recent (stable or pre-release)
        let latest_release = ($releases | first)
        let asset = ($latest_release.assets | where name == "aerion-linux-amd64.tar.gz" | first)

        if ($asset | is-empty) {
            rm -rf $temp_dir
            error make { msg: $"Could not find aerion-linux-amd64.tar.gz in ($latest_release.tag_name)" }
        }

        print $"(ansi cyan)Found build: ($latest_release.tag_name) \(Pre-release: ($latest_release.prerelease)\)(ansi reset)"
        $asset.browser_download_url
    } else {
        $"https://github.com/($repo)/releases/latest/download/aerion-linux-amd64.tar.gz"
    }

    print $"(ansi green)Downloading Aerion archive...(ansi reset)"
    try {
        http get $download_url | save -f $archive_path
    } catch {
        rm -rf $temp_dir
        error make { msg: "Failed to download Aerion archive. Verify your internet connection." }
    }

    print $"(ansi green)Extracting archive...(ansi reset)"
    tar -xzf $archive_path -C $temp_dir

    let installer_paths = (glob $"($temp_dir)/**/install.sh")
    if ($installer_paths | is-empty) {
        rm -rf $temp_dir
        error make { msg: "install.sh not found in the extracted archive." }
    }
    let installer = ($installer_paths | first)
    let install_dir = ($installer | path dirname)

    print $"(ansi green)Running installer script...(ansi reset)"
    let old_pwd = $env.PWD
    cd $install_dir

    bash ./install.sh

    cd $old_pwd

    print $"(ansi green)Cleaning up temporary files...(ansi reset)"
    rm -rf $temp_dir

    print $"(ansi green)🎉 Aerion update workflow completed!(ansi reset)"
}

# Helper to determine fallback TERM when running in Ghostty to avoid remote/container terminfo missing issues
export def get-term [] {
    if "TERM" in $env and $env.TERM == "xterm-ghostty" {
        "xterm-256color"
    } else {
        $env.TERM? | default "xterm-256color"
    }
}

# Search files using ripgrep and output matches in a structured table.
export def rgt [
    pattern: string,       # The pattern to search for
    ...args: string        # Additional arguments to pass to ripgrep (e.g. file paths or globs)
] {
    let config_args = (if ($env.RIPGREP_CONFIG_PATH? | is-not-empty) { [] } else { ["--hidden"] })
    let run = (rg --json ...$config_args $pattern ...$args | complete)

    if $run.exit_code == 1 and $run.stdout == "" {
        return []
    }

    if $run.exit_code != 0 {
        let err_msg = ($run.stderr | str trim)
        let display_err = if ($err_msg | is-empty) { "ripgrep search failed" } else { $err_msg }
        nu-fail $display_err -c "RG_EXEC_ERROR"
        return []
    }

    $run.stdout
    | from json -o
    | where type == "match"
    | each { |row|
        mut line = ($row.data.lines.text | str replace --regex '\r?\n$' '')
        let submatches = ($row.data.submatches | reverse)
        for sub in $submatches {
            let start = $sub.start
            let end = $sub.end
            let prefix = ($line | str substring 0..<$start)
            let matched = ($line | str substring $start..<$end)
            let suffix = ($line | str substring $end..)
            $line = $"($prefix)(ansi { fg: '#cba6f7', attr: 'b' })($matched)(ansi reset)($suffix)"
        }
        {
            file: $row.data.path.text,
            line: $row.data.line_number,
            content: $line
        }
    }
}
