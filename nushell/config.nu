$env.config.show_banner = false

# 1. Define where Node versions will be stored
$env.N_PREFIX = ($env.HOME | path join ".n")

# 2. Add the 'n' binary and the active Node bin to your PATH
$env.PATH = (
    $env.PATH
    | prepend ($env.HOME | path join ".local" "bin")   # Where 'n' lives
    | prepend ($env.N_PREFIX | path join "bin")       # Where 'node' lives
)

$env.editor = "zed"

use ~/.config/nushell/scripts/docker.nu *
use ~/.config/nushell/scripts/python.nu *
use ~/.config/nushell/scripts/dotnet.nu *
use ~/.config/nushell/scripts/npm.nu *
use ~/.config/nushell/scripts/misc.nu *

source ~/.config/nushell/scripts/hooks.nu

source ~/.zoxide.nu

alias deactivate = hide-env VIRTUAL_ENV; $env.PATH = ($env.PATH | drop)

mkdir ($nu.data-dir | path join "vendor/autoload")
starship init nu | save -f ($nu.data-dir | path join "vendor/autoload/starship.nu")
