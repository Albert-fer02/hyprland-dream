#!/usr/bin/env bash
# Network Menu Script for Waybar
# Shows network connections and allows switching

# Check if rofi is available
if ! command -v rofi &> /dev/null; then
    notify-send "Network Menu" "Rofi is not installed"
    exit 1
fi

# Get available network interfaces
get_interfaces() {
    ip link show | grep -E "^[0-9]+:" | awk -F': ' '{print $2}' | grep -v lo
}

# Get WiFi networks
get_wifi_networks() {
    if command -v nmcli &> /dev/null; then
        nmcli -t -f SSID,SIGNAL,SECURITY device wifi list --rescan yes | \
        awk -F':' '{print $1 " (" $2 "%, " $3 ")"}' | \
        grep -v "^$"
    else
        echo "NetworkManager not available"
    fi
}

# Get current connection
get_current_connection() {
    if command -v nmcli &> /dev/null; then
        nmcli -t -f NAME,TYPE,DEVICE connection show --active | \
        head -1 | cut -d: -f1
    else
        echo "Unknown"
    fi
}

# Connect to WiFi network
connect_wifi() {
    local ssid="$1"
    if command -v nmcli &> /dev/null; then
        nmcli device wifi connect "$ssid"
        notify-send "Network" "Connecting to $ssid..."
    fi
}

# Disconnect current connection
disconnect_current() {
    if command -v nmcli &> /dev/null; then
        local current=$(get_current_connection)
        nmcli connection down "$current"
        notify-send "Network" "Disconnected from $current"
    fi
}

# Show network information
show_network_info() {
    if command -v nmcli &> /dev/null; then
        local info=$(nmcli -t -f DEVICE,TYPE,STATE,IP4.ADDRESS device status)
        local current=$(get_current_connection)
        
        local message="Current Connection: $current\n\n"
        message+="Device Information:\n"
        message+="$info"
        
        rofi -e "$message" -theme-str 'window {width: 600px; height: 400px;}'
    fi
}

# Main menu
show_main_menu() {
    local current=$(get_current_connection)
    local options=(
        "1: Current: $current"
        "2: Available WiFi Networks"
        "3: Network Information"
        "4: Disconnect"
        "5: Refresh"
    )
    
    local choice=$(printf '%s\n' "${options[@]}" | rofi -dmenu -p "Network Menu" -theme-str 'window {width: 300px;}')
    
    case "$choice" in
        *"Available WiFi Networks"*)
            show_wifi_menu
            ;;
        *"Network Information"*)
            show_network_info
            ;;
        *"Disconnect"*)
            disconnect_current
            ;;
        *"Refresh"*)
            show_main_menu
            ;;
        *)
            exit 0
            ;;
    esac
}

# WiFi networks menu
show_wifi_menu() {
    local networks=($(get_wifi_networks))
    local current=$(get_current_connection)
    
    if [[ ${#networks[@]} -eq 0 ]]; then
        rofi -e "No WiFi networks found" -theme-str 'window {width: 300px;}'
        return
    fi
    
    # Add current connection at top if connected
    local options=()
    if [[ "$current" != "Unknown" ]]; then
        options+=("Current: $current (Connected)")
    fi
    
    # Add available networks
    for network in "${networks[@]}"; do
        if [[ "$network" != "$current" ]]; then
            options+=("$network")
        fi
    done
    
    local choice=$(printf '%s\n' "${options[@]}" | rofi -dmenu -p "WiFi Networks" -theme-str 'window {width: 400px;}')
    
    if [[ -n "$choice" && "$choice" != *"(Connected)"* ]]; then
        local ssid=$(echo "$choice" | cut -d' ' -f1)
        connect_wifi "$ssid"
    fi
}

# Handle command line arguments
case "${1:-}" in
    "wifi")
        show_wifi_menu
        ;;
    "info")
        show_network_info
        ;;
    "disconnect")
        disconnect_current
        ;;
    *)
        show_main_menu
        ;;
esac 