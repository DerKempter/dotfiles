export def py [
    action: string@nu-complete-py-actions,
    target?: string@nu-complete-py-targets
] {
    let is_uv_project = ("uv.lock" | path exists)

    match $action {
        "run" => {
            if $is_uv_project {
                ^uv run (if ($target | is-empty) { "main.py" } else { $target })
            } else {
                ^python3 (if ($target | is-empty) { "main.py" } else { $target })
            }
        }
        "sync" | "install" => {
            if $is_uv_project { ^uv sync } else { ^pip install -r requirements.txt }
        }
        "add" => {
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
