# ==============================================================================
# Nushell Core Configuration & Theme
# ==============================================================================

$env.config.show_banner = false

# Import modular helper scripts and apply Catppuccin theme
use scripts *
$env.config.color_config = (catppuccin_mocha)

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
alias cat = ^bat
alias lg = ^lazygit
alias ld = ^lazydocker

# ==============================================================================
# Autoloads & Prompt Setup
# ==============================================================================

# Initialize Starship prompt using the Nushell autoload directory if not already cached
let starship_path = ($nu.data-dir | path join "vendor/autoload/starship.nu")
if not ($starship_path | path exists) {
    mkdir ($nu.data-dir | path join "vendor/autoload")
    starship init nu | save -f $starship_path
}

# ==============================================================================
# Custom Completions
# ==============================================================================

# Import all autocompletion scripts via the completions module
use completions *
