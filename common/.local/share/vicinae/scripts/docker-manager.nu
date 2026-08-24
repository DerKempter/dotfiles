#!/usr/bin/env nu

# @vicinae.schemaVersion 1
# @vicinae.title Docker Container Manager
# @vicinae.mode silent
# @vicinae.icon 🐳

def main [] {
    let containers = (
        ^docker ps -a --format '{{.Names}} ({{.Status}})'
        | lines
        | where { |it| ($it | str trim | is-not-empty) }
    )

    if ($containers | is-empty) {
        ^notify-send "Docker" "No containers found." -a "Docker"
        return
    }

    let selection = ($containers | str join (char nl) | ^vicinae dmenu -p "Container..." | str trim)
    if ($selection | is-empty) { return }

    let name = ($selection | split row " " | first)
    let actions = ["Restart", "Stop", "Start", "Follow Logs in Terminal"]
    let action = ($actions | str join (char nl) | ^vicinae dmenu -p $"Action for ($name)..." | str trim)

    match $action {
        "Restart" => { ^docker restart $name; ^notify-send "Docker" $"Restarted ($name)" -a "Docker" }
        "Stop" => { ^docker stop $name; ^notify-send "Docker" $"Stopped ($name)" -a "Docker" }
        "Start" => { ^docker start $name; ^notify-send "Docker" $"Started ($name)" -a "Docker" }
        "Follow Logs in Terminal" => { ^ghostty -e docker logs -f $name }
        _ => {}
    }
}
