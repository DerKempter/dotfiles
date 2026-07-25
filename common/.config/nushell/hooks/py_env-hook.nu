# Helper to recursively find a .venv folder in parent directories up to a boundary (.git or root)
def find-venv [dir: path] {
    let venv_dir = ($dir | path join ".venv")
    let bin_name = (if $nu.os-info.name == "windows" { "Scripts" } else { "bin" })
    if ($venv_dir | path exists) and (($venv_dir | path join $bin_name) | path exists) {
        $venv_dir
    } else if (($dir | path join ".git") | path exists) or ($dir == ($dir | path dirname)) {
        null
    } else {
        find-venv ($dir | path dirname)
    }
}

$env.config = ($env.config | upsert hooks.env_change.PWD [
    { |before, after|
        let active_venv = (find-venv ($after | path expand))
        let in_venv = ("VIRTUAL_ENV" in $env)

        if not ($active_venv | is-empty) {
            if not $in_venv or ($env.VIRTUAL_ENV != $active_venv) {
                let bin_name = (if $nu.os-info.name == "windows" { "Scripts" } else { "bin" })
                let bin_dir = ($active_venv | path join $bin_name)
                
                if ($bin_dir | path exists) {
                    let path_clean = (if $in_venv {
                        let old_bin_dir = ($env.VIRTUAL_ENV | path join $bin_name)
                        $env.PATH | where $it != $old_bin_dir
                    } else {
                        $env.PATH
                    })
                    
                    load-env {
                        VIRTUAL_ENV: $active_venv
                        PATH: ($path_clean | prepend $bin_dir)
                    }
                }
            }
        } else if $in_venv {
            # We are no longer in a directory with a venv in its ancestry hierarchy
            let old_venv = $env.VIRTUAL_ENV
            let bin_name = (if $nu.os-info.name == "windows" { "Scripts" } else { "bin" })
            let bin_dir = ($old_venv | path join $bin_name)
            
            hide-env VIRTUAL_ENV
            $env.PATH = ($env.PATH | where $it != $bin_dir)
        }
    }
])
