# ==============================================================================
# Nushell Core Configuration & Theme
# ==============================================================================

$env.config.show_banner = false

# Import modular helper scripts and apply Catppuccin theme
use scripts *
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

# Atuin shell history hook
const ATUIN_PATH = ($nu.config-path | path dirname | path join "hooks" "atuin.nu")
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
    if not (which batcat | is-empty) {
        ^batcat ...$args
    } else {
        ^bat ...$args
    }
}

def --wrapped cat [...args] {
    if not (which ^bat | is-empty) {
        ^bat ...$args
    } else if not (which batcat | is-empty) {
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
if not (which starship | is-empty) {
    if not ($starship_path | path exists) {
        mkdir ($nu.data-dir | path join "vendor/autoload")
        starship init nu | save -f $starship_path
    }
} else {
    print -e $"(ansi yellow)Warning: starship is not installed. Custom prompt has not been initialized.(ansi reset)"
    if ($starship_path | path exists) {
        rm $starship_path
    }
}

# ==============================================================================
# Custom Completions
# ==============================================================================

# Import all autocompletion scripts via the completions module
use completions *
