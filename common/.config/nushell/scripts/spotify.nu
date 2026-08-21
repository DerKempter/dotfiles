def spotify_types [] {
    [
        { value: "track", description: "Search and play a single track" }
        { value: "album", description: "Play an entire album" }
        { value: "artist", description: "Play top tracks by an artist" }
        { value: "playlist", description: "Search and play a playlist" }
    ]
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
    let items = ($data | get -o $key | default [])

    if ($items | is-empty) {
        print $"No ($type)s found for '($query)'"
        return
    }

    let choices = ($items | first $limit | each {|item|
        let display_str = match $type {
            "track" => {
                let artist = ($item | get -o artists | default [] | each {|a| $a.name } | str join ", ")
                let album = ($item | get -o album | get -o name | default "-")
                $"($item.name) — ($artist) [($album)]"
            },
            "album" => {
                let artist = ($item | get -o artists | default [] | each {|a| $a.name } | str join ", ")
                $"($item.name) — ($artist)"
            },
            "artist" => {
                $item.name
            },
            "playlist" => {
                let owner = ($item | get -o owner | get -o display_name | default ($item | get -o owner | get -o id | default ""))
                if ($owner | is-empty) {
                    $item.name
                } else {
                    $"($item.name) (by ($owner))"
                }
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
