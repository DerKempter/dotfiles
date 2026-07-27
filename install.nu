# install.nu
# Dotfiles Essentials Installer & Audit Tool for Nushell

use common/.config/nushell/scripts/misc.nu nu-fail

# Run the dotfiles installer and dependency audit
export def main [] {
    print $"(ansi cyan_bold)==============================================================================(ansi reset)"
    print $"(ansi cyan_bold)          Dotfiles Essentials Installer & Audit - Nushell             (ansi reset)"
    print $"(ansi cyan_bold)==============================================================================(ansi reset)\n"

    # Define all required essential tools and binary alias fallbacks
    let essentials = [
        { name: "nu", binaries: ["nu"] },
        { name: "zsh", binaries: ["zsh"] },
        { name: "bash", binaries: ["bash"] },
        { name: "stow", binaries: ["stow"] },
        { name: "just", binaries: ["just"] },
        { name: "starship", binaries: ["starship"] },
        { name: "atuin", binaries: ["atuin"] },
        { name: "yazi", binaries: ["yazi"] },
        { name: "bat", binaries: ["bat", "batcat"] },
        { name: "lazygit", binaries: ["lazygit"] },
        { name: "lazydocker", binaries: ["lazydocker"] },
        { name: "micro", binaries: ["micro"] },
        { name: "zoxide", binaries: ["zoxide"] },
        { name: "keychain", binaries: ["keychain"] },
        { name: "delta", binaries: ["delta", "git-delta"] },
        { name: "fzf", binaries: ["fzf"] },
        { name: "rg", binaries: ["rg", "ripgrep"] },
        { name: "uv", binaries: ["uv"] },
        { name: "fnm", binaries: ["fnm"] }
    ]

    # Audit current availability of essential binaries
    let audit_results = ($essentials | each {|item|
        let found = ($item.binaries | each {|b| which $b } | flatten)
        if ($found | is-empty) {
            { Tool: $item.name, Status: $"(ansi red)Missing(ansi reset)", Location: "-" }
        } else {
            { Tool: $item.name, Status: $"(ansi green)Installed(ansi reset)", Location: ($found | first | get path) }
        }
    })

    print $"(ansi yellow_bold)--- Essential CLI Tools Audit ---(ansi reset)"
    print ($audit_results | table)

    let missing_tools = ($audit_results | where Location == "-" | get Tool)

    if ($missing_tools | is-empty) {
        print $"\n(ansi green_bold)✓ All essential CLI tools are installed!(ansi reset)"
    } else {
        print $"\n(ansi yellow_bold)Installing missing tools: ($missing_tools | str join ', ')...(ansi reset)"
        install-missing-tools $missing_tools
    }

    # Ensure dotfiles symlinks are active
    sync-stow-links
}

# Installs missing tools based on system package manager
def install-missing-tools [missing: list<string>] {
    let os_id = (if ("/etc/os-release" | path exists) {
        let matches = (open /etc/os-release | lines | where $it =~ "^ID=")
        let id_line = if ($matches | is-not-empty) { $matches | first } else { "ID=unknown" }
        $id_line | str replace --regex '^ID=' '' | str replace -a '"' ''
    } else {
        $nu.os-info.name
    })

    print $"Detected OS distribution: (ansi cyan_bold)($os_id)(ansi reset)"

    match $os_id {
        "cachyos" | "arch" => {
            print "Running pacman package installer..."
            let pkg_map = { "rg": "ripgrep", "delta": "git-delta" }
            let pacman_pkgs = ($missing | each {|cmd| $pkg_map | get -o $cmd | default $cmd })
            ^sudo pacman -S --needed --noconfirm ...$pacman_pkgs
        }
        "ubuntu" | "debian" | "tuxedo" | "pop" | "mint" => {
            print "Running APT package installer..."
            let apt_map = { "rg": "ripgrep", "delta": "git-delta", "bat": "bat" }
            let apt_pkgs = ($missing | each {|cmd| $apt_map | get -o $cmd | default $cmd })
            
            try {
                ^sudo apt-get update -qq
                ^sudo apt-get install -y -qq ...$apt_pkgs
            } catch {
                nu-fail "Some APT packages failed to install. Falling back to individual installation."
            }

            # Handle standalone installations for tools missing from standard apt repos
            if "just" in $missing and (which just | is-empty) {
                print "Installing just via standalone script..."
                ^curl --proto '=https' --tlsv1.2 -sSf https://just.systems/install.sh | ^bash -s -- --to $"($env.HOME)/.local/bin"
            }

            if "starship" in $missing and (which starship | is-empty) {
                print "Installing starship prompt..."
                ^curl -sS https://starship.rs/install.sh | ^sh -s -- -y -b $"($env.HOME)/.local/bin"
            }

            if "uv" in $missing and (which uv | is-empty) {
                print "Installing uv Python manager..."
                ^curl -LsSf https://astral.sh/uv/install.sh | ^sh
            }

            if "nu" in $missing and (which nu | is-empty) {
                print "Installing Nushell via Fury APT repository..."
                ^sudo mkdir -p /etc/apt/keyrings
                ^curl -fsSL https://apt.fury.io/nushell/gpg.key | ^sudo gpg --dearmor -o /etc/apt/keyrings/fury-nushell.gpg
                "deb [signed-by=/etc/apt/keyrings/fury-nushell.gpg] https://apt.fury.io/nushell/ /" | ^sudo tee /etc/apt/sources.list.d/fury-nushell.list
                ^sudo apt-get update -qq
                ^sudo apt-get install -y -qq nushell
            }

            if "lazygit" in $missing and (which lazygit | is-empty) {
                print "Installing lazygit..."
                let version = (^curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | ^grep -oP '"tag_name": "v\K[^"]+' | str trim)
                let tmp_tar = $"($env.HOME)/.local/bin/lazygit.tar.gz"
                ^curl -sLo $tmp_tar $"https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_($version)_Linux_x86_64.tar.gz"
                ^tar -xzf $tmp_tar -C $"($env.HOME)/.local/bin" lazygit
                rm -f $tmp_tar
            }

            if "lazydocker" in $missing and (which lazydocker | is-empty) {
                print "Installing lazydocker..."
                with-env { DIR: $"($env.HOME)/.local/bin" } {
                    ^curl https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | ^bash
                }
            }

            if "atuin" in $missing and (which atuin | is-empty) {
                print "Installing atuin..."
                ^curl --proto '=https' --tlsv1.2 -sSf https://setup.atuin.sh | ^bash
            }

            if "fnm" in $missing and (which fnm | is-empty) {
                print "Installing fnm..."
                ^curl -fsSL https://fnm.vercel.app/install | ^bash -s -- --install-dir $"($env.HOME)/.local/bin" --skip-shell
            }
        }
        _ => {
            nu-fail $"Unsupported OS distribution '($os_id)' for automatic package installation. Please install missing tools manually."
        }
    }
}

# Applies dotfiles Stow links and Yazi plugins
def sync-stow-links [] {
    print $"\n(ansi cyan_bold)--- Syncing Dotfiles Configurations ---(ansi reset)"
    if not (which just | is-empty) {
        ^just link
        if not (which ya | is-empty) {
            print "Installing Yazi plugins..."
            try { ^just install } catch {}
        }
    } else if not (which stow | is-empty) {
        ^stow -R common --verbose
    } else {
        nu-fail "Neither 'just' nor 'stow' found. Cannot link dotfiles."
    }
    print $"\n(ansi green_bold)🎉 Dotfiles environment setup complete!(ansi reset)"
}
