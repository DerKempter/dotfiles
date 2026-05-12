$env.config = ($env.config | upsert hooks.env_change.PWD [
    { |before, after|
        let venv_dir = ($after | path join ".venv")
        let in_venv = ("VIRTUAL_ENV" in $env)

        if ($venv_dir | path exists) {
            if not $in_venv or ($env.VIRTUAL_ENV != $venv_dir) {
                let bin_name = (if $nu.os-info.name == "windows" { "Scripts" } else { "bin" })
                let bin_dir = ($venv_dir | path join $bin_name)
                
                if ($bin_dir | path exists) {
                    load-env {
                        VIRTUAL_ENV: $venv_dir
                        PATH: ($env.PATH | prepend $bin_dir)
                    }
                }
            }
        } else if $in_venv {
            # We left a directory with a .venv, so deactivate
            let old_venv = $env.VIRTUAL_ENV
            let bin_name = (if $nu.os-info.name == "windows" { "Scripts" } else { "bin" })
            let bin_dir = ($old_venv | path join $bin_name)
            
            hide-env VIRTUAL_ENV
            $env.PATH = ($env.PATH | where $it != $bin_dir)
        }
    }
])
