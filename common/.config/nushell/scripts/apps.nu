# apps.nu
# Automated application release installer and updater for GitHub releases.
# Supports shared catalog recipes and device-specific activation configs.

use misc.nu nu-fail

# -----------------------------------------------------------------------------
# Global Application Recipe Catalog
# -----------------------------------------------------------------------------

export const APP_CATALOG = {
    spotifast: {
        repo: "crmne/spotifast"
        asset: '^spotifast-.*-x86_64-unknown-linux-gnu\.tar\.gz$'
        strategy: "cargo_desktop"
        binary: "spotifast"
        description: "Native Spotify desktop client (GTK/Rust)"
    }
    zapfast: {
        repo: "crmne/zapfast"
        asset: '^zapfast-.*-x86_64-unknown-linux-gnu\.tar\.gz$'
        strategy: "cargo_desktop"
        binary: "zapfast"
        description: "Native WhatsApp desktop client (GTK/Rust)"
    }
    aerion: {
        repo: "hkdb/aerion"
        asset: '^aerion-linux-amd64\.tar\.gz$'
        strategy: "installer_script"
        script: "install.sh"
        description: "Aerion Email Client"
    }
}

# -----------------------------------------------------------------------------
# Device Configuration Loader
# -----------------------------------------------------------------------------

# Returns the standard path for device-specific apps.toml
def get-config-path [] {
    let base = if ($env.XDG_CONFIG_HOME? | is-not-empty) {
        $env.XDG_CONFIG_HOME
    } else {
        $nu.home-dir | path join ".config"
    }
    $base | path join "nushell" "apps.toml"
}

# Loads device configuration from apps.toml (if present)
def load-device-config [] {
    let cfg_path = (get-config-path)
    if not ($cfg_path | path exists) {
        return { enabled: null, custom: {} }
    }

    try {
        let content = (open $cfg_path)
        {
            enabled: ($content.enabled? | default null),
            custom: ($content.custom? | default {})
        }
    } catch {
        print -e $"(ansi yellow)Warning: Could not parse ($cfg_path). Falling back to global catalog.(ansi reset)"
        { enabled: null, custom: {} }
    }
}

# Merges catalog recipes with device-specific custom recipes
def resolve-registry [] {
    let cfg = (load-device-config)
    $APP_CATALOG | merge ($cfg.custom? | default {})
}

# Returns list of application keys active on this specific machine
def get-active-apps [] {
    let cfg = (load-device-config)
    let registry = (resolve-registry)
    if ($cfg.enabled | is-not-empty) {
        let custom_keys = ($cfg.custom | columns)
        ($cfg.enabled | append $custom_keys | uniq | where { |a| $a in $registry })
    } else {
        $registry | columns
    }
}

# Autocompletion provider covering all resolved apps
def "nu-complete apps" [] {
    resolve-registry | columns
}

# Scaffolds a local apps.toml template if not already present, or resets it when force is true
def init-device-config [force: bool = false] {
    let cfg_path = (get-config-path)
    if ($cfg_path | path exists) and not $force {
        print $"(ansi yellow)Configuration already exists at: ($cfg_path)(ansi reset)"
        print $"(ansi dark_gray)Tip: Run 'update-app --init --force' to overwrite with the default template.(ansi reset)"
        return
    }

    mkdir ($cfg_path | path dirname)

    let template = '# =============================================================================
# Device-Specific Application Configuration
# =============================================================================
# Applications from the shared catalog to keep updated on this machine.
# Run `update-app --list` to view all available catalog recipes.

enabled = [
    "spotifast",
    "zapfast",
    "aerion",
]

# (Optional) Custom machine-specific applications not in the shared catalog.
# Example:
# [custom.my-tool]
# repo = "owner/repo"
# asset = ''^my-tool-.*-linux-x86_64\.tar\.gz$''
# strategy = "binary"           # "cargo_desktop" | "installer_script" | "binary"
# binary = "my-tool"            # optional, defaults to app key
# description = "Internal CLI tool"
'

    $template | save -f $cfg_path
    if $force {
        print $"(ansi green)✓ Overwrote device application config at ($cfg_path)(ansi reset)"
    } else {
        print $"(ansi green)✓ Created device application config at ($cfg_path)(ansi reset)"
    }
}

# -----------------------------------------------------------------------------
# GitHub Release & Archive Helpers
# -----------------------------------------------------------------------------

# Fetch latest or pre-release release metadata from GitHub API
def fetch-release [repo: string, pre_release: bool] {
    let headers = if ($env.GITHUB_TOKEN? | is-not-empty) {
        { Authorization: $"Bearer ($env.GITHUB_TOKEN)" }
    } else {
        {}
    }

    let url = $"https://api.github.com/repos/($repo)/releases"
    let releases = try {
        http get --headers $headers $url
    } catch {
        nu-fail $"Failed to connect to GitHub API for '($repo)'. Check network or API rate limits." -c "GITHUB_API_ERROR"
        return null
    }

    if ($releases | is-empty) {
        nu-fail $"No releases found on GitHub for '($repo)'." -c "NO_RELEASES"
        return null
    }

    if $pre_release {
        $releases | first
    } else {
        let stable = ($releases | where prerelease == false)
        if ($stable | is-empty) { $releases | first } else { $stable | first }
    }
}

# Resolve target release asset using exact name or regex pattern
def find-asset [release: record, asset_pattern: string] {
    let assets = $release.assets
    if ($assets | is-empty) {
        return null
    }

    let exact = ($assets | where name == $asset_pattern | get -o 0)
    if ($exact | is-not-empty) {
        return $exact
    }

    $assets | where name =~ $asset_pattern | get -o 0
}

# Extract archive based on file extension
def unpack-archive [archive_path: path, dest_dir: path] {
    if ($archive_path | str ends-with ".tar.gz") or ($archive_path | str ends-with ".tgz") {
        tar -xzf $archive_path -C $dest_dir
    } else if ($archive_path | str ends-with ".tar.xz") {
        tar -xJf $archive_path -C $dest_dir
    } else if ($archive_path | str ends-with ".zip") {
        unzip -q $archive_path -d $dest_dir
    } else {
        tar -xf $archive_path -C $dest_dir
    }
}

# -----------------------------------------------------------------------------
# Installation Strategies
# -----------------------------------------------------------------------------

# Strategy: Cargo/Rust desktop application bundle
def install-cargo-desktop [app_name: string, config: record, temp_dir: path] {
    let binary = ($config.binary? | default $app_name)

    let subdirs = (ls $temp_dir | where type == "dir" | get name)
    let base_dir = if ($subdirs | length) == 1 {
        $subdirs | first
    } else {
        let matched = ($subdirs | where ($it | path basename) =~ $'^(?:($app_name)|($binary))' | get -o 0)
        if ($matched | is-not-empty) { $matched } else { $temp_dir }
    }

    let bin_dir = ("~/.local/bin" | path expand)
    let app_dir = ("~/.local/share/applications" | path expand)
    let icon_dir = ("~/.local/share/icons/hicolor/scalable/apps" | path expand)

    mkdir $bin_dir $app_dir $icon_dir

    let binary_src = if (($base_dir | path join $binary) | path exists) {
        $base_dir | path join $binary
    } else {
        let candidates = (glob $"($temp_dir)/**/($binary)")
        if ($candidates | is-not-empty) {
            $candidates | first
        } else {
            nu-fail $"Binary '($binary)' not found in extracted archive." -c "BINARY_NOT_FOUND"
            return false
        }
    }

    print $"(ansi green)Installing binary to ($bin_dir)/($binary)...(ansi reset)"
    install -m 755 $binary_src ($bin_dir | path join $binary)

    # Clean up stale cargo binary if present to avoid PATH shadowing/drift
    let cargo_bin = ($"~/.cargo/bin/($binary)" | path expand)
    if ($cargo_bin | path exists) {
        rm -f $cargo_bin
    }

    # Install desktop shortcut if present
    let desktop_file = if (($base_dir | path join $"packaging/applications/($binary).desktop") | path exists) {
        $base_dir | path join $"packaging/applications/($binary).desktop"
    } else {
        let candidates = (glob $"($temp_dir)/**/*.desktop")
        if ($candidates | is-not-empty) { $candidates | first } else { "" }
    }

    if ($desktop_file | is-not-empty) and ($desktop_file | path exists) {
        print $"(ansi green)Installing desktop shortcut...(ansi reset)"
        cp -f $desktop_file ($app_dir | path join $"($binary).desktop")
    }

    # Install icon if present
    let icon_file = if (($base_dir | path join $"packaging/icons/($binary).svg") | path exists) {
        $base_dir | path join $"packaging/icons/($binary).svg"
    } else {
        let candidates = (glob $"($temp_dir)/**/($binary).svg")
        if ($candidates | is-not-empty) { $candidates | first } else { "" }
    }

    if ($icon_file | is-not-empty) and ($icon_file | path exists) {
        print $"(ansi green)Installing icon...(ansi reset)"
        cp -f $icon_file ($icon_dir | path join $"($binary).svg")
    }

    if (which update-desktop-database | is-not-empty) {
        update-desktop-database $app_dir
    }

    true
}

# Strategy: Run internal installer script
def install-installer-script [app_name: string, config: record, temp_dir: path] {
    let script_name = ($config.script? | default "install.sh")
    let script_candidates = (glob $"($temp_dir)/**/($script_name)")

    if ($script_candidates | is-empty) {
        nu-fail $"Installer script '($script_name)' not found in extracted archive." -c "SCRIPT_NOT_FOUND"
        return false
    }

    let script_path = ($script_candidates | first)
    let install_dir = ($script_path | path dirname)

    print $"(ansi green)Running installer script \(($script_name)\)...(ansi reset)"
    let old_pwd = $env.PWD
    cd $install_dir

    bash $"./($script_name)"

    cd $old_pwd
    true
}

# Strategy: Direct binary installation
def install-binary [app_name: string, config: record, temp_dir: path] {
    let binary = ($config.binary? | default $app_name)
    let bin_dir = ("~/.local/bin" | path expand)
    mkdir $bin_dir

    let binary_src = if (($temp_dir | path join $binary) | path exists) {
        $temp_dir | path join $binary
    } else {
        let candidates = (glob $"($temp_dir)/**/($binary)")
        if ($candidates | is-not-empty) { $candidates | first } else { "" }
    }

    if ($binary_src | is-empty) or not ($binary_src | path exists) {
        nu-fail $"Binary '($binary)' not found." -c "BINARY_NOT_FOUND"
        return false
    }

    print $"(ansi green)Installing binary to ($bin_dir)/($binary)...(ansi reset)"
    install -m 755 $binary_src ($bin_dir | path join $binary)
    true
}

# -----------------------------------------------------------------------------
# Updater Pipeline
# -----------------------------------------------------------------------------

# Internal updater routine for a single application
def update-single-app [
    app_name: string,
    pre_release: bool = false,
    dry_run: bool = false
] {
    let registry = (resolve-registry)
    if not ($app_name in $registry) {
        nu-fail $"Unknown application: '($app_name)'. Use 'update-app --list' to view supported applications." -c "APP_NOT_FOUND"
        return false
    }

    let config = ($registry | get $app_name)
    let repo = $config.repo
    let asset_pattern = $config.asset

    print $"(ansi yellow)Fetching ($app_name) release metadata from GitHub \(($repo)\)...(ansi reset)"
    let release = (fetch-release $repo $pre_release)
    if ($release | is-empty) {
        return false
    }

    let asset = (find-asset $release $asset_pattern)
    if ($asset | is-empty) {
        nu-fail $"No matching asset found in ($release.tag_name) matching '($asset_pattern)'." -c "ASSET_NOT_FOUND"
        return false
    }

    print $"(ansi cyan)Found build: ($release.tag_name) \(Pre-release: ($release.prerelease)\)(ansi reset)"

    if $dry_run {
        print $"(ansi yellow)[dry-run] Would download: ($asset.browser_download_url)(ansi reset)"
        print $"(ansi yellow)[dry-run] Strategy: ($config.strategy)(ansi reset)"
        return true
    }

    let temp_dir = (mktemp -d -t $"($app_name)-upgrade.XXXXXX")
    let archive_path = ($temp_dir | path join $asset.name)

    print $"(ansi green)Downloading archive: ($asset.name)...(ansi reset)"
    let download_success = try {
        http get $asset.browser_download_url | save -f $archive_path
        true
    } catch {
        rm -rf $temp_dir
        nu-fail $"Failed to download archive from ($asset.browser_download_url)." -c "DOWNLOAD_FAILED"
        false
    }

    if not $download_success {
        return false
    }

    print $"(ansi green)Extracting archive...(ansi reset)"
    let extract_success = try {
        unpack-archive $archive_path $temp_dir
        true
    } catch {
        rm -rf $temp_dir
        nu-fail $"Failed to extract archive '($archive_path)'." -c "EXTRACT_FAILED"
        false
    }

    if not $extract_success {
        return false
    }

    let install_ok = match $config.strategy {
        "cargo_desktop" => { install-cargo-desktop $app_name $config $temp_dir },
        "installer_script" => { install-installer-script $app_name $config $temp_dir },
        "binary" => { install-binary $app_name $config $temp_dir },
        _ => {
            nu-fail $"Unknown installation strategy: '($config.strategy)'." -c "UNKNOWN_STRATEGY"
            false
        }
    }

    print $"(ansi green)Cleaning up temporary files...(ansi reset)"
    rm -rf $temp_dir

    if $install_ok {
        print $"(ansi green)🎉 ($app_name) \(($release.tag_name)\) update completed successfully!(ansi reset)"
        true
    } else {
        false
    }
}

# -----------------------------------------------------------------------------
# User Commands & Aliases
# -----------------------------------------------------------------------------

# Update an installed application or all configured applications from GitHub releases
export def update-app [
    app?: string@"nu-complete apps" # Specific app to update (tab-completes from registry)
    --all (-a)                      # Update all applications enabled for this machine
    --pre-release (-p)              # Include pre-releases/testing builds
    --dry-run (-d)                  # Check release and download URL without installing
    --list (-l)                     # List all configured applications and device status
    --init                          # Initialize a local apps.toml template for this device
    --force (-f)                    # Overwrite existing apps.toml when initializing
] {
    if $init {
        init-device-config $force
        return
    }

    if $list or (($app | is-empty) and not $all) {
        let registry = (resolve-registry)
        let active = (get-active-apps)
        return (
            $registry
            | transpose app cfg
            | insert status { |row| if $row.app in $active { "enabled" } else { "available" } }
            | select app status cfg.repo cfg.strategy cfg.description?
            | rename app status repo strategy description
        )
    }

    if $all {
        let apps = (get-active-apps)
        if ($apps | is-empty) {
            nu-fail "No applications are currently enabled on this device. Run 'update-app --init' or edit ~/.config/nushell/apps.toml."
            return
        }

        mut results = []
        for a in $apps {
            print $"\n(ansi white_bold)========================================(ansi reset)"
            print $"(ansi white_bold)Updating ($a)...(ansi reset)"
            print $"(ansi white_bold)========================================(ansi reset)"
            let ok = try {
                update-single-app $a $pre_release $dry_run
            } catch { |err|
                print -e $"(ansi red)Error updating ($a): ($err.msg)(ansi reset)"
                false
            }
            $results = ($results | append {
                app: $a,
                status: (if $ok { "Success" } else { "Failed" })
            })
        }
        print $"\n(ansi white_bold)Update Summary:(ansi reset)"
        return $results
    }

    update-single-app $app $pre_release $dry_run
}

# Backward-compatibility alias wrappers
export def update-spotifast [
    --pre-release (-p)
    --dry-run (-d)
] {
    update-app spotifast --pre-release=$pre_release --dry-run=$dry_run
}

export def update-zapfast [
    --pre-release (-p)
    --dry-run (-d)
] {
    update-app zapfast --pre-release=$pre_release --dry-run=$dry_run
}

export def update-aerion [
    --pre-release (-p)
    --dry-run (-d)
] {
    update-app aerion --pre-release=$pre_release --dry-run=$dry_run
}
