$env.config = ($env.config | upsert hooks.env_change.PWD [
    { |before, after|
        let venv_dir = ($after | path join ".venv")
        let in_venv = ("VIRTUAL_ENV" in $env)

        if ($venv_dir | path exists) {
            if not $in_venv or ($env.VIRTUAL_ENV != $venv_dir) {
                let bin_name = (if $nu.os-info.name == "windows" { "Scripts" } else { "bin" })
                let bin_dir = ($venv_dir | path join $bin_name)
                
                if ($bin_dir | path exists) {
                    let path_clean = (if $in_venv {
                        let old_bin_dir = ($env.VIRTUAL_ENV | path join $bin_name)
                        $env.PATH | where $it != $old_bin_dir
                    } else {
                        $env.PATH
                    })
                    
                    load-env {
                        VIRTUAL_ENV: $venv_dir
                        PATH: ($path_clean | prepend $bin_dir)
                    }
                }
            }
        } else if $in_venv {
            let project_root = ($env.VIRTUAL_ENV | path dirname)
            # Only deactivate if the new PWD is not a subdirectory of the active project root
            if not ($after | path expand | str starts-with ($project_root | path expand)) {
                let old_venv = $env.VIRTUAL_ENV
                let bin_name = (if $nu.os-info.name == "windows" { "Scripts" } else { "bin" })
                let bin_dir = ($old_venv | path join $bin_name)
                
                hide-env VIRTUAL_ENV
                $env.PATH = ($env.PATH | where $it != $bin_dir)
            }
        }
    }
])
