# ==============================================================================
# Environment Variables
# ==============================================================================

$env.EDITOR = "zed"
$env.N_PREFIX = ($env.HOME | path join ".n")

# ==============================================================================
# Path Customization
# ==============================================================================

$env.PATH = (
    $env.PATH
    | prepend ($env.HOME | path join ".opencode" "bin") # Where 'opencode' lives
    | prepend ($env.HOME | path join ".local" "bin")    # Where 'n' lives
    | prepend ($env.N_PREFIX | path join "bin")         # Where 'node' lives
    | prepend ($env.HOME | path join ".atuin" "bin")    # Where 'atuin' lives
    | prepend ($env.HOME | path join ".cargo" "bin")    # Where 'cargo' lives
)

# ==============================================================================
# External Tool Initializations & SSH Agents
# ==============================================================================

# Zoxide smart directory jumping initializer (cached for startup performance)
let zoxide_cache = ($env.HOME | path join ".zoxide.nu")
if not ($zoxide_cache | path exists) {
    zoxide init nushell | save -f $zoxide_cache
}

# Keychain SSH Key Management
let keychain_output = (^keychain --eval --quiet id_ed25519
    | lines
    | where $it =~ "setenv"
    | parse "setenv {name} {value};"
    | transpose -rd)

if not ($keychain_output | is-empty) {
    load-env $keychain_output
}
