#!/usr/bin/env nu
# =============================================================================
# Dotfiles Essentials Installer & Audit Tool for Nushell
# Audits, installs dependencies, and links dotfiles across supported distributions
# =============================================================================

# Helper: Fail with formatted error message
def nu-fail [msg: string] {
    error make { msg: $msg }
}

# Helper to check if a real external binary exists on the system (ignoring completions/.nu files)
def has-binary [cmd: string] {
    let results = (which -a $cmd | where type == "external" and not ($it.path | str ends-with ".nu") and ($it.path | path exists))
    ($results | is-not-empty)
}

# Run the dotfiles installer and dependency audit
def main [] {
    print $"(ansi cyan_bold)          Dotfiles Essentials Installer & Audit - Nushell             (ansi reset)"
    print $"(ansi cyan)=========================================================================(ansi reset)\n"

    # Identify current OS
    let os_id = (get-os-id)
    print $"(ansi cyan_bold)==>(ansi reset) Detected operating system: (ansi default_bold)($os_id)(ansi reset)"

    # Audit essential tools
    let audit_results = (audit-tools $os_id)

    let missing_system_pkgs = ($audit_results | where missing and ($it.install_type == "system") | get pkg)
    let missing_special_pkgs = ($audit_results | where missing and ($it.install_type == "special") | get tool)

    # Install missing packages if any
    if ($missing_system_pkgs | is-not-empty) {
        print $"\n(ansi cyan_bold)==>(ansi reset) Installing missing system packages: ($missing_system_pkgs | str join ' ')..."
        install-system-packages $os_id $missing_system_pkgs
    }

    if ($missing_special_pkgs | is-not-empty) {
        print $"\n(ansi cyan_bold)==>(ansi reset) Installing standalone tools..."
        for tool in $missing_special_pkgs {
            install-special-tool $tool $os_id
        }
    }

    # Ensure ~/.local/bin is in PATH for current script execution
    let local_bin = ($env.HOME | path join ".local" "bin")
    if not ($env.PATH | any { |it| $it == $local_bin }) {
        $env.PATH = ($env.PATH | prepend $local_bin)
    }

    # Final verification
    let re_audit = (audit-tools $os_id)
    let still_missing = ($re_audit | where missing)

    if ($still_missing | is-empty) {
        print $"\n(ansi green_bold)✓ All essential CLI tools and dependencies are installed.(ansi reset)"
    } else {
        print $"\n(ansi yellow_bold)⚠ Some tools could not be automatically installed:(ansi reset)"
        $still_missing | select tool pkg | print
    }

    # Ensure dotfiles symlinks and fallback themes are active
    sync-stow-links
}

# Determines the OS distribution ID
def get-os-id [] {
    if $nu.os-info.name == "macos" {
        "darwin"
    } else if ("/etc/os-release" | path exists) {
        let os_data = (open /etc/os-release --raw
            | lines
            | where { |l| $l =~ "^[A-Z_]+=" }
            | parse "{key}={value}"
            | upsert value { |r| $r.value | str trim -c '"' }
        )
        let os_id = ($os_data | where key == "ID" | get 0.value? | default "unknown")
        let id_like = ($os_data | where key == "ID_LIKE" | get 0.value? | default "")

        if $os_id in ["ubuntu", "debian", "pop", "linuxmint", "tuxedo", "elementary", "neon", "zorin"] {
            $os_id
        } else if ($id_like =~ "ubuntu|debian") {
            "debian"
        } else if ($id_like =~ "arch") {
            "arch"
        } else if ($id_like =~ "fedora|rhel") {
            "fedora"
        } else if ($id_like =~ "suse") {
            "suse"
        } else {
            $os_id
        }
    } else {
        "unknown"
    }
}

# Core package definitions across distributions
def tool-definitions [] {
    [
        { tool: "git",      arch: "git",       debian: "git",       fedora: "git",       suse: "git",       alpine: "git",       brew: "git" }
        { tool: "curl",     arch: "curl",      debian: "curl",      fedora: "curl",      suse: "curl",      alpine: "curl",      brew: "curl" }
        { tool: "stow",     arch: "stow",      debian: "stow",      fedora: "stow",      suse: "stow",      alpine: "stow",      brew: "stow" }
        { tool: "just",     arch: "just",      debian: "just",      fedora: "just",      suse: "just",      alpine: "just",      brew: "just" }
        { tool: "nu",       arch: "nushell",   debian: "nushell",   fedora: "nushell",   suse: "nushell",   alpine: "nushell",   brew: "nushell" }
        { tool: "starship", arch: "starship",  debian: "starship",  fedora: "starship",  suse: "starship",  alpine: "starship",  brew: "starship" }
        { tool: "zoxide",   arch: "zoxide",    debian: "zoxide",    fedora: "zoxide",    suse: "zoxide",    alpine: "zoxide",    brew: "zoxide" }
        { tool: "atuin",    arch: "atuin",     debian: "atuin",     fedora: "atuin",     suse: "atuin",     alpine: "atuin",     brew: "atuin" }
        { tool: "bat",      arch: "bat",       debian: "bat",       fedora: "bat",       suse: "bat",       alpine: "bat",       brew: "bat" }
        { tool: "rg",       arch: "ripgrep",   debian: "ripgrep",   fedora: "ripgrep",   suse: "ripgrep",   alpine: "ripgrep",   brew: "ripgrep" }
        { tool: "fd",       arch: "fd",        debian: "fd-find",   fedora: "fd-find",   suse: "fd",        alpine: "fd",        brew: "fd" }
        { tool: "fzf",      arch: "fzf",       debian: "fzf",       fedora: "fzf",       suse: "fzf",       alpine: "fzf",       brew: "fzf" }
        { tool: "delta",    arch: "git-delta", debian: "git-delta", fedora: "git-delta", suse: "git-delta", alpine: "git-delta", brew: "git-delta" }
        { tool: "yazi",     arch: "yazi",      debian: "yazi",      fedora: "yazi",      suse: "yazi",      alpine: "yazi",      brew: "yazi" }
        { tool: "fnm",      arch: "fnm",       debian: "fnm",       fedora: "fnm",       suse: "fnm",       alpine: "fnm",       brew: "fnm" }
    ]
}

# Audits current environment against required tools
def audit-tools [os_id: string] {
    let defs = (tool-definitions)
    let os_key = match $os_id {
        "arch" | "cachyos" | "endeavouros" | "manjaro" => "arch",
        "ubuntu" | "debian" | "pop" | "linuxmint" | "tuxedo" | "elementary" | "neon" | "zorin" => "debian",
        "fedora" | "rhel" | "centos" => "fedora",
        "opensuse" | "opensuse-tumbleweed" | "opensuse-leap" | "suse" => "suse",
        "alpine" => "alpine",
        "darwin" => "brew",
        _ => "debian"
    }

    $defs | each { |entry|
        let is_installed = (has-binary $entry.tool)
        let pkg_name = ($entry | get $os_key)

        let is_special = match $os_key {
            "debian" => ($entry.tool in ["starship", "atuin", "yazi", "fnm", "just", "delta"]),
            "fedora" => ($entry.tool in ["fnm", "yazi"]),
            "suse"   => ($entry.tool in ["fnm", "yazi"]),
            _ => false
        }

        {
            tool: $entry.tool,
            pkg: $pkg_name,
            missing: (not $is_installed),
            install_type: (if $is_special { "special" } else { "system" })
        }
    }
}

# Installs system packages via native package manager
def install-system-packages [os_id: string, pkgs: list<string>] {
    match $os_id {
        "arch" | "cachyos" | "endeavouros" | "manjaro" => {
            if (has-binary paru) {
                ^paru -S --needed --noconfirm ...$pkgs
            } else if (has-binary yay) {
                ^yay -S --needed --noconfirm ...$pkgs
            } else {
                ^sudo pacman -S --needed --noconfirm ...$pkgs
            }
        }
        "ubuntu" | "debian" | "pop" | "linuxmint" | "tuxedo" | "elementary" | "neon" | "zorin" => {
            ^sudo apt update
            ^sudo apt install -y ...$pkgs
        }
        "fedora" | "rhel" | "centos" => {
            ^sudo dnf install -y ...$pkgs
        }
        "opensuse" | "opensuse-tumbleweed" | "opensuse-leap" | "suse" => {
            ^sudo zypper install -y ...$pkgs
        }
        "alpine" => {
            ^sudo apk add ...$pkgs
        }
        "darwin" => {
            ^brew install ...$pkgs
        }
        _ => {
            nu-fail $"Unsupported OS distribution '($os_id)' for automatic package installation. Please install missing packages manually."
        }
    }
}

# Fallback installer for tools not in standard repos
def install-special-tool [tool: string, os_id: string] {
    let local_bin = ($env.HOME | path join ".local" "bin")
    mkdir $local_bin

    match $tool {
        "starship" => {
            print "Installing starship via official install script..."
            ^curl -sS https://starship.rs/install.sh | ^sh -s -- -y -b $local_bin
        }
        "atuin" => {
            print "Installing atuin via official install script..."
            ^curl --proto "=https" --tlsv1.2 -sSf https://setup.atuin.sh | ^bash
        }
        "just" => {
            print "Installing just via official script..."
            ^curl --proto "=https" --tlsv1.2 -sSf https://just.systems/install.sh | ^bash -s -- --to $local_bin
        }
        "delta" => {
            if (has-binary cargo) {
                print "Installing git-delta via cargo..."
                ^cargo install git-delta
            }
        }
        "yazi" => {
            if (has-binary cargo) {
                print "Installing yazi via cargo..."
                ^cargo install --locked yazi-fm yazi-cli
            }
        }
        "fnm" => {
            print "Installing Fast Node Manager (fnm)..."
            if (has-binary curl) {
                ^curl -fsSL https://fnm.vercel.app/install | ^bash -s -- --install-dir $"($env.HOME)/.local/bin" --skip-shell
            }
        }
        _ => {
            nu-fail $"Unsupported OS distribution '($os_id)' for automatic package installation. Please install missing tools manually."
        }
    }
}

# Bootstraps default themes from matugen defaults if not present
def bootstrap-default-themes [] {
    let defaults_dir = ($env.FILE_PWD? | default "." | path join "common/.config/matugen/defaults")
    let targets = [
        [($defaults_dir | path join "ghostty-theme"), ($env.HOME | path join ".config/ghostty/themes/matugen")],
        [($defaults_dir | path join "yazi-flavor.toml"), ($env.HOME | path join ".config/yazi/flavors/matugen.yazi/flavor.toml")],
        [($defaults_dir | path join "atuin-theme.toml"), ($env.HOME | path join ".config/atuin/themes/matugen.toml")],
        [($defaults_dir | path join "micro-colorscheme.micro"), ($env.HOME | path join ".config/micro/colorschemes/matugen.micro")],
        [($defaults_dir | path join "vicinae-theme.toml"), ($env.HOME | path join ".local/share/vicinae/themes/matugen.toml")]
    ]
    for pair in $targets {
        let src = $pair.0
        let dst = $pair.1
        if ($src | path exists) and not ($dst | path exists) {
            mkdir ($dst | path dirname)
            cp $src $dst
            print $"✓ Bootstrapped default theme: ($dst)"
        }
    }
}

# Applies dotfiles Stow links and Yazi plugins
def sync-stow-links [] {
    print $"\n(ansi cyan_bold)--- Syncing Dotfiles Configurations ---(ansi reset)"
    if (has-binary just) {
        ^just link
        if (has-binary ya) {
            print "Installing Yazi plugins..."
            try { ^just install } catch {}
        }
    } else if (has-binary stow) {
        ^stow -R common --target $env.HOME --verbose
        bootstrap-default-themes
    } else {
        nu-fail "Neither 'just' nor 'stow' found. Cannot link dotfiles."
    }
    print $"\n(ansi green_bold)🎉 Dotfiles environment setup complete!(ansi reset)"
}
