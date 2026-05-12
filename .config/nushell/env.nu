# 1. Define where Node versions will be stored
$env.N_PREFIX = ($env.HOME | path join ".n")

# 2. Add the 'n' binary and the active Node bin to your PATH
$env.PATH = (
    $env.PATH
    | prepend ($env.HOME | path join ".local" "bin")   # Where 'n' lives
    | prepend ($env.N_PREFIX | path join "bin")       # Where 'node' lives
)

$env.EDITOR = "zed"

# 3. Initialize zoxide
zoxide init nushell | save -f ~/.zoxide.nu

# 4. SSH Keychain
let keychain_output = (^keychain --eval --quiet id_ed25519
    | lines
    | where $it =~ "setenv"
    | parse "setenv {name} {value};"
    | transpose -rd)

if not ($keychain_output | is-empty) {
    load-env $keychain_output
}
