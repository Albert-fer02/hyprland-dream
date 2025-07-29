#!/usr/bin/env bash
# System Info Script for Waybar
# Shows CPU, RAM, and temperature information

# Colors for different states
get_color() {
    local value=$1
    local threshold1=$2
    local threshold2=$3
    
    if (( $(echo "$value >= $threshold2" | bc -l) )); then
        echo "#f7768e"  # Red for critical
    elif (( $(echo "$value >= $threshold1" | bc -l) )); then
        echo "#ff9e64"  # Orange for warning
    else
        echo "#7aa2f7"  # Blue for normal
    fi
}

# Get CPU usage
get_cpu_usage() {
    local cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | awk -F'%' '{print $1}')
    echo "$cpu_usage"
}

# Get RAM usage
get_ram_usage() {
    local ram_usage=$(free | grep Mem | awk '{printf "%.1f", $3/$2 * 100.0}')
    echo "$ram_usage"
}

# Get CPU temperature
get_cpu_temp() {
    local temp=""
    
    # Try different temperature sources
    if [[ -f /sys/class/thermal/thermal_zone0/temp ]]; then
        temp=$(cat /sys/class/thermal/thermal_zone0/temp | awk '{printf "%.0f", $1/1000}')
    elif command -v sensors &> /dev/null; then
        temp=$(sensors | grep "Core 0" | awk '{print $3}' | sed 's/+//' | sed 's/°C//')
    elif [[ -f /sys/class/hwmon/hwmon0/temp1_input ]]; then
        temp=$(cat /sys/class/hwmon/hwmon0/temp1_input | awk '{printf "%.0f", $1/1000}')
    else
        temp="N/A"
    fi
    
    echo "$temp"
}

# Format output for Waybar
format_output() {
    local cpu=$1
    local ram=$2
    local temp=$3
    
    local cpu_color=$(get_color "$cpu" 70 90)
    local ram_color=$(get_color "$ram" 80 95)
    local temp_color=$(get_color "$temp" 70 85)
    
    # Create JSON output for Waybar
    cat << EOF
{
    "text": "󰘚 ${cpu}% 󰍛 ${ram}% 󰈐 ${temp}°C",
    "tooltip": "CPU: ${cpu}% | RAM: ${ram}% | Temp: ${temp}°C",
    "class": "system-info",
    "percentage": {
        "cpu": ${cpu},
        "ram": ${ram},
        "temp": ${temp}
    }
}
EOF
}

# Main execution
main() {
    local cpu_usage=$(get_cpu_usage)
    local ram_usage=$(get_ram_usage)
    local cpu_temp=$(get_cpu_temp)
    
    format_output "$cpu_usage" "$ram_usage" "$cpu_temp"
}

# Run main function
main "$@" 