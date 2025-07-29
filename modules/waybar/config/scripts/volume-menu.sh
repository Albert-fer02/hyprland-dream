#!/usr/bin/env bash
# Volume Menu Script for Waybar
# Provides volume control and audio device switching

# Check if rofi is available
if ! command -v rofi &> /dev/null; then
    notify-send "Volume Menu" "Rofi is not installed"
    exit 1
fi

# Get current volume
get_volume() {
    pactl get-sink-volume @DEFAULT_SINK@ | head -n1 | cut -d'/' -f2 | tr -d ' %'
}

# Get muted state
is_muted() {
    pactl get-sink-mute @DEFAULT_SINK@ | cut -d' ' -f2
}

# Set volume
set_volume() {
    local volume="$1"
    pactl set-sink-volume @DEFAULT_SINK@ "$volume%"
    notify-send "Volume" "Set to $volume%" -h int:value:$volume
}

# Toggle mute
toggle_mute() {
    pactl set-sink-mute @DEFAULT_SINK@ toggle
    local muted=$(is_muted)
    if [[ "$muted" == "yes" ]]; then
        notify-send "Volume" "Muted"
    else
        notify-send "Volume" "Unmuted"
    fi
}

# Get audio sinks (output devices)
get_sinks() {
    pactl list short sinks | while read -r id name description; do
        echo "$id:$name:$description"
    done
}

# Get current sink
get_current_sink() {
    pactl info | grep "Default Sink" | cut -d' ' -f3
}

# Switch audio sink
switch_sink() {
    local sink_id="$1"
    pactl set-default-sink "$sink_id"
    notify-send "Audio" "Switched to sink $sink_id"
}

# Get audio sources (input devices)
get_sources() {
    pactl list short sources | while read -r id name description; do
        echo "$id:$name:$description"
    done
}

# Get current source
get_current_source() {
    pactl info | grep "Default Source" | cut -d' ' -f3
}

# Switch audio source
switch_source() {
    local source_id="$1"
    pactl set-default-source "$source_id"
    notify-send "Audio" "Switched to source $source_id"
}

# Show volume slider
show_volume_slider() {
    local current_volume=$(get_volume)
    local volume=$(rofi -dmenu -p "Volume (%)" -theme-str 'entry {placeholder: "Enter volume (0-100)";}' -theme-str 'window {width: 300px;}' <<< "$current_volume")
    
    if [[ -n "$volume" && "$volume" =~ ^[0-9]+$ && "$volume" -ge 0 && "$volume" -le 100 ]]; then
        set_volume "$volume"
    fi
}

# Show sinks menu
show_sinks_menu() {
    local current_sink=$(get_current_sink)
    local sinks=($(get_sinks))
    
    local options=()
    for sink in "${sinks[@]}"; do
        local id=$(echo "$sink" | cut -d: -f1)
        local name=$(echo "$sink" | cut -d: -f2)
        local desc=$(echo "$sink" | cut -d: -f3)
        
        if [[ "$name" == "$current_sink" ]]; then
            options+=("● $desc (Current)")
        else
            options+=("○ $desc")
        fi
    done
    
    local choice=$(printf '%s\n' "${options[@]}" | rofi -dmenu -p "Audio Output" -theme-str 'window {width: 400px;}')
    
    if [[ -n "$choice" && "$choice" != *"(Current)"* ]]; then
        local desc=$(echo "$choice" | sed 's/^[○●] //')
        for sink in "${sinks[@]}"; do
            local id=$(echo "$sink" | cut -d: -f1)
            local name=$(echo "$sink" | cut -d: -f2)
            local sink_desc=$(echo "$sink" | cut -d: -f3)
            if [[ "$sink_desc" == "$desc" ]]; then
                switch_sink "$name"
                break
            fi
        done
    fi
}

# Show sources menu
show_sources_menu() {
    local current_source=$(get_current_source)
    local sources=($(get_sources))
    
    local options=()
    for source in "${sources[@]}"; do
        local id=$(echo "$source" | cut -d: -f1)
        local name=$(echo "$source" | cut -d: -f2)
        local desc=$(echo "$source" | cut -d: -f3)
        
        if [[ "$name" == "$current_source" ]]; then
            options+=("● $desc (Current)")
        else
            options+=("○ $desc")
        fi
    done
    
    local choice=$(printf '%s\n' "${options[@]}" | rofi -dmenu -p "Audio Input" -theme-str 'window {width: 400px;}')
    
    if [[ -n "$choice" && "$choice" != *"(Current)"* ]]; then
        local desc=$(echo "$choice" | sed 's/^[○●] //')
        for source in "${sources[@]}"; do
            local id=$(echo "$source" | cut -d: -f1)
            local name=$(echo "$source" | cut -d: -f2)
            local source_desc=$(echo "$source" | cut -d: -f3)
            if [[ "$source_desc" == "$desc" ]]; then
                switch_source "$name"
                break
            fi
        done
    fi
}

# Main menu
show_main_menu() {
    local volume=$(get_volume)
    local muted=$(is_muted)
    local mute_status=""
    
    if [[ "$muted" == "yes" ]]; then
        mute_status=" (Muted)"
    fi
    
    local options=(
        "1: Volume: ${volume}%$mute_status"
        "2: Set Volume"
        "3: Toggle Mute"
        "4: Audio Output Devices"
        "5: Audio Input Devices"
        "6: Open Pavucontrol"
    )
    
    local choice=$(printf '%s\n' "${options[@]}" | rofi -dmenu -p "Volume Control" -theme-str 'window {width: 350px;}')
    
    case "$choice" in
        *"Set Volume"*)
            show_volume_slider
            ;;
        *"Toggle Mute"*)
            toggle_mute
            ;;
        *"Audio Output Devices"*)
            show_sinks_menu
            ;;
        *"Audio Input Devices"*)
            show_sources_menu
            ;;
        *"Open Pavucontrol"*)
            pavucontrol &
            ;;
        *)
            exit 0
            ;;
    esac
}

# Handle command line arguments
case "${1:-}" in
    "up")
        local current=$(get_volume)
        local new=$((current + 5))
        if [[ $new -gt 100 ]]; then new=100; fi
        set_volume "$new"
        ;;
    "down")
        local current=$(get_volume)
        local new=$((current - 5))
        if [[ $new -lt 0 ]]; then new=0; fi
        set_volume "$new"
        ;;
    "toggle")
        toggle_mute
        ;;
    "sinks")
        show_sinks_menu
        ;;
    "sources")
        show_sources_menu
        ;;
    *)
        show_main_menu
        ;;
esac 