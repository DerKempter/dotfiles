# GPU-accelerated terminal file manager with automated directory syncing on exit.
export def --env y [...args] {
    let tmp = (mktemp -t "yazi-cwd.XXXXXX")
    
    # Run yazi and write the final active directory path to our temp file
    ^yazi ...$args --cwd-file $tmp

    if ($tmp | path exists) {
        let cwd = (open $tmp | str trim)
        if ($cwd | is-empty) == false and $cwd != $env.PWD {
            cd $cwd
        }
        rm -f $tmp
    }
}
