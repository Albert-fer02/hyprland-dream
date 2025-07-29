#!/usr/bin/env bash
# Calendar Menu Script for Waybar
# Shows calendar and date/time information

# Check if rofi is available
if ! command -v rofi &> /dev/null; then
    notify-send "Calendar Menu" "Rofi is not installed"
    exit 1
fi

# Get current date and time
get_current_datetime() {
    date '+%Y-%m-%d %H:%M:%S'
}

# Get current date
get_current_date() {
    date '+%Y-%m-%d'
}

# Get current time
get_current_time() {
    date '+%H:%M:%S'
}

# Get calendar for current month
get_calendar() {
    local year=$(date '+%Y')
    local month=$(date '+%m')
    cal -m "$month" "$year"
}

# Get calendar for specific month
get_calendar_month() {
    local year="$1"
    local month="$2"
    cal -m "$month" "$year"
}

# Get upcoming events (if calendar file exists)
get_upcoming_events() {
    local calendar_file="$HOME/.local/share/calendar/events"
    
    if [[ -f "$calendar_file" ]]; then
        local today=$(date '+%Y-%m-%d')
        local next_week=$(date -d "+7 days" '+%Y-%m-%d')
        
        echo "Upcoming Events:"
        echo "================"
        while IFS= read -r line; do
            if [[ -n "$line" ]]; then
                local event_date=$(echo "$line" | cut -d'|' -f1)
                local event_desc=$(echo "$line" | cut -d'|' -f2)
                
                if [[ "$event_date" >= "$today" && "$event_date" <= "$next_week" ]]; then
                    echo "$event_date: $event_desc"
                fi
            fi
        done < "$calendar_file"
    else
        echo "No calendar events file found"
        echo "Create: $calendar_file"
        echo "Format: YYYY-MM-DD|Event Description"
    fi
}

# Show current date and time
show_datetime_info() {
    local current_datetime=$(get_current_datetime)
    local current_date=$(get_current_date)
    local current_time=$(get_current_time)
    local timezone=$(timedatectl show --property=Timezone --value)
    local uptime=$(uptime -p | sed 's/up //')
    
    local message="Date & Time Information\n\n"
    message+="Date: $current_date\n"
    message+="Time: $current_time\n"
    message+="Timezone: $timezone\n"
    message+="Uptime: $uptime\n\n"
    message+="Full DateTime: $current_datetime"
    
    rofi -e "$message" -theme-str 'window {width: 350px; height: 200px;}'
}

# Show calendar
show_calendar() {
    local calendar=$(get_calendar)
    local current_date=$(get_current_date)
    
    local message="Calendar - $(date '+%B %Y')\n\n"
    message+="$calendar\n\n"
    message+="Today: $current_date"
    
    rofi -e "$message" -theme-str 'window {width: 400px; height: 300px;}'
}

# Show events
show_events() {
    local events=$(get_upcoming_events)
    
    rofi -e "$events" -theme-str 'window {width: 500px; height: 400px;}'
}

# Show timezone selection
show_timezone_menu() {
    local current_tz=$(timedatectl show --property=Timezone --value)
    local timezones=(
        "America/Mexico_City"
        "America/New_York"
        "America/Los_Angeles"
        "Europe/London"
        "Europe/Paris"
        "Asia/Tokyo"
        "UTC"
    )
    
    local options=()
    for tz in "${timezones[@]}"; do
        if [[ "$tz" == "$current_tz" ]]; then
            options+=("● $tz (Current)")
        else
            options+=("○ $tz")
        fi
    done
    
    local choice=$(printf '%s\n' "${options[@]}" | rofi -dmenu -p "Select Timezone" -theme-str 'window {width: 400px;}')
    
    if [[ -n "$choice" && "$choice" != *"(Current)"* ]]; then
        local tz=$(echo "$choice" | sed 's/^[○●] //')
        sudo timedatectl set-timezone "$tz"
        notify-send "Timezone" "Changed to $tz"
    fi
}

# Show date/time settings
show_datetime_settings() {
    local options=(
        "1: Change Timezone"
        "2: Set Date"
        "3: Set Time"
        "4: Enable NTP"
        "5: Disable NTP"
    )
    
    local choice=$(printf '%s\n' "${options[@]}" | rofi -dmenu -p "Date/Time Settings" -theme-str 'window {width: 300px;}')
    
    case "$choice" in
        *"Change Timezone"*)
            show_timezone_menu
            ;;
        *"Set Date"*)
            local new_date=$(rofi -dmenu -p "Enter date (YYYY-MM-DD)" -theme-str 'entry {placeholder: "2024-01-01";}' -theme-str 'window {width: 300px;}')
            if [[ -n "$new_date" && "$new_date" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
                sudo timedatectl set-time "$new_date"
                notify-send "Date" "Set to $new_date"
            fi
            ;;
        *"Set Time"*)
            local new_time=$(rofi -dmenu -p "Enter time (HH:MM:SS)" -theme-str 'entry {placeholder: "12:00:00";}' -theme-str 'window {width: 300px;}')
            if [[ -n "$new_time" && "$new_time" =~ ^[0-9]{2}:[0-9]{2}:[0-9]{2}$ ]]; then
                sudo timedatectl set-time "$new_time"
                notify-send "Time" "Set to $new_time"
            fi
            ;;
        *"Enable NTP"*)
            sudo timedatectl set-ntp true
            notify-send "NTP" "Network time synchronization enabled"
            ;;
        *"Disable NTP"*)
            sudo timedatectl set-ntp false
            notify-send "NTP" "Network time synchronization disabled"
            ;;
        *)
            exit 0
            ;;
    esac
}

# Main menu
show_main_menu() {
    local current_datetime=$(get_current_datetime)
    
    local options=(
        "1: Current: $current_datetime"
        "2: Date & Time Information"
        "3: Calendar"
        "4: Upcoming Events"
        "5: Date/Time Settings"
    )
    
    local choice=$(printf '%s\n' "${options[@]}" | rofi -dmenu -p "Calendar & Time" -theme-str 'window {width: 400px;}')
    
    case "$choice" in
        *"Date & Time Information"*)
            show_datetime_info
            ;;
        *"Calendar"*)
            show_calendar
            ;;
        *"Upcoming Events"*)
            show_events
            ;;
        *"Date/Time Settings"*)
            show_datetime_settings
            ;;
        *)
            exit 0
            ;;
    esac
}

# Handle command line arguments
case "${1:-}" in
    "info")
        show_datetime_info
        ;;
    "calendar")
        show_calendar
        ;;
    "events")
        show_events
        ;;
    "settings")
        show_datetime_settings
        ;;
    "timezone")
        show_timezone_menu
        ;;
    *)
        show_main_menu
        ;;
esac 