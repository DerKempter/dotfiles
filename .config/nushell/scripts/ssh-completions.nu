# List hosts from SSH config for autocompletion
export def "ssh-hosts" [] {
    let config_file = ($env.HOME | path join ".ssh" "config")
    if ($config_file | path exists) {
        open $config_file
        | lines
        | where $it =~ "^Host "
        | str replace --regex "^Host " ""
        | where $it !~ "\\*" # Skip wildcards
        | split row " "
        | str trim
        | where ($it | is-not-empty)
    } else {
        []
    }
}

# Sync local starship configuration to a remote host via SSH
export def sync-starship [
    host: string@"ssh-hosts" # The SSH host (e.g., user@remote-server)
] {
    let config_path = ($nu.config-path | path dirname | path dirname | path join "starship.toml")

    print $"Ensuring remote ~/.config exists on ($host)..."
    ssh $host "mkdir -p ~/.config"

    print $"Syncing starship.toml to ($host)..."
    scp $config_path $"($host):~/.config/starship.toml"

    print "Sync complete! (Note: Starship must be installed on the remote and added to .bashrc/config.nu)"
}

# SSH Connect with working autocompletion
export def sshc [
    host: string@"ssh-hosts" # Use the custom host completer
    ...args: string          # Pass-through for other arguments
] {
    ^ssh $host ...$args
}
