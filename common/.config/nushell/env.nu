# ==============================================================================
# Environment Conversions & Sanitization
# ==============================================================================

# Sanitize / convert host environment variables inherited from other shells
$env.ENV_CONVERSIONS = ($env.ENV_CONVERSIONS? | default {} | upsert __zoxide_hooked {
    from_string: { |s| if ($s | describe) == "bool" { $s } else { $s == "true" or $s == "1" } }
    to_string: { |v| $v | into string }
})

if "__zoxide_hooked" in $env {
    hide-env -i __zoxide_hooked
}

# ==============================================================================
# Helper functions
# ==============================================================================

# Helper to check if a real external executable exists on the system
def has-binary [cmd: string] {
    let results = (which -a $cmd | where type == "external" and not ($it.path | str ends-with ".nu") and ($it.path | path exists))
    ($results | is-not-empty)
}

# ==============================================================================
# OS-Specific Environment Configuration
# ==============================================================================

$env.EDITOR = "zed"
$env.MICRO_TRUECOLOR = "1"

if $nu.os-info.name == "windows" {
    # --------------------------------------------------------------------------
    # Windows Environment
    # --------------------------------------------------------------------------
    let user_home = ($env.USERPROFILE? | default $nu.home-dir)
    let starship_cfg = ($user_home | path join ".config" "starship.toml")
    if ($starship_cfg | path exists) {
        $env.STARSHIP_CONFIG = $starship_cfg
    }

    # Ensure zoxide cache exists to prevent source errors
    let zoxide_cache = ($user_home | path join ".zoxide.nu")
    if (has-binary zoxide) {
        if not ($zoxide_cache | path exists) or (open $zoxide_cache | is-empty) {
            zoxide init nushell | save -f $zoxide_cache
        }
    } else {
        if not ($zoxide_cache | path exists) {
            "" | save -f $zoxide_cache
        }
    }

    # Starship autoload cache
    let starship_path = ($nu.data-dir | path join "vendor/autoload/starship.nu")
    if (has-binary starship) {
        if not ($starship_path | path exists) {
            mkdir ($nu.data-dir | path join "vendor/autoload")
            starship init nu | save -f $starship_path
        }
    }
} else {
    # --------------------------------------------------------------------------
    # Linux-Specific Environment
    # --------------------------------------------------------------------------
    $env.RIPGREP_CONFIG_PATH = ($env.HOME | path join ".ripgreprc")
    $env.N_PREFIX = ($env.HOME | path join ".n")

    # Dynamic Starship Config (uses cached matugen-generated theme outside git if present)
    let cached_starship = ($env.HOME | path join ".cache/starship.toml")
    let default_starship = ($env.HOME | path join ".config/starship.toml")
    $env.STARSHIP_CONFIG = (if ($cached_starship | path exists) { $cached_starship } else { $default_starship })

    # Dynamic Lazygit Config (uses cached matugen-generated theme outside git if present)
    let cached_lg_theme = ($env.HOME | path join ".cache/lazygit/theme.yml")
    let base_lg_config = ($env.HOME | path join ".config/lazygit/config.yml")
    $env.LG_CONFIG_FILE = (if ($cached_lg_theme | path exists) { $"($base_lg_config),($cached_lg_theme)" } else { $base_lg_config })

    # Path Customization
    $env.PATH = (
        $env.PATH
        | split row (char esep)
        | prepend [
            ($env.HOME | path join ".opencode" "bin")
            ($env.HOME | path join ".local" "bin")
            (if ($env.N_PREFIX? | is-not-empty) { $env.N_PREFIX | path join "bin" } else { null })
            ($env.HOME | path join ".cargo" "bin")
            ($env.HOME | path join ".nub" "bin")
            ($env.HOME | path join ".atuin" "bin")
            ($env.HOME | path join ".lmstudio" "bin")
        ]
        | compact
        | uniq
    )

    # Bun
    let bun_bin = ($env.HOME | path join ".bun" "bin")
    if ($bun_bin | path exists) {
        $env.PATH = ($env.PATH | prepend $bun_bin)
    }

    # Deno
    let deno_bin = ($env.HOME | path join ".deno" "bin")
    if ($deno_bin | path exists) {
        $env.PATH = ($env.PATH | prepend $deno_bin)
    }

    # LM Studio
    let lmstudio_bin = ($env.HOME | path join ".lmstudio" "bin")
    if ($lmstudio_bin | path exists) {
        $env.PATH = ($env.PATH | prepend $lmstudio_bin)
    }

    # SQL Server Command Line Tools
    let mssql_bin = "/opt/mssql-tools18/bin"
    if ($mssql_bin | path exists) {
        $env.PATH = ($env.PATH | append $mssql_bin)
    }

    # fnm (Fast Node Manager)
    let fnm_path = ($env.HOME | path join ".local" "share" "fnm")
    if ($fnm_path | path exists) {
        $env.PATH = ($env.PATH | prepend $fnm_path)

        if (has-binary fnm) {
            # Load fnm environment variables dynamically
            let fnm_env = (fnm env --shell bash
                | lines
                | str replace "export " ""
                | str replace -a "\"" ""
                | split column "="
                | rename name value
                | where name != "PATH"
                | reduce -f {} {|it, acc| $acc | upsert $it.name $it.value })

            load-env $fnm_env

            # Add active node version path from FNM
            if ($env.FNM_MULTISHELL_PATH? | is-not-empty) {
                $env.PATH = ($env.PATH | prepend ($env.FNM_MULTISHELL_PATH | path join "bin"))
            }
        }
    }

    # Zoxide smart directory jumping initializer (cached for startup performance)
    let zoxide_cache = ($env.HOME | path join ".zoxide.nu")
    if (has-binary zoxide) {
        if not ($zoxide_cache | path exists) or (open $zoxide_cache | is-empty) {
            zoxide init nushell | save -f $zoxide_cache
        }
    } else {
        print -e $"(ansi yellow)Warning: zoxide is not installed. Directory jumping has not been initialized.(ansi reset)"
        if not ($zoxide_cache | path exists) {
            # Create a dummy empty file to prevent parse-time source error in config.nu
            "" | save -f $zoxide_cache
        }
    }

    # Ensure ~/.cargo/env.nu exists to prevent parse-time source error in config.nu
    let cargo_env = ($env.HOME | path join ".cargo" "env.nu")
    if not ($cargo_env | path exists) {
        let cargo_dir = ($env.HOME | path join ".cargo")
        if not ($cargo_dir | path exists) {
            mkdir $cargo_dir
        }
        "" | save -f $cargo_env
    }

    # Atuin shell history hook initializer
    let atuin_share_dir = ($env.HOME | path join ".local" "share" "atuin")
    let atuin_init = ($atuin_share_dir | path join "init.nu")
    let atuin_pty = ($atuin_share_dir | path join "pty-proxy-init.nu")

    if not ($atuin_share_dir | path exists) {
        mkdir $atuin_share_dir
    }

    if (has-binary atuin) {
        if not ($atuin_init | path exists) or (open $atuin_init | is-empty) {
            atuin init nu | save -f $atuin_init
        }
        if not ($atuin_pty | path exists) or (open $atuin_pty | is-empty) {
            atuin pty-proxy init nu | save -f $atuin_pty
        }
    }

    if not ($atuin_init | path exists) {
        touch $atuin_init
    }
    if not ($atuin_pty | path exists) {
        touch $atuin_pty
    }

    # Keychain SSH Key Management
    if (has-binary keychain) {
        let keychain_output = (with-env { SHELL: csh } {
            keychain --eval --quiet --noask
        })

        let keychain_env = ($keychain_output
            | lines
            | where { |line| $line =~ "^setenv" }
            | each { |line|
                let parts = ($line | parse "setenv {key} {value};")
                if not ($parts | is-empty) {
                    let row = ($parts | first)
                    { name: $row.key, value: $row.value }
                }
            }
            | compact
            | reduce -f {} { |it, acc| $acc | upsert $it.name $it.value })

        load-env $keychain_env
    } else {
        print -e $"(ansi yellow)Warning: keychain is not installed. SSH Agent has not been initialized.(ansi reset)"
    }

    # Distro-agnostic GUI Askpass detection (KDE, Wayland/Hyprland, LXQt, GNOME)
    let is_gui = ($env.WAYLAND_DISPLAY? | is-not-empty) or ($env.DISPLAY? | is-not-empty)

    if $is_gui {
        let askpass_candidates = [
            "ksshaskpass"
            "lxqt-openssh-askpass"
            "gnome-ssh-askpass"
            "ssh-pass"
        ]

        let resolved_askpass = (
            $askpass_candidates
            | each { |bin| do -i { which $bin } }
            | flatten
            | where type == "external"
            | get -o 0.path
        )

        if ($resolved_askpass | is-not-empty) {
            {
                SSH_ASKPASS: $resolved_askpass
                SSH_ASKPASS_REQUIRE: "prefer"
            }
        } else {
            {}
        }
    } else {
        {}
    } | load-env

    # Starship Prompt Cache initialization
    let starship_path = ($nu.data-dir | path join "vendor/autoload/starship.nu")
    if (has-binary starship) {
        if not ($starship_path | path exists) {
            mkdir ($nu.data-dir | path join "vendor/autoload")
            starship init nu | save -f $starship_path
        }
    }
}
