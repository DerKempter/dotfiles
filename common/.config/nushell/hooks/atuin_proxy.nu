# Atuin PTY Proxy initialization hook for Nushell
# Wraps the interactive terminal session in Atuin's PTY proxy with Nushell explicitly defined

if (has-binary atuin) and (is-terminal --stdin) and (is-terminal --stdout) {
    let tmux_current = ($env.TMUX? | default "")
    let tmux_previous = ($env.ATUIN_PTY_PROXY_TMUX? | default ($env.ATUIN_HEX_TMUX? | default ""))

    if (($env.ATUIN_PTY_PROXY_ACTIVE? | default ($env.ATUIN_HEX_ACTIVE? | default "")) | is-empty) or ($tmux_current != $tmux_previous) {
        $env.ATUIN_PTY_PROXY_ACTIVE = "1"
        $env.ATUIN_PTY_PROXY_TMUX = $tmux_current
        let nu_path = (which -a nu | where type == "external" | get 0.path)
        exec atuin pty-proxy --shell $nu_path
    }
}
