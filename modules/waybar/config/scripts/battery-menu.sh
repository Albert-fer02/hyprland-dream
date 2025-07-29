#!/usr/bin/env bash
# Battery Menu Script for Waybar
# Shows battery information and power management options

# Check if rofi is available
if ! command -v rofi &> /dev/null; then
    notify-send "Battery Menu" "Rofi is not installed"
    exit 1
fi

# Get battery information
get_battery_info() {
    local battery_path="/sys/class/power_supply/BAT0"
    
    if [[ ! -d "$battery_path" ]]; then
        echo "No battery found"
        return 1
    fi
    
    local capacity=$(cat "$battery_path/capacity" 2>/dev/null || echo "0")
    local status=$(cat "$battery_path/status" 2>/dev/null || echo "Unknown")
    local power_now=$(cat "$battery_path/power_now" 2>/dev/null || echo "0")
    local energy_now=$(cat "$battery_path/energy_now" 2>/dev/null || echo "0")
    local energy_full=$(cat "$battery_path/energy_full" 2>/dev/null || echo "0")
    
    # Convert to readable values
    power_now=$((power_now / 1000))  # Convert to mW
    energy_now=$((energy_now / 1000))  # Convert to mWh
    energy_full=$((energy_full / 1000))  # Convert to mWh
    
    echo "$capacity:$status:$power_now:$energy_now:$energy_full"
}

# Calculate time remaining
calculate_time_remaining() {
    local power_now="$1"
    local energy_now="$2"
    
    if [[ "$power_now" -gt 0 ]]; then
        local hours=$((energy_now / power_now))
        local minutes=$(((energy_now % power_now) * 60 / power_now))
        echo "${hours}h ${minutes}m"
    else
        echo "Calculating..."
    fi
}

# Get power consumption
get_power_consumption() {
    local power_now="$1"
    if [[ "$power_now" -gt 0 ]]; then
        echo "${power_now}mW"
    else
        echo "Unknown"
    fi
}

# Check if charging
is_charging() {
    local status="$1"
    [[ "$status" == "Charging" ]]
}

# Get battery health
get_battery_health() {
    local battery_path="/sys/class/power_supply/BAT0"
    local health_file="$battery_path/health"
    
    if [[ -f "$health_file" ]]; then
        cat "$health_file"
    else
        echo "Unknown"
    fi
}

# Show battery information
show_battery_info() {
    local battery_info=$(get_battery_info)
    
    if [[ "$battery_info" == "No battery found" ]]; then
        rofi -e "No battery detected on this system" -theme-str 'window {width: 300px;}'
        return
    fi
    
    local capacity=$(echo "$battery_info" | cut -d: -f1)
    local status=$(echo "$battery_info" | cut -d: -f2)
    local power_now=$(echo "$battery_info" | cut -d: -f3)
    local energy_now=$(echo "$battery_info" | cut -d: -f4)
    local energy_full=$(echo "$battery_info" | cut -d: -f5)
    
    local time_remaining=""
    local power_consumption=$(get_power_consumption "$power_now")
    local health=$(get_battery_health)
    
    if is_charging "$status"; then
        time_remaining="Charging..."
    else
        time_remaining=$(calculate_time_remaining "$power_now" "$energy_now")
    fi
    
    local message="Battery Information\n\n"
    message+="Capacity: ${capacity}%\n"
    message+="Status: $status\n"
    message+="Time Remaining: $time_remaining\n"
    message+="Power Consumption: $power_consumption\n"
    message+="Current Energy: ${energy_now}mWh\n"
    message+="Full Capacity: ${energy_full}mWh\n"
    message+="Health: $health"
    
    rofi -e "$message" -theme-str 'window {width: 400px; height: 300px;}'
}

# Show power management options
show_power_menu() {
    local options=(
        "1: Battery Information"
        "2: Power Settings"
        "3: Suspend"
        "4: Hibernate"
        "5: Lock Screen"
        "6: Logout"
        "7: Shutdown"
        "8: Reboot"
    )
    
    local choice=$(printf '%s\n' "${options[@]}" | rofi -dmenu -p "Power Management" -theme-str 'window {width: 300px;}')
    
    case "$choice" in
        *"Battery Information"*)
            show_battery_info
            ;;
        *"Power Settings"*)
            if command -v power-profiles-daemon &> /dev/null; then
                show_power_profiles
            else
                rofi -e "Power profiles daemon not available" -theme-str 'window {width: 300px;}'
            fi
            ;;
        *"Suspend"*)
            systemctl suspend
            ;;
        *"Hibernate"*)
            systemctl hibernate
            ;;
        *"Lock Screen"*)
            if command -v swaylock &> /dev/null; then
                swaylock
            elif command -v loginctl &> /dev/null; then
                loginctl lock-session
            fi
            ;;
        *"Logout"*)
            if command -v wlogout &> /dev/null; then
                wlogout
            else
                hyprctl dispatch exit
            fi
            ;;
        *"Shutdown"*)
            systemctl poweroff
            ;;
        *"Reboot"*)
            systemctl reboot
            ;;
        *)
            exit 0
            ;;
    esac
}

# Show power profiles (if available)
show_power_profiles() {
    local profiles=$(powerprofilesctl list | grep -E "^\*|^ " | sed 's/^\* //; s/^  //')
    local current=$(powerprofilesctl get)
    
    local options=()
    while IFS= read -r profile; do
        if [[ -n "$profile" ]]; then
            if [[ "$profile" == "$current" ]]; then
                options+=("● $profile (Current)")
            else
                options+=("○ $profile")
            fi
        fi
    done <<< "$profiles"
    
    local choice=$(printf '%s\n' "${options[@]}" | rofi -dmenu -p "Power Profile" -theme-str 'window {width: 300px;}')
    
    if [[ -n "$choice" && "$choice" != *"(Current)"* ]]; then
        local profile=$(echo "$choice" | sed 's/^[○●] //')
        powerprofilesctl set "$profile"
        notify-send "Power Profile" "Switched to $profile"
    fi
}

# Check battery level and show warnings
check_battery_warnings() {
    local battery_info=$(get_battery_info)
    
    if [[ "$battery_info" == "No battery found" ]]; then
        return
    fi
    
    local capacity=$(echo "$battery_info" | cut -d: -f1)
    local status=$(echo "$battery_info" | cut -d: -f2)
    
    # Don't show warnings if charging
    if is_charging "$status"; then
        return
    fi
    
    # Show warnings based on battery level
    if [[ "$capacity" -le 10 ]]; then
        notify-send -u critical "Battery Critical" "Battery level: ${capacity}% - Please connect charger!"
    elif [[ "$capacity" -le 20 ]]; then
        notify-send -u normal "Battery Low" "Battery level: ${capacity}% - Consider connecting charger"
    fi
}

# Main execution
main() {
    # Check for warnings first
    check_battery_warnings
    
    # Show main menu
    show_power_menu
}

# Handle command line arguments
case "${1:-}" in
    "info")
        show_battery_info
        ;;
    "warnings")
        check_battery_warnings
        ;;
    "profiles")
        show_power_profiles
        ;;
    *)
        main
        ;;
esac 