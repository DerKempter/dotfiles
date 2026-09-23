use misc.nu [get-term nu-fail]

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

# Automatically load SSH keys defined in ~/.ssh/config into ssh-agent
export def ssh-load-fleet [] {
    # 1. Guard: Ensure ssh-agent is running and reachable
    if ($env.SSH_AUTH_SOCK? == null) or not ($env.SSH_AUTH_SOCK | path exists) {
        return
    }

    # 2. Guard: Ensure ~/.ssh/config exists
    let ssh_config = ($env.HOME | path join ".ssh" "config")
    if not ($ssh_config | path exists) {
        return
    }

    # 3. Guard: Check if identities are already loaded in memory (0 = keys present)
    let agent_status = (do -i { ^ssh-add -l } | complete)
    if $agent_status.exit_code == 0 {
        return
    }

    # 4. Extract target private keys from ~/.ssh/config
    let target_keys = (
        open $ssh_config
        | lines
        | parse --regex '(?i)^\s*IdentityFile\s+(?P<path>.+)$'
        | get -o path
        | default []
        | str trim
        | str trim -c '"'
        | each { |p| $p | path expand }
        | uniq
        | where ($it | path exists)
    )

    if ($target_keys | is-empty) {
        return
    }

    # 5. Load keys quietly using GUI askpass if configured
    if ($env.SSH_ASKPASS? != null) {
        with-env { SSH_ASKPASS_REQUIRE: "force" } {
            do -i { ^ssh-add -q ...$target_keys } | complete
        }
    }
}

# Sync local starship configuration to a remote host via SSH
export def sync-starship [
    host: string@"ssh-hosts" # The SSH host (e.g., user@remote-server)
] {
    if ($host | is-empty) {
        nu-fail "Target SSH host must be specified."
        return
    }

    let config_path = ($nu.config-path | path dirname | path dirname | path join "starship.toml")

    if not ($config_path | path exists) {
        nu-fail $"Local starship configuration not found at ($config_path)."
        return
    }

    print $"Ensuring remote ~/.config exists on ($host)..."
    ^ssh $host "mkdir -p ~/.config"

    print $"Syncing starship.toml to ($host)..."
    ^scp $config_path $"($host):~/.config/starship.toml"

    print "Sync complete! (Note: Starship must be installed on the remote and added to .bashrc/config.nu)"
}

# SSH Connect with working autocompletion
export def sshc [
    host: string@"ssh-hosts" # Use the custom host completer
    ...args: string          # Pass-through for other arguments
] {
    if ($host | is-empty) {
        nu-fail "Target SSH host must be specified."
        return
    }
    with-env { TERM: (get-term) } {
        ^ssh $host ...$args
    }
}

# SSH into a remote host while dynamically injecting your actual stowed ~/.bashrc configuration
export def sshi [
    host: string@"ssh-hosts"  # Use the custom host completer
    ...ssh_args               # Additional standard SSH arguments (e.g. -p 22)
] {
    if ($host | is-empty) {
        nu-fail "Target SSH host must be specified."
        return
    }

    let bashrc_file = ($env.HOME | path join ".bashrc")
    if not ($bashrc_file | path exists) {
        nu-fail "Local ~/.bashrc not found."
        return
    }

    # Read the actual content of your local stowed .bashrc file
    let bashrc_content = (open $bashrc_file)

    # Base64 encode it and strip all newlines/returns locally to ensure a single clean line
    let encoded_bashrc = ($bashrc_content | encode base64 | str replace -a "\n" "" | str replace -a "\r" "" | str trim)

    # Execute SSH interactively, booting nu if available, else decoding and evaluating your local .bashrc using bash
    with-env { TERM: (get-term) } {
        ^ssh -t ...$ssh_args $host $"bash -c \"if command -v nu >/dev/null 2>&1; then exec nu; else exec bash --rcfile <\(printf '%s' '($encoded_bashrc)' | base64 -d; echo 'source ~/.bashrc'; echo 'stty echo 2>/dev/null'\); fi\""
    }
}

# Sync local Nushell configuration recursively to a remote host via SSH
export def sync-nushell [
    host: string@"ssh-hosts" # Use the custom host completer
] {
    if ($host | is-empty) {
        nu-fail "Target SSH host must be specified."
        return
    }

    let local_nu_dir = ($nu.config-path | path dirname)

    print $"Ensuring remote ~/.config exists on ($host)..."
    ^ssh $host "mkdir -p ~/.config"

    print $"Syncing Nushell configurations to ($host)..."
    # Use scp -r to copy the entire local nushell configuration folder recursively
    ^scp -r $local_nu_dir $"($host):~/.config/"

    print "Sync complete! (Note: Nushell must be installed on the remote host)"
}
