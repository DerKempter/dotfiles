$env.config = ($env.config | upsert hooks.env_change.PWD [
    { |before, after|
        let venv_dir = ($after | path join ".venv")
        if ($venv_dir | path exists) {
            let bin_name = (if $nu.os-info.name == "windows" { "Scripts" } else { "bin" })
            let bin_dir = ($venv_dir | path join $bin_name)

            if ($bin_dir | path exists) {
                # We use load-env because it is dynamic-friendly
                load-env {
                    VIRTUAL_ENV: $venv_dir
                    PATH: ($env.PATH | prepend $bin_dir)
                }
            }
        }
    }
])
