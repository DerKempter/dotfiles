$env.config.show_banner = false

use scripts *
$env.config.color_config = (catppuccin_mocha)

source ($nu.config-path | path dirname | path join "hooks" "py_env-hook.nu")

const ZOXIDE_PATH = ($nu.home-dir | path join ".zoxide.nu")
source $ZOXIDE_PATH

const ATUIN_PATH = ($nu.config-path | path dirname | path join "hooks" "atuin.nu")
source $ATUIN_PATH

alias deactivate = hide-env VIRTUAL_ENV; $env.PATH = ($env.PATH | drop)

alias cd = z

# Daily CLI utility aliases
alias cat = ^bat
alias lg = ^lazygit
alias ld = ^lazydocker

# Starship init
mkdir ($nu.data-dir | path join "vendor/autoload")
starship init nu | save -f ($nu.data-dir | path join "vendor/autoload/starship.nu")

# Git completions
use completions/git-completions.nu *

# Just completions
use completions/just-completions.nu *

