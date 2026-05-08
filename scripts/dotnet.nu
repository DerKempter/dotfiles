export def dn [
    action: string@nu-complete-dn-actions,
    project?: string@nu-complete-dn-projects
] {
    let proj_arg = if ($project | is-empty) { "" } else { $project }

    match $action {
        "run" => { ^dotnet run --project $proj_arg }
        "watch" => { ^dotnet watch run --project $proj_arg }
        "build" => { ^dotnet build $proj_arg }
        "test" => { ^dotnet test $proj_arg }
        _ => { ^dotnet $action $proj_arg }
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
