#!/usr/bin/env bash
# Theme Switcher Script for Waybar
# Allows dynamic theme switching with live preview

# Check if rofi is available
if ! command -v rofi &> /dev/null; then
    notify-send "Theme Switcher" "Rofi is not installed"
    exit 1
fi

# Configuration directory
CONFIG_DIR="$HOME/.config/waybar"
THEMES_DIR="$CONFIG_DIR/themes"
CURRENT_STYLE="$CONFIG_DIR/style.css"

# Available themes
THEMES=(
    "default:Tokyo Night (Default)"
    "nord:Nord Theme"
    "dracula:Dracula Theme"
    "catppuccin:Catppuccin Mocha"
    "tokyo-night:Tokyo Night"
)

# Create themes directory if it doesn't exist
create_themes_dir() {
    if [[ ! -d "$THEMES_DIR" ]]; then
        mkdir -p "$THEMES_DIR"
        notify-send "Theme Switcher" "Created themes directory: $THEMES_DIR"
    fi
}

# Copy theme files from module to user config
copy_themes() {
    local module_themes_dir="$(dirname "$0")/../themes"
    
    if [[ -d "$module_themes_dir" ]]; then
        cp -r "$module_themes_dir"/* "$THEMES_DIR/" 2>/dev/null
        notify-send "Theme Switcher" "Themes copied to $THEMES_DIR"
    else
        notify-send "Theme Switcher" "Module themes directory not found"
        return 1
    fi
}

# Get current theme
get_current_theme() {
    if [[ -L "$CURRENT_STYLE" ]]; then
        local target=$(readlink "$CURRENT_STYLE")
        basename "$target" .css
    elif [[ -f "$CURRENT_STYLE" ]]; then
        # Try to detect theme from content
        if grep -q "TOKYO NIGHT" "$CURRENT_STYLE" 2>/dev/null; then
            echo "tokyo-night"
        elif grep -q "NORD THEME" "$CURRENT_STYLE" 2>/dev/null; then
            echo "nord"
        elif grep -q "DRACULA THEME" "$CURRENT_STYLE" 2>/dev/null; then
            echo "dracula"
        elif grep -q "CATPPUCCIN THEME" "$CURRENT_STYLE" 2>/dev/null; then
            echo "catppuccin"
        else
            echo "default"
        fi
    else
        echo "default"
    fi
}

# Apply theme
apply_theme() {
    local theme="$1"
    local theme_file="$THEMES_DIR/${theme}.css"
    
    if [[ ! -f "$theme_file" ]]; then
        notify-send "Theme Switcher" "Theme file not found: $theme_file"
        return 1
    fi
    
    # Create backup of current style
    if [[ -f "$CURRENT_STYLE" && ! -L "$CURRENT_STYLE" ]]; then
        cp "$CURRENT_STYLE" "$CURRENT_STYLE.backup"
    fi
    
    # Create symlink to theme
    ln -sf "$theme_file" "$CURRENT_STYLE"
    
    # Restart waybar
    restart_waybar
    
    notify-send "Theme Switcher" "Applied theme: $theme"
}

# Restart waybar
restart_waybar() {
    # Kill existing waybar processes
    pkill -f waybar 2>/dev/null
    
    # Wait a moment
    sleep 0.5
    
    # Start waybar in background
    waybar &
    
    # Save PID for future reference
    echo $! > /tmp/waybar.pid 2>/dev/null
}

# Show theme preview
preview_theme() {
    local theme="$1"
    local theme_file="$THEMES_DIR/${theme}.css"
    
    if [[ ! -f "$theme_file" ]]; then
        rofi -e "Theme file not found: $theme_file" -theme-str 'window {width: 400px;}'
        return
    fi
    
    # Extract color palette from theme
    local colors=$(grep -E "^[[:space:]]*--[a-zA-Z-]+:" "$theme_file" | head -10)
    
    local preview="Theme Preview: $theme\n\n"
    preview+="Color Palette:\n"
    preview+="$colors\n\n"
    preview+="Click 'Apply' to switch to this theme"
    
    rofi -e "$preview" -theme-str 'window {width: 500px; height: 400px;}'
}

# Show theme information
show_theme_info() {
    local theme="$1"
    local theme_file="$THEMES_DIR/${theme}.css"
    
    if [[ ! -f "$theme_file" ]]; then
        rofi -e "Theme file not found: $theme_file" -theme-str 'window {width: 400px;}'
        return
    fi
    
    local info="Theme Information\n\n"
    info+="Name: $theme\n"
    info+="File: $(basename "$theme_file")\n"
    info+="Size: $(du -h "$theme_file" | cut -f1)\n"
    info+="Modified: $(stat -c %y "$theme_file" | cut -d' ' -f1)\n\n"
    
    # Extract description from comments
    local description=$(grep -E "^[[:space:]]*/\*.*\*/" "$theme_file" | head -3)
    if [[ -n "$description" ]]; then
        info+="Description:\n$description\n\n"
    fi
    
    info+="Features:\n"
    info+="• Responsive design\n"
    info+="• Smooth animations\n"
    info+="• Hover effects\n"
    info+="• Modern UI/UX\n"
    
    rofi -e "$info" -theme-str 'window {width: 500px; height: 400px;}'
}

# Show main menu
show_main_menu() {
    local current_theme=$(get_current_theme)
    
    local options=(
        "1: Current Theme: $current_theme"
        "2: Available Themes"
        "3: Theme Information"
        "4: Copy Themes"
        "5: Restart Waybar"
        "6: Backup Current Theme"
        "7: Restore Backup"
    )
    
    local choice=$(printf '%s\n' "${options[@]}" | rofi -dmenu -p "Theme Switcher" -theme-str 'window {width: 350px;}')
    
    case "$choice" in
        *"Available Themes"*)
            show_theme_selection
            ;;
        *"Theme Information"*)
            show_theme_info_menu
            ;;
        *"Copy Themes"*)
            copy_themes
            ;;
        *"Restart Waybar"*)
            restart_waybar
            ;;
        *"Backup Current Theme"*)
            backup_current_theme
            ;;
        *"Restore Backup"*)
            restore_backup
            ;;
        *)
            exit 0
            ;;
    esac
}

# Show theme selection menu
show_theme_selection() {
    local current_theme=$(get_current_theme)
    
    local options=()
    for theme_info in "${THEMES[@]}"; do
        local theme_id=$(echo "$theme_info" | cut -d: -f1)
        local theme_name=$(echo "$theme_info" | cut -d: -f2)
        
        if [[ "$theme_id" == "$current_theme" ]]; then
            options+=("● $theme_name (Current)")
        else
            options+=("○ $theme_name")
        fi
    done
    
    local choice=$(printf '%s\n' "${options[@]}" | rofi -dmenu -p "Select Theme" -theme-str 'window {width: 400px;}')
    
    if [[ -n "$choice" && "$choice" != *"(Current)"* ]]; then
        local theme_name=$(echo "$choice" | sed 's/^[○●] //')
        
        # Find theme ID from name
        for theme_info in "${THEMES[@]}"; do
            local theme_id=$(echo "$theme_info" | cut -d: -f1)
            local theme_display_name=$(echo "$theme_info" | cut -d: -f2)
            
            if [[ "$theme_display_name" == "$theme_name" ]]; then
                # Show preview first
                preview_theme "$theme_id"
                
                # Ask for confirmation
                local confirm=$(echo -e "Yes\nNo" | rofi -dmenu -p "Apply theme: $theme_name?" -theme-str 'window {width: 300px;}')
                
                if [[ "$confirm" == "Yes" ]]; then
                    apply_theme "$theme_id"
                fi
                break
            fi
        done
    fi
}

# Show theme information menu
show_theme_info_menu() {
    local current_theme=$(get_current_theme)
    
    local options=()
    for theme_info in "${THEMES[@]}"; do
        local theme_id=$(echo "$theme_info" | cut -d: -f1)
        local theme_name=$(echo "$theme_info" | cut -d: -f2)
        options+=("$theme_name")
    done
    
    local choice=$(printf '%s\n' "${options[@]}" | rofi -dmenu -p "Theme Information" -theme-str 'window {width: 400px;}')
    
    if [[ -n "$choice" ]]; then
        # Find theme ID from name
        for theme_info in "${THEMES[@]}"; do
            local theme_id=$(echo "$theme_info" | cut -d: -f1)
            local theme_display_name=$(echo "$theme_info" | cut -d: -f2)
            
            if [[ "$theme_display_name" == "$choice" ]]; then
                show_theme_info "$theme_id"
                break
            fi
        done
    fi
}

# Backup current theme
backup_current_theme() {
    if [[ -f "$CURRENT_STYLE" ]]; then
        local backup_file="$CURRENT_STYLE.backup.$(date +%Y%m%d_%H%M%S)"
        cp "$CURRENT_STYLE" "$backup_file"
        notify-send "Theme Switcher" "Backup created: $(basename "$backup_file")"
    else
        notify-send "Theme Switcher" "No current theme to backup"
    fi
}

# Restore backup
restore_backup() {
    local backups=($(ls "$CURRENT_STYLE.backup."* 2>/dev/null))
    
    if [[ ${#backups[@]} -eq 0 ]]; then
        rofi -e "No backups found" -theme-str 'window {width: 300px;}'
        return
    fi
    
    local options=()
    for backup in "${backups[@]}"; do
        local backup_name=$(basename "$backup")
        local backup_date=$(echo "$backup_name" | sed 's/.*backup\.//')
        options+=("$backup_date")
    done
    
    local choice=$(printf '%s\n' "${options[@]}" | rofi -dmenu -p "Select Backup" -theme-str 'window {width: 400px;}')
    
    if [[ -n "$choice" ]]; then
        local backup_file="$CURRENT_STYLE.backup.$choice"
        if [[ -f "$backup_file" ]]; then
            cp "$backup_file" "$CURRENT_STYLE"
            restart_waybar
            notify-send "Theme Switcher" "Restored backup: $choice"
        fi
    fi
}

# Main execution
main() {
    # Ensure config directory exists
    mkdir -p "$CONFIG_DIR"
    
    # Create themes directory and copy themes
    create_themes_dir
    copy_themes
    
    # Show main menu
    show_main_menu
}

# Handle command line arguments
case "${1:-}" in
    "list")
        for theme_info in "${THEMES[@]}"; do
            echo "$theme_info"
        done
        ;;
    "current")
        get_current_theme
        ;;
    "apply")
        if [[ -n "$2" ]]; then
            apply_theme "$2"
        else
            echo "Usage: $0 apply <theme>"
        fi
        ;;
    "preview")
        if [[ -n "$2" ]]; then
            preview_theme "$2"
        else
            echo "Usage: $0 preview <theme>"
        fi
        ;;
    "restart")
        restart_waybar
        ;;
    *)
        main
        ;;
esac 