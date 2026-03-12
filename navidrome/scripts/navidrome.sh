#!/bin/bash
# Navidrome API helper script

set -e

# Load config
CONFIG_FILE="${NAVIDROME_CONFIG:-$HOME/.navidrome/config.json}"

if [[ -f "$CONFIG_FILE" ]]; then
    NAVIDROME_URL="${NAVIDROME_URL:-$(grep -oP '"url"\s*:\s*"\K[^"]+' "$CONFIG_FILE")}"
    NAVIDROME_USER="${NAVIDROME_USER:-$(grep -oP '"user"\s*:\s*"\K[^"]+' "$CONFIG_FILE")}"
    NAVIDROME_PASSWORD="${NAVIDROME_PASSWORD:-$(grep -oP '"password"\s*:\s*"\K[^"]+' "$CONFIG_FILE")}"
fi

: "${NAVIDROME_URL:?NAVIDROME_URL not set}"
: "${NAVIDROME_USER:?NAVIDROME_USER not set}"
: "${NAVIDROME_PASSWORD:?NAVIDROME_PASSWORD not set}"

API_VERSION="1.16.1"
CLIENT="harobot"

# Base API call
navidrome_api() {
    local endpoint="$1"
    shift
    local params=""
    for arg in "$@"; do
        params="$params&$arg"
    done
    curl -s "${NAVIDROME_URL}/rest/${endpoint}?u=${NAVIDROME_USER}&p=${NAVIDROME_PASSWORD}&v=${API_VERSION}&c=${CLIENT}&f=json${params}"
}

# Commands
case "${1:-help}" in
    ping)
        navidrome_api "ping"
        ;;
    starred)
        navidrome_api "getStarred2"
        ;;
    search)
        shift
        query="${1:?Search query required}"
        navidrome_api "search3" "query=$(printf '%s' "$query" | jq -sRr @uri)"
        ;;
    artists)
        navidrome_api "getArtists"
        ;;
    artist)
        shift
        id="${1:?Artist ID required}"
        navidrome_api "getArtist" "id=$id"
        ;;
    album)
        shift
        id="${1:?Album ID required}"
        navidrome_api "getAlbum" "id=$id"
        ;;
    random)
        shift
        size="${1:-10}"
        navidrome_api "getRandomSongs" "size=$size"
        ;;
    queue)
        navidrome_api "getPlayQueue"
        ;;
    help|*)
        echo "Usage: navidrome.sh <command> [args]"
        echo ""
        echo "Commands:"
        echo "  ping              Test server connection"
        echo "  starred           Get starred/favorite music"
        echo "  search <query>    Search music library"
        echo "  artists           List all artists"
        echo "  artist <id>       Get albums by artist"
        echo "  album <id>        Get songs in album"
        echo "  random [size]     Get random songs (default: 10)"
        echo "  queue             Get current play queue"
        echo ""
        echo "Environment variables:"
        echo "  NAVIDROME_URL      Server URL"
        echo "  NAVIDROME_USER     Username"
        echo "  NAVIDROME_PASSWORD Password"
        echo "  NAVIDROME_CONFIG   Config file path (default: ~/.navidrome/config.json)"
        ;;
esac
*** End Patch