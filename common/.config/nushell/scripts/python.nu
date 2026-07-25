use misc.nu nu-fail

export def py [
    action: string@nu-complete-py-actions,
    target?: string@nu-complete-py-targets
] {
    let is_uv_project = ("uv.lock" | path exists)

    match $action {
        "run" => {
            let script_target = if ($target | is-empty) { "main.py" } else { $target }
            if $is_uv_project {
                ^uv run $script_target
            } else if (which python3 | is-not-empty) {
                ^python3 $script_target
            } else {
                nu-fail "Neither uv nor python3 are available in PATH." -c "MISSING_DEPS"
                return
            }
        }
        "sync" | "install" => {
            if $is_uv_project {
                ^uv sync
            } else if ("requirements.txt" | path exists) {
                ^pip install -r requirements.txt
            } else {
                nu-fail "No uv.lock or requirements.txt found in current directory."
                return
            }
        }
        "add" => {
            if ($target | is-empty) {
                nu-fail "Must specify a package name to add (e.g., py add requests)."
                return
            }
            if $is_uv_project { ^uv add $target } else { ^pip install $target }
        }
        _ => { ^python3 -m $action $target }
    }
}

# Completer for common Python actions
export def nu-complete-py-actions [] {
    ["run", "new", "install", "add", "test", "repl", "pytest"]
}

# Completer for local .py files
export def nu-complete-py-targets [] {
    glob *.py
}
