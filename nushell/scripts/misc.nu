export def "git histogram" [
    --limit: int = -1 # Number of recent commits to analyze
] {
    let delimiter = "»¦«"
    let format = (
        [ "%h" "%aN" "%s" "%aD" ] | str join $delimiter
    )

    ^git log --max-count=($limit) --pretty=($format)
    | lines
    | split column $delimiter sha1 committer desc merged_at
    | histogram committer merger
}

export def parse-scraper [path: path] {
    if not ($path | path exists) {
        error make {msg: $"File not found: ($path)"}
    }

    # Using the 'slurp' Perl method to handle the multi-line merging
    # Then applying the optional regex for the dealer ID
    awk '/^[0-9]{4}-[0-9]{2}-[0-9]{2}/ { if (line) print line; line = $0; next } { line = line " " $0 } END { print line }' $path
    | lines
    | parse --regex '(?<date>\d{4}-\d{2}-\d{2}) (?<time>\d{2}:\d{2}:\d{2}) \[(?<context>[\w-]+)(?:: (?<dealer>\d+))?\] (?<level>\w+): (?<message>.*)'
    | upsert dealer { |row| if ($row.dealer | is-empty) { null } else { $row.dealer | into int } }
    | collect
}

export def fix-anims [] {
    # Force KWin to unhook the crashed instance
    dbus-send --session --dest=org.kde.KWin --type=method_call /Effects org.kde.kwin.Effects.unloadEffect string:"kwin6_effect_aura_glow" | ignore

    # Give KWin time to garbage collect
    sleep 200ms

    # Reinitialize the effect
    dbus-send --session --dest=org.kde.KWin --type=method_call /Effects org.kde.kwin.Effects.loadEffect string:"kwin6_effect_aura_glow" | ignore

    print "Aura Glow state reset."
}
