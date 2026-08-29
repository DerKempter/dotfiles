#!/usr/bin/env nu

# @vicinae.schemaVersion 1
# @vicinae.title Game Launcher
# @vicinae.mode silent
# @vicinae.icon 🎮

# 1. Discover all installed Steam games
let steam_dirs = [
    "~/.local/share/Steam/steamapps"
    "~/.steam/steam/steamapps"
]

let steam_games = (
    $steam_dirs
    | each { |d| glob $"($d | path expand)/appmanifest_*.acf" }
    | flatten
    | uniq
    | each { |f|
        let raw = (open --raw $f)
        let appid = ($raw | parse -r "(?m)^\\s*\"appid\"\\s+\"(?P<id>[0-9]+)\"" | get -o id.0)
        let name = ($raw | parse -r "(?m)^\\s*\"name\"\\s+\"(?P<title>[^\"]+)\"" | get -o title.0)
        
        # Filter out Proton, Steam runtimes, & SDK tools
        if $name != null and ($name | str starts-with "Proton") == false and ($name | str starts-with "Steam Linux Runtime") == false and ($name | str starts-with "Steamworks") == false {
            {
                title: $"🎮 ($name)  (Steam)"
                cmd: $"steam steam://rungameid/($appid)"
                name: $name
            }
        }
    }
    | compact
)

if ($steam_games | is-empty) {
    notify-send -u low "Game Launcher" "No installed games found in Steam libraries."
    exit 0
}

# 2. Present interactive list in Vicinae
let selection = (
    $steam_games
    | each { |g| $g.title }
    | str join (char nl)
    | ^vicinae dmenu -p "Search & launch games..."
    | str trim
)

if ($selection | is-empty) {
    exit 0
}

# 3. Match and launch
let chosen = ($steam_games | where title == $selection | first)

if ($chosen != null) {
    notify-send -u normal "Game Launcher" $"Launching ($chosen.name)..." -i input-gaming
    job spawn { ^bash -c $chosen.cmd }
}
