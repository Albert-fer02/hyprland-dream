#!/usr/bin/env bash
# Enhanced Fuzzy Search for Rofi
# Features: intelligent ranking, caching, performance optimization

set -e

SCRIPT_DIR="$(dirname "$0")"
CACHE_DIR="$HOME/.cache/rofi-fuzzy"
HISTORY_FILE="$CACHE_DIR/search-history"
APPS_CACHE="$CACHE_DIR/apps-cache"
CONFIG_FILE="$HOME/.config/rofi/fuzzy-config.conf"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
RESET='\033[0m'

# Initialize cache directory
init_cache() {
    mkdir -p "$CACHE_DIR"
    touch "$HISTORY_FILE"
    touch "$APPS_CACHE"
}

# Load configuration
load_config() {
    if [[ -f "$CONFIG_FILE" ]]; then
        source "$CONFIG_FILE"
    else
        # Default configuration
        MAX_RESULTS=20
        CACHE_DURATION=3600  # 1 hour
        FUZZY_THRESHOLD=0.3
        HISTORY_WEIGHT=0.3
        RECENCY_WEIGHT=0.2
        POPULARITY_WEIGHT=0.1
    fi
}

# Calculate fuzzy match score
fuzzy_score() {
    local query="$1"
    local target="$2"
    
    # Convert to lowercase for case-insensitive matching
    query=$(echo "$query" | tr '[:upper:]' '[:lower:]')
    target=$(echo "$target" | tr '[:upper:]' '[:lower:]')
    
    local score=0
    local query_len=${#query}
    local target_len=${#target}
    
    # Exact match gets highest score
    if [[ "$target" == *"$query"* ]]; then
        score=$((score + 100))
        
        # Bonus for start of word matches
        if [[ "$target" =~ ^"$query" ]] || [[ "$target" =~ [[:space:]]"$query" ]]; then
            score=$((score + 50))
        fi
    fi
    
    # Character-by-character fuzzy matching
    local query_chars=($(echo "$query" | grep -o .))
    local target_chars=($(echo "$target" | grep -o .))
    
    local match_count=0
    local last_match_pos=-1
    
    for char in "${query_chars[@]}"; do
        for ((i=last_match_pos+1; i<target_len; i++)); do
            if [[ "${target_chars[$i]}" == "$char" ]]; then
                match_count=$((match_count + 1))
                last_match_pos=$i
                break
            fi
        done
    done
    
    # Calculate fuzzy score based on character matches
    if [[ $match_count -gt 0 ]]; then
        local fuzzy_ratio=$(echo "scale=2; $match_count / $query_len" | bc -l)
        score=$((score + $(echo "scale=0; $fuzzy_ratio * 50" | bc -l)))
    fi
    
    # Penalty for length difference
    local length_diff=$((target_len - query_len))
    if [[ $length_diff -gt 0 ]]; then
        score=$((score - length_diff))
    fi
    
    echo $score
}

# Get application usage history
get_app_history() {
    local app_name="$1"
    local count=0
    
    if [[ -f "$HISTORY_FILE" ]]; then
        count=$(grep -c "^$app_name:" "$HISTORY_FILE" 2>/dev/null || echo "0")
    fi
    
    echo $count
}

# Get recent usage timestamp
get_recent_usage() {
    local app_name="$1"
    local timestamp=0
    
    if [[ -f "$HISTORY_FILE" ]]; then
        timestamp=$(grep "^$app_name:" "$HISTORY_FILE" | tail -1 | cut -d: -f2 2>/dev/null || echo "0")
    fi
    
    echo $timestamp
}

# Calculate popularity score
calculate_popularity() {
    local app_name="$1"
    local history_count=$(get_app_history "$app_name")
    local recent_usage=$(get_recent_usage "$app_name")
    local current_time=$(date +%s)
    
    # Time decay factor (more recent usage = higher score)
    local time_diff=$((current_time - recent_usage))
    local time_decay=0
    
    if [[ $time_diff -lt 86400 ]]; then  # Last 24 hours
        time_decay=1.0
    elif [[ $time_diff -lt 604800 ]]; then  # Last week
        time_decay=0.7
    elif [[ $time_diff -lt 2592000 ]]; then  # Last month
        time_decay=0.4
    else
        time_decay=0.1
    fi
    
    # Calculate popularity score
    local popularity_score=$(echo "scale=2; $history_count * $time_decay" | bc -l)
    echo $popularity_score
}

# Cache applications list
cache_applications() {
    local cache_age=0
    
    if [[ -f "$APPS_CACHE" ]]; then
        cache_age=$(($(date +%s) - $(stat -c %Y "$APPS_CACHE" 2>/dev/null || echo "0")))
    fi
    
    if [[ $cache_age -gt $CACHE_DURATION ]] || [[ ! -f "$APPS_CACHE" ]]; then
        log_info "Updating applications cache..."
        
        # Get desktop files
        local desktop_dirs=(
            "/usr/share/applications"
            "/usr/local/share/applications"
            "$HOME/.local/share/applications"
        )
        
        > "$APPS_CACHE"
        
        for dir in "${desktop_dirs[@]}"; do
            if [[ -d "$dir" ]]; then
                find "$dir" -name "*.desktop" -type f 2>/dev/null | while read -r file; do
                    local name=$(grep "^Name=" "$file" | head -1 | cut -d= -f2)
                    local exec_cmd=$(grep "^Exec=" "$file" | head -1 | cut -d= -f2)
                    local categories=$(grep "^Categories=" "$file" | head -1 | cut -d= -f2)
                    local icon=$(grep "^Icon=" "$file" | head -1 | cut -d= -f2)
                    
                    if [[ -n "$name" ]] && [[ -n "$exec_cmd" ]]; then
                        echo "$name|$exec_cmd|$categories|$icon" >> "$APPS_CACHE"
                    fi
                done
            fi
        done
        
        log_ok "Applications cache updated"
    fi
}

# Search applications with intelligent ranking
search_applications() {
    local query="$1"
    local results=()
    
    if [[ -z "$query" ]]; then
        # Return recently used applications
        get_recent_apps
        return
    fi
    
    cache_applications
    
    # Read cached applications and calculate scores
    local temp_file=$(mktemp)
    
    while IFS='|' read -r name exec_cmd categories icon; do
        local fuzzy_score=$(fuzzy_score "$query" "$name")
        local popularity_score=$(calculate_popularity "$name")
        
        # Calculate final score
        local final_score=$(echo "scale=2; $fuzzy_score + ($popularity_score * $POPULARITY_WEIGHT)" | bc -l)
        
        if [[ $(echo "$final_score > 0" | bc -l) -eq 1 ]]; then
            echo "$final_score|$name|$exec_cmd|$categories|$icon" >> "$temp_file"
        fi
    done < "$APPS_CACHE"
    
    # Sort by score and limit results
    sort -t'|' -k1,1nr "$temp_file" | head -n "$MAX_RESULTS" | while IFS='|' read -r score name exec_cmd categories icon; do
        results+=("$name")
    done
    
    rm "$temp_file"
    
    # Output results for Rofi
    for result in "${results[@]}"; do
        echo "$result"
    done
}

# Get recently used applications
get_recent_apps() {
    local recent_apps=()
    
    if [[ -f "$HISTORY_FILE" ]]; then
        # Get unique apps sorted by most recent usage
        while IFS=':' read -r app_name timestamp; do
            if [[ ! " ${recent_apps[@]} " =~ " ${app_name} " ]]; then
                recent_apps+=("$app_name")
            fi
        done < <(sort -t: -k2,2nr "$HISTORY_FILE" | head -20)
    fi
    
    # Output recent apps
    for app in "${recent_apps[@]}"; do
        echo "$app"
    done
}

# Record application usage
record_usage() {
    local app_name="$1"
    local timestamp=$(date +%s)
    
    echo "$app_name:$timestamp" >> "$HISTORY_FILE"
    
    # Keep history file manageable
    if [[ $(wc -l < "$HISTORY_FILE") -gt 1000 ]]; then
        tail -500 "$HISTORY_FILE" > "$HISTORY_FILE.tmp"
        mv "$HISTORY_FILE.tmp" "$HISTORY_FILE"
    fi
}

# Launch application
launch_app() {
    local app_name="$1"
    
    # Find the application in cache
    local app_info=$(grep "^$app_name|" "$APPS_CACHE" | head -1)
    
    if [[ -n "$app_info" ]]; then
        IFS='|' read -r name exec_cmd categories icon <<< "$app_info"
        
        # Record usage
        record_usage "$app_name"
        
        # Launch application
        nohup sh -c "$exec_cmd" >/dev/null 2>&1 &
        
        log_info "Launched: $app_name"
    else
        log_error "Application not found: $app_name"
    fi
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
    init_cache
    load_config
    
    local query="$1"
    
    if [[ -z "$query" ]]; then
        # Show recent applications
        get_recent_apps
    else
        # Search applications
        search_applications "$query"
    fi
}

# Handle selection
handle_selection() {
    local selected="$1"
    
    if [[ -n "$selected" ]]; then
        launch_app "$selected"
    fi
}

# Check if script is being called by Rofi
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    if [[ "$1" == "--launch" ]]; then
        handle_selection "$2"
    else
        main "$1"
    fi
fi 