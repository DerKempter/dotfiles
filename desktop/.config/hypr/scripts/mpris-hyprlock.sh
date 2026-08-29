#!/usr/bin/env bash

# Fetch playback status
status=$(playerctl status 2>/dev/null)

if [ "$status" = "Playing" ]; then
    player=$(playerctl metadata --format "{{playerName}}" 2>/dev/null)
    artist=$(playerctl metadata --format "{{artist}}" 2>/dev/null)
    title=$(playerctl metadata --format "{{title}}" 2>/dev/null)
    pos=$(playerctl metadata --format "{{duration(position)}}/{{duration(mpris:length)}}" 2>/dev/null)
    
    case "$player" in
        spotify*|fastpotify*) icon="" ;;
        firefox*) icon="" ;;
        zen*) icon="󰈹" ;;
        chromium*|chrome*) icon="" ;;
        mpv*) icon="" ;;
        *) icon="" ;;
    esac

    # Truncate title if too long
    if [ ${#title} -gt 35 ]; then
        title="${title:0:32}..."
    fi
    if [ ${#artist} -gt 25 ]; then
        artist="${artist:0:22}..."
    fi

    if [ -n "$title" ]; then
        if [ -n "$artist" ]; then
            echo "$icon  $title  •  $artist  [$pos]"
        else
            echo "$icon  $title  [$pos]"
        fi
    fi
elif [ "$status" = "Paused" ]; then
    player=$(playerctl metadata --format "{{playerName}}" 2>/dev/null)
    artist=$(playerctl metadata --format "{{artist}}" 2>/dev/null)
    title=$(playerctl metadata --format "{{title}}" 2>/dev/null)
    
    case "$player" in
        spotify*|fastpotify*) icon="" ;;
        firefox*) icon="" ;;
        zen*) icon="󰈹" ;;
        chromium*|chrome*) icon="" ;;
        mpv*) icon="" ;;
        *) icon="" ;;
    esac

    if [ ${#title} -gt 35 ]; then
        title="${title:0:32}..."
    fi
    if [ ${#artist} -gt 25 ]; then
        artist="${artist:0:22}..."
    fi

    if [ -n "$title" ]; then
        if [ -n "$artist" ]; then
            echo "$icon  $title  •  $artist  (Paused)"
        else
            echo "$icon  $title  (Paused)"
        fi
    fi
else
    echo ""
fi
