use misc.nu nu-fail

export def dn [
    action: string@nu-complete-dn-actions,
    project?: string@nu-complete-dn-projects
] {
    if (which dotnet | is-empty) {
        nu-fail ".NET SDK (dotnet) is not installed or not in PATH." -c "MISSING_DEPS"
        return
    }

    let proj_arg = if ($project | is-empty) { [] } else { ["--project", $project] }

    match $action {
        "run" => { ^dotnet run ...$proj_arg }
        "watch" => { ^dotnet watch run ...$proj_arg }
        "build" => { ^dotnet build (if ($project | is-not-empty) { $project } else { "" }) }
        "test" => { ^dotnet test (if ($project | is-not-empty) { $project } else { "" }) }
        _ => { ^dotnet $action (if ($project | is-not-empty) { $project } else { "" }) }
    }
}

# Completer for common dotnet actions
export def nu-complete-dn-actions [] {
    ["run", "watch", "build", "test", "restore", "clean"]
}

# Completer that finds .csproj files in your current directory tree
export def nu-complete-dn-projects [] {
    ls **/*.csproj | get name
}
