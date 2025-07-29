#!/usr/bin/env bash
# Enhanced Web Search for Rofi
# Features: multiple search engines, bookmarks, search history, smart suggestions

set -e

SCRIPT_DIR="$(dirname "$0")"
CACHE_DIR="$HOME/.cache/rofi-web-search"
HISTORY_FILE="$CACHE_DIR/search-history"
BOOKMARKS_FILE="$CACHE_DIR/bookmarks"
CONFIG_FILE="$HOME/.config/rofi/web-search-config.conf"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
RESET='\033[0m'

# Search engines configuration
declare -A SEARCH_ENGINES=(
    ["google"]="https://www.google.com/search?q="
    ["duckduckgo"]="https://duckduckgo.com/?q="
    ["bing"]="https://www.bing.com/search?q="
    ["youtube"]="https://www.youtube.com/results?search_query="
    ["github"]="https://github.com/search?q="
    ["stackoverflow"]="https://stackoverflow.com/search?q="
    ["wikipedia"]="https://en.wikipedia.org/wiki/Special:Search?search="
    ["archwiki"]="https://wiki.archlinux.org/index.php?search="
    ["aur"]="https://aur.archlinux.org/packages/?K="
    ["reddit"]="https://www.reddit.com/search/?q="
    ["amazon"]="https://www.amazon.com/s?k="
    ["ebay"]="https://www.ebay.com/sch/i.html?_nkw="
    ["maps"]="https://www.google.com/maps/search/"
    ["translate"]="https://translate.google.com/?sl=auto&tl=en&text="
    ["weather"]="https://www.google.com/search?q=weather+"
    ["currency"]="https://www.google.com/search?q=currency+converter+"
    ["time"]="https://www.google.com/search?q=time+in+"
)

# Quick search shortcuts
declare -A QUICK_SEARCHES=(
    ["yt"]="youtube"
    ["gh"]="github"
    ["so"]="stackoverflow"
    ["wiki"]="wikipedia"
    ["arch"]="archwiki"
    ["maps"]="maps"
    ["tr"]="translate"
    ["w"]="weather"
    ["c"]="currency"
    ["t"]="time"
)

# Load configuration
load_config() {
    if [[ -f "$CONFIG_FILE" ]]; then
        source "$CONFIG_FILE"
    else
        # Default configuration
        DEFAULT_ENGINE="google"
        MAX_HISTORY=100
        ENABLE_SUGGESTIONS=true
        ENABLE_BOOKMARKS=true
        BROWSER="firefox"
        ENABLE_QUICK_SEARCHES=true
    fi
}

# Initialize cache directory
init_cache() {
    mkdir -p "$CACHE_DIR"
    touch "$HISTORY_FILE"
    touch "$BOOKMARKS_FILE"
}

# Add to search history
add_to_history() {
    local query="$1"
    local engine="$2"
    local timestamp=$(date +%s)
    
    echo "$timestamp|$query|$engine" >> "$HISTORY_FILE"
    
    # Keep history manageable
    if [[ $(wc -l < "$HISTORY_FILE") -gt $MAX_HISTORY ]]; then
        tail -$MAX_HISTORY "$HISTORY_FILE" > "$HISTORY_FILE.tmp"
        mv "$HISTORY_FILE.tmp" "$HISTORY_FILE"
    fi
}

# Get search history
get_history() {
    if [[ -f "$HISTORY_FILE" ]]; then
        while IFS='|' read -r timestamp query engine; do
            local date_str=$(date -d "@$timestamp" '+%Y-%m-%d %H:%M')
            echo "$date_str | $engine: $query"
        done < <(sort -t'|' -k1,1nr "$HISTORY_FILE" | head -20)
    fi
}

# Add bookmark
add_bookmark() {
    local name="$1"
    local url="$2"
    
    echo "$name|$url" >> "$BOOKMARKS_FILE"
    log_info "Bookmark added: $name"
}

# Get bookmarks
get_bookmarks() {
    if [[ -f "$BOOKMARKS_FILE" ]]; then
        while IFS='|' read -r name url; do
            echo "$name"
        done < "$BOOKMARKS_FILE"
    fi
}

# Get bookmark URL
get_bookmark_url() {
    local name="$1"
    
    if [[ -f "$BOOKMARKS_FILE" ]]; then
        local url=$(grep "^$name|" "$BOOKMARKS_FILE" | cut -d'|' -f2)
        echo "$url"
    fi
}

# URL encode function
url_encode() {
    local string="$1"
    echo "$string" | sed 's/ /%20/g' | sed 's/&/%26/g' | sed 's/+/%2B/g' | sed 's/#/%23/g' | sed 's/\$/%24/g' | sed 's/\[/%5B/g' | sed 's/\]/%5D/g' | sed 's/{/%7B/g' | sed 's/}/%7D/g' | sed 's/|/%7C/g' | sed 's/\\/%5C/g' | sed 's/\^/%5E/g' | sed 's/~/%7E/g' | sed 's/`/%60/g'
}

# Open URL in browser
open_url() {
    local url="$1"
    
    case $BROWSER in
        "firefox")
            firefox "$url" >/dev/null 2>&1 &
            ;;
        "chrome")
            google-chrome "$url" >/dev/null 2>&1 &
            ;;
        "chromium")
            chromium "$url" >/dev/null 2>&1 &
            ;;
        "brave")
            brave-browser "$url" >/dev/null 2>&1 &
            ;;
        "edge")
            microsoft-edge "$url" >/dev/null 2>&1 &
            ;;
        *)
            xdg-open "$url" >/dev/null 2>&1 &
            ;;
    esac
    
    log_info "Opened: $url"
}

# Search with specified engine
search() {
    local query="$1"
    local engine="$2"
    
    if [[ -z "$engine" ]]; then
        engine="$DEFAULT_ENGINE"
    fi
    
    # Check if engine exists
    if [[ -z "${SEARCH_ENGINES[$engine]}" ]]; then
        log_error "Unknown search engine: $engine"
        return 1
    fi
    
    # URL encode the query
    local encoded_query=$(url_encode "$query")
    local search_url="${SEARCH_ENGINES[$engine]}$encoded_query"
    
    # Add to history
    add_to_history "$query" "$engine"
    
    # Open in browser
    open_url "$search_url"
}

# Quick search with shortcuts
quick_search() {
    local input="$1"
    local engine=""
    local query=""
    
    # Check for engine shortcut
    for shortcut in "${!QUICK_SEARCHES[@]}"; do
        if [[ "$input" =~ ^$shortcut[[:space:]]+(.+)$ ]]; then
            engine="${QUICK_SEARCHES[$shortcut]}"
            query="${BASH_REMATCH[1]}"
            break
        fi
    done
    
    if [[ -n "$engine" ]] && [[ -n "$query" ]]; then
        search "$query" "$engine"
        return 0
    fi
    
    return 1
}

# Smart suggestions based on input
get_suggestions() {
    local input="$1"
    local suggestions=()
    
    # Check if it's a URL
    if [[ "$input" =~ ^https?:// ]]; then
        echo "Open URL: $input"
        return 0
    fi
    
    # Check if it's a local file
    if [[ -f "$input" ]]; then
        echo "Open File: $input"
        return 0
    fi
    
    # Check if it's a directory
    if [[ -d "$input" ]]; then
        echo "Open Directory: $input"
        return 0
    fi
    
    # Check bookmarks
    if [[ "$ENABLE_BOOKMARKS" == "true" ]]; then
        while IFS='|' read -r name url; do
            if [[ "$name" =~ "$input" ]]; then
                suggestions+=("Bookmark: $name")
            fi
        done < "$BOOKMARKS_FILE"
    fi
    
    # Check search history
    if [[ "$ENABLE_SUGGESTIONS" == "true" ]]; then
        while IFS='|' read -r timestamp query engine; do
            if [[ "$query" =~ "$input" ]]; then
                suggestions+=("History: $query ($engine)")
            fi
        done < "$HISTORY_FILE"
    fi
    
    # Add search engine suggestions
    for engine in "${!SEARCH_ENGINES[@]}"; do
        suggestions+=("Search $engine: $input")
    done
    
    # Output suggestions
    for suggestion in "${suggestions[@]}"; do
        echo "$suggestion"
    done
}

# Handle different input types
handle_input() {
    local input="$1"
    
    # Remove extra spaces
    input=$(echo "$input" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    
    if [[ -z "$input" ]]; then
        return 0
    fi
    
    # Check for special commands
    case "$input" in
        "help"|"h"|"?")
            show_help
            ;;
        "history"|"hist")
            get_history
            ;;
        "bookmarks"|"bm")
            get_bookmarks
            ;;
        "engines"|"e")
            list_engines
            ;;
        "clear"|"cls")
            > "$HISTORY_FILE"
            echo "Search history cleared"
            ;;
        "add-bookmark"|"ab")
            add_bookmark_interactive
            ;;
        *)
            # Try quick search first
            if [[ "$ENABLE_QUICK_SEARCHES" == "true" ]]; then
                if quick_search "$input"; then
                    return 0
                fi
            fi
            
            # Check if it's a bookmark
            local bookmark_url=$(get_bookmark_url "$input")
            if [[ -n "$bookmark_url" ]]; then
                open_url "$bookmark_url"
                return 0
            fi
            
            # Default search
            search "$input"
            ;;
    esac
}

# Add bookmark interactively
add_bookmark_interactive() {
    echo -n "Bookmark name: "
    read -r name
    echo -n "URL: "
    read -r url
    
    if [[ -n "$name" ]] && [[ -n "$url" ]]; then
        add_bookmark "$name" "$url"
    fi
}

# List available search engines
list_engines() {
    echo "Available Search Engines:"
    for engine in "${!SEARCH_ENGINES[@]}"; do
        echo "  - $engine"
    done
    
    echo ""
    echo "Quick Search Shortcuts:"
    for shortcut in "${!QUICK_SEARCHES[@]}"; do
        echo "  - $shortcut -> ${QUICK_SEARCHES[$shortcut]}"
    done
}

# Show help
show_help() {
    echo "Enhanced Web Search Help:"
    echo ""
    echo "Basic Usage:"
    echo "  <query>                    - Search with default engine"
    echo "  <engine>: <query>          - Search with specific engine"
    echo ""
    echo "Quick Search Shortcuts:"
    echo "  yt <query>                 - Search YouTube"
    echo "  gh <query>                 - Search GitHub"
    echo "  so <query>                 - Search Stack Overflow"
    echo "  wiki <query>               - Search Wikipedia"
    echo "  arch <query>               - Search Arch Wiki"
    echo "  maps <query>               - Search Google Maps"
    echo "  tr <query>                 - Translate with Google"
    echo "  w <query>                  - Search weather"
    echo "  c <query>                  - Currency converter"
    echo "  t <query>                  - Time in location"
    echo ""
    echo "Special Commands:"
    echo "  history                    - Show search history"
    echo "  bookmarks                  - Show bookmarks"
    echo "  engines                    - List search engines"
    echo "  add-bookmark               - Add new bookmark"
    echo "  clear                      - Clear search history"
    echo ""
    echo "Bookmarks:"
    echo "  Type bookmark name to open"
    echo ""
    echo "URLs and Files:"
    echo "  URLs and local files will open directly"
}

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${RESET} $1" >&2
}

log_ok() {
    echo -e "${GREEN}[OK]${RESET} $1" >&2
}

log_error() {
    echo -e "${RED}[ERROR]${RESET} $1" >&2
}

# Main function
main() {
    load_config
    init_cache
    
    local input="$1"
    
    if [[ -z "$input" ]]; then
        echo "Enter search query, URL, or command (type 'help' for assistance)"
        return 0
    fi
    
    handle_input "$input"
}

# Handle Rofi integration
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    if [[ "$1" == "--suggestions" ]]; then
        # Called by Rofi for suggestions
        while read -r line; do
            if [[ -n "$line" ]]; then
                get_suggestions "$line"
            fi
        done
    elif [[ "$1" == "--history" ]]; then
        # Called by Rofi for history
        get_history
    elif [[ "$1" == "--bookmarks" ]]; then
        # Called by Rofi for bookmarks
        get_bookmarks
    else
        main "$1"
    fi
fi 