zoxide init nushell | save -f ~/.zoxide.nu

let keychain_output = (^keychain --eval --agents ssh --quiet id_ed25519
    | lines
    | where $it =~ "setenv"
    | parse "setenv {name} {value};"
    | transpose -rd)

if not ($keychain_output | is-empty) {
    load-env $keychain_output
}
