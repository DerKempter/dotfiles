def spotify_types [] {
    [
        { value: "track", description: "Search and play a single track" }
        { value: "album", description: "Play an entire album" }
        { value: "artist", description: "Play top tracks by an artist" }
        { value: "playlist", description: "Search and play a playlist" }
    ]
}

def get-spotify-preset-file [] {
    "~/.config/spotify_player/presets.json" | path expand
}

def get-spotify-presets [] {
    let file = (get-spotify-preset-file)
    if ($file | path exists) {
        try {
            let data = (open $file)
            if ($data | describe) =~ "record" {
                $data | transpose name id
            } else {
                $data
            }
        } catch { [] }
    } else {
        []
    }
}

# Autocompletion provider that quotes names containing spaces
def spotify_preset_names [] {
    get-spotify-presets | each {|it|
        let n = ($it | get -o name | default "")
        if ($n | str contains " ") {
            $"\"($n)\""
        } else {
            $n
        }
    }
}

# Play a preset playlist from the local store
export def "play preset" [
    name: string@spotify_preset_names,
    ...rest: string # Catches unquoted trailing words if entered manually
] {
    let raw_name = ([$name] | append $rest | str join " ")
    let target_name = ($raw_name | str trim -c '"' | str trim -c "'" | str lowercase)

    let presets = (get-spotify-presets)
    let match_item = ($presets | where {|it| ($it.name | str lowercase) == $target_name } | get -o 0)

    if ($match_item | is-empty) {
        let avail = ($presets | get -o name | default [])
        if ($avail | is-empty) {
            print -e "No presets found. Add some with: spotify preset save <name> <id_or_url>"
        } else {
            print -e $"Preset '($raw_name)' not found. Available: ($avail | str join ', ')"
        }
        return
    }

    spotify_player playback start context --id $match_item.id playlist
    print $"▶ Playing preset playlist: ($match_item.name)"
}

# Helper to save or update preset IDs
export def "spotify preset save" [
    name: string,
    target: string # Accepts raw ID or full Spotify share URL
] {
    let file = (get-spotify-preset-file)
    let parent = ($file | path dirname)
    if not ($parent | path exists) { mkdir $parent }

    let clean_name = ($name | str trim -c '"' | str trim -c "'")
    let clean_id = ($target
        | str replace -r '^.*playlist/' ''
        | str replace -r '\?.*$' '')

    let current = (get-spotify-presets)
    let updated = ($current
        | where name != $clean_name
        | append { name: $clean_name, id: $clean_id }
        | sort-by name)

    $updated | to json | save -f $file
    print $"✓ Saved preset '($clean_name)' -> ($clean_id)"
}

# Helper to list all saved presets
export def "spotify preset list" [] {
    get-spotify-presets
}

# Search Spotify and return results as a structured Nushell table
export def search [query: string, --limit (-l): int = 10] {
    let res = (do { spotify_player search $query } | complete)
    if $res.exit_code != 0 { return [] }

    let data = ($res.stdout | from json)
    let tracks = ($data | get -o tracks | default [])

    $tracks | first $limit | each {|t|
        let raw_dur = ($t | get -o duration | default ($t | get -o duration_ms | default 0))

        let dur_str = if ($raw_dur | describe) =~ "record" {
            # Handles Rust Duration struct serialization { secs: ..., nanos: ... }
            fmt-time ($raw_dur | get -o secs | default 0)
        } else if ($raw_dur | describe) =~ "int|float" {
            if $raw_dur > 10000 {
                fmt-time (($raw_dur | into float) / 1000)
            } else {
                fmt-time $raw_dur
            }
        } else {
            $"($raw_dur)"
        }

        {
            id: $t.id,
            title: $t.name,
            artist: ($t.artists | each {|a| $a.name } | str join ", "),
            album: ($t | get -o album | get -o name | default "-"),
            duration: $dur_str
        }
    }
}

export def pick [
    query: string,
    --type (-t): string@spotify_types = "track",
    --limit (-l): int = 25
] {
    let res = (do { spotify_player search $query } | complete)
    if $res.exit_code != 0 {
        print -e "Error querying Spotify API"
        return
    }

    let data = ($res.stdout | from json)
    let key = if $type == "track" { "tracks" } else { $"($type)s" }
    let items = (try { $data | get $key } catch { [] })

    if ($items | is-empty) {
        print $"No ($type)s found for '($query)'"
        return
    }

    let choices = ($items | first $limit | each {|item|
        let display_str = match $type {
            "track" => {
                let artists = (try {
                    $item | get artists | each {|a| try { $a | get name } catch { "" } } | str join ", "
                } catch { "" })
                let album = (try { $item | get album.name } catch { "-" })
                $"($item.name) — ($artists) [($album)]"
            },
            "album" => {
                let artists = (try {
                    $item | get artists | each {|a| try { $a | get name } catch { "" } } | str join ", "
                } catch { "" })
                $"($item.name) — ($artists)"
            },
            "artist" => {
                $item.name
            },
            "playlist" => {
                let owner_obj = (try { $item | get owner } catch { {} })
                let d_name = (try { $owner_obj | get display_name } catch { "" })
                let o_id = (try { $owner_obj | get id } catch { "" })
                let owner = (if ($d_name | is-not-empty) { $d_name } else if ($o_id | is-not-empty) { $o_id } else { "" })

                let total = (try { $item | get tracks.total } catch { 0 })
                let desc = (try { $item | get description } catch { "" }) | str trim

                let owner_part = if ($owner | is-not-empty) { $" (by ($owner))" } else { "" }
                let count_part = if ($total | into int) > 0 { $" [($total) tracks]" } else { "" }
                let desc_part = if ($desc | is-not-empty) {
                    # Strip any HTML anchor/formatting tags returned by Spotify
                    let clean = ($desc | str replace -a -r '<[^>]*>' '')
                    $" — \"($clean)\""
                } else {
                    ""
                }

                $"($item.name)($owner_part)($count_part)($desc_part)"
            },
            _ => $item.name
        }

        {
            value: $item.id,
            display: $display_str
        }
    })

    let selected = ($choices | input list --display display $"Select ($type) to play:")
    if ($selected | is-not-empty) {
        if $type == "track" {
            spotify_player playback start track --id $selected.value
        } else {
            spotify_player playback start context --id $selected.value $type
        }
        print $"▶ Playing ($type): ($selected.display)"
    }
}

# Play Liked Songs
export def liked [--shuffle (-s)] {
    if $shuffle {
        spotify_player playback start liked --shuffle
    } else {
        spotify_player playback start liked
    }
    print "▶ Playing Liked Songs"
}

# Start Radio based on a track search
export def radio [query: string] {
    let res = (do { spotify_player search $query } | complete)
    if $res.exit_code != 0 { return }

    let track = ($res.stdout | from json | get -o tracks | get -o 0)
    if ($track | is-empty) {
        print $"No track found to seed radio from '($query)'"
        return
    }

    spotify_player playback start radio --id $track.id track
    print $"▶ Playing Radio seeded from: ($track.name)"
}

# Play top match directly or pass -i to pick from results
export def play [
    query: string,
    --type (-t): string@spotify_types = "track",
    --interactive (-i)
] {
    if $interactive {
        pick $query -t $type
        return
    }

    let res = (do { spotify_player search $query } | complete)
    if $res.exit_code != 0 {
        print -e "Error querying Spotify API"
        return
    }

    let data = ($res.stdout | from json)

    match $type {
        "track" => {
            let item = ($data | get -o tracks | get -o 0)
            if ($item | is-empty) { print $"No track found for '($query)'"; return }
            let artist = ($item.artists | each {|a| $a.name } | str join ", ")
            spotify_player playback start track --id $item.id
            print $"▶ Playing track: ($item.name) — ($artist)"
        },
        "album" | "artist" | "playlist" => {
            let key = $"($type)s"
            let item = ($data | get -o $key | get -o 0)
            if ($item | is-empty) { print $"No ($type) found for '($query)'"; return }

            let label = if $type == "album" {
                let artist = ($item.artists | each {|a| $a.name } | str join ", ")
                $"($item.name) — ($artist)"
            } else {
                $item.name
            }

            spotify_player playback start context --id $item.id $type
            print $"▶ Playing ($type): ($label)"
        },
        _ => {
            print -e $"Invalid type '($type)'. Choose from: track, album, artist, playlist"
        }
    }
}

def fmt-time [val: any] {
    try {
        let s = ($val | into float | into int)
        let m = ($s // 60 | fill -a right -c '0' -w 2)
        let rem = ($s mod 60 | fill -a right -c '0' -w 2)
        $"($m):($rem)"
    } catch {
        "-"
    }
}

export def status [] {
    let status_res = (do { playerctl --player=spotify_player,spotify status } | complete)

    if $status_res.exit_code != 0 {
        return { status: "Inactive", artist: "-", title: "-", album: "-", position: "-" }
    }

    let meta = (do {
        playerctl --player=spotify_player,spotify metadata --format "{{artist}}\t{{title}}\t{{album}}\t{{mpris:length}}"
    } | complete)

    let pos = (do { playerctl --player=spotify_player,spotify position } | complete)

    let fields = if $meta.exit_code == 0 {
        $meta.stdout | str trim | split row (char tab)
    } else {
        ["-", "-", "-", "0"]
    }

    let length_raw = ($fields | get -o 3 | default "0")
    let length_secs = (try { ($length_raw | into int) / 1_000_000 } catch { 0 })

    let cur_pos = if $pos.exit_code == 0 { fmt-time ($pos.stdout | str trim) } else { "-" }
    let total_dur = if $length_secs > 0 { fmt-time $length_secs } else { "-" }

    let artist_str = ($fields | get -o 0 | default "-")
    let title_str = ($fields | get -o 1 | default "-")
    let album_str = ($fields | get -o 2 | default "-")

    {
        status: ($status_res.stdout | str trim),
        artist: (if ($artist_str | is-empty) { "-" } else { $artist_str }),
        title: (if ($title_str | is-empty) { "-" } else { $title_str }),
        album: (if ($album_str | is-empty) { "-" } else { $album_str }),
        position: $"($cur_pos) / ($total_dur)"
    }
}

# Control commands using native spotify_player socket/CLI
export def toggle [] { spotify_player playback play-pause }
export def next []   { spotify_player playback next }
export def prev []   { spotify_player playback previous }
export def vol [val: string] {
    let clean = ($val | str trim | str replace "%" "")

    if ($clean | str starts-with "+") or ($clean | str starts-with "-") {
        let offset = (try { $clean | into int } catch { 0 })
        spotify_player playback volume --offset -- $offset
    } else {
        let target = (try { $clean | into int } catch { 50 })
        spotify_player playback volume $target
    }
}
export def player []    { spotify_player }
