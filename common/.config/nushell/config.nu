# ==============================================================================
# Nushell Core Configuration & Theme
# ==============================================================================

$env.config.show_banner = false

# Import modular helper scripts (Linux only) and apply Catppuccin theme
const LINUX_SCRIPTS = (if $nu.os-info.name == "windows" {
    ($nu.default-config-dir | path join "empty.nu")
} else {
    "scripts"
})
use $LINUX_SCRIPTS *

const THEME_SCRIPT = (if $nu.os-info.name == "windows" {
    ($nu.default-config-dir | path join "scripts" "catppuccin_mocha.nu")
} else {
    ($nu.default-config-dir | path join "empty.nu")
})
use $THEME_SCRIPT *

$env.config.color_config = (catppuccin_mocha)

$env.config.table.index_mode = "auto"
$env.config.table.trim = {
    methodology: "truncating"
    wrapping_try_keep_words: false
    truncating_suffix: "..."
}
$env.config.datetime_format = {
    normal: '%a, %d %b %Y %H:%M:%S %z'    # shows up in displays of variables or other datetime's outside of tables
    # table: '%d.%m.%y %I:%M:%S%p'          # generally shows up in tabular outputs such as ls. commenting this out will change it to the default human readable datetime format
}

# ==============================================================================
# Shell Hooks & Integrations
# ==============================================================================

# Python Virtual Environment hook
source ($nu.config-path | path dirname | path join "hooks" "py_env-hook.nu")

# Zoxide smart directory switching
const ZOXIDE_PATH = ($nu.home-dir | path join ".zoxide.nu")
source $ZOXIDE_PATH

# Atuin shell history hook & PTY proxy overlay (Linux only)
if $nu.os-info.name != "windows" {
    source ($nu.config-path | path dirname | path join "hooks" "atuin_proxy.nu")
}
const ATUIN_PATH = (if $nu.os-info.name == "windows" {
    ($nu.default-config-dir | path join "empty.nu")
} else {
    ($nu.home-dir | path join ".local" "share" "atuin" "init.nu")
})
source $ATUIN_PATH

# ==============================================================================
# Custom Aliases
# ==============================================================================

# Navigation & Environments
alias cd = z
def --env deactivate [] {
    hide-env -i VIRTUAL_ENV
    $env.PATH = ($env.PATH | drop)
}

# Daily developer TUI & CLI utilities
def --wrapped bat [...args] {
    if (has-binary batcat) {
        ^batcat ...$args
    } else {
        ^bat ...$args
    }
}

def --wrapped cat [...args] {
    if (has-binary bat) {
        ^bat ...$args
    } else if (has-binary batcat) {
        ^batcat ...$args
    } else {
        ^cat ...$args
    }
}

alias lg = ^lazygit
alias ld = ^lazydocker

# ==============================================================================
# Autoloads & Prompt Setup
# ==============================================================================

# Initialize Starship prompt using the Nushell autoload directory if not already cached
let starship_path = ($nu.data-dir | path join "vendor/autoload/starship.nu")
if (has-binary starship) {
    if not ($starship_path | path exists) {
        mkdir ($nu.data-dir | path join "vendor/autoload")
        starship init nu | save -f $starship_path
    }
} else {
    if $nu.os-info.name != "windows" {
        print -e $"(ansi yellow)Warning: starship is not installed. Custom prompt has not been initialized.(ansi reset)"
    }
    if ($starship_path | path exists) {
        rm $starship_path
    }
}

# ==============================================================================
# Custom Completions & SSH Key Fleet
# ==============================================================================

# Import all autocompletion scripts via the completions module
use completions *

# Auto-load SSH identities into agent (Linux only)
if $nu.os-info.name != "windows" {
    ssh-load-fleet
}
