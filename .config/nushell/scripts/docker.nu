export def "nu-complete docker-contexts" [] {
    ^docker context ls --format json
    | lines
    | each { from json }
    | get Name
}

# Safety wrapper for docker
export def "docker rm" [...args] {
    let current_context = (^docker context show | str trim)
    if ($current_context != "default") {
        print (set color red; "⚠️ WARNING: You are on REMOTE context: " + $current_context)
        let confirm = (input "Are you sure? (y/n): ")
        if $confirm != "y" { return }
    }
    ^docker rm ...$args
}

export def dps [
    --all (-a)
] {
    let args = if $all { ["ps", "-a", "--format", "json"] } else { ["ps", "--format", "json"] }

    ^docker ...$args
    | lines
    | each { from json }
    | select Names Image Status
    | collect
}

export def --env dx [
    name?: string@"nu-complete docker-contexts" # Attaches the completer
] {
    if ($name | is-empty) {
        ^docker context ls --format json
        | lines
        | each { from json }
        | select Name Current DockerEndpoint Description
    } else {
        let result = (^docker context use $name | str trim)
        print $result

        let header_color = (ansi cyan)
        let reset = (ansi reset)
        print $"\n($header_color)--- Active Containers on ($name) ---($reset)"

        dps
    }
}
