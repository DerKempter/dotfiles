$env.N_PREFIX = ($env.HOME | path join ".n")

$env.PATH = (
    $env.PATH
    | prepend ($env.HOME | path join ".opencode" "bin") # Where 'opencode' lives
    | prepend ($env.HOME | path join ".local" "bin")    # Where 'n' lives
    | prepend ($env.N_PREFIX | path join "bin")         # Where 'node' lives
    | prepend ($env.HOME | path join ".atuin" "bin")    # Where 'atuin' lives
    | prepend ($env.HOME | path join ".cargo" "bin")    # Where 'cargo' lives
)

$env.EDITOR = "zed"

zoxide init nushell | save -f ~/.zoxide.nu

let keychain_output = (^keychain --eval --quiet id_ed25519
    | lines
    | where $it =~ "setenv"
    | parse "setenv {name} {value};"
    | transpose -rd)

if not ($keychain_output | is-empty) {
    load-env $keychain_output
}
