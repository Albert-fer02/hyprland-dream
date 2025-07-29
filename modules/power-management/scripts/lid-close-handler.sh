#!/usr/bin/env bash
# Lid Close Handler for Hyprland Dream
# Monitors lid state and handles suspend/lock actions

set -euo pipefail

# =============================================================================
# CONFIGURATION
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$HOME/.config"
LOG_FILE="$HOME/.local/share/hyprland-dream/lid-handler.log"

# Commands
LOCK_CMD="swaylock -c $CONFIG_DIR/swaylock/config"
SUSPEND_CMD="systemctl suspend"

# Lid state file
LID_STATE_FILE="/proc/acpi/button/lid/LID0/state"

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

# Logging function
log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" | tee -a "$LOG_FILE"
}

# Check if running on laptop
is_laptop() {
    [[ -f /sys/class/power_supply/BAT* ]] && return 0 || return 1
}

# Check if lid is closed
is_lid_closed() {
    if [[ -f "$LID_STATE_FILE" ]]; then
        [[ "$(cat "$LID_STATE_FILE")" == "closed" ]]
    else
        return 1
    fi
}

# Check if AC is connected
is_ac_connected() {
    [[ "$(cat /sys/class/power_supply/AC/online 2>/dev/null)" == "1" ]]
}

# Get battery percentage
get_battery_percentage() {
    cat /sys/class/power_supply/BAT*/capacity 2>/dev/null | head -1 || echo "100"
}

# =============================================================================
# LID HANDLING FUNCTIONS
# =============================================================================

# Handle lid close event
handle_lid_close() {
    log "INFO" "Lid closed detected"
    
    # Lock screen immediately
    log "INFO" "Locking screen"
    notify-send -u normal -i "lock" "Pantalla bloqueada" "Tapa cerrada - Pantalla bloqueada"
    $LOCK_CMD &
    
    # Wait a moment for lock to take effect
    sleep 1
    
    # Check if we should suspend
    if should_suspend_on_lid_close; then
        log "INFO" "Suspending system due to lid close"
        notify-send -u normal -i "suspend" "Suspensión" "Sistema suspendido por cierre de tapa"
        
        # Pre-suspend actions
        pre_suspend_actions
        
        # Suspend
        $SUSPEND_CMD
    else
        log "INFO" "Lid closed but not suspending (AC connected or battery high)"
    fi
}

# Handle lid open event
handle_lid_open() {
    log "INFO" "Lid opened detected"
    
    # Post-resume actions
    post_resume_actions
    
    notify-send -u normal -i "resume" "Reanudado" "Sistema reanudado"
}

# Determine if we should suspend on lid close
should_suspend_on_lid_close() {
    # Always suspend if not on AC
    if ! is_ac_connected; then
        return 0
    fi
    
    # If on AC, check battery level
    local battery_level=$(get_battery_percentage)
    
    # Suspend if battery is low even on AC
    if [[ $battery_level -le 20 ]]; then
        return 0
    fi
    
    # Don't suspend if on AC and battery is good
    return 1
}

# Pre-suspend actions
pre_suspend_actions() {
    log "INFO" "Running pre-suspend actions"
    
    # Pause media players
    playerctl pause 2>/dev/null || true
    
    # Save any pending work
    # Add your custom pre-suspend actions here
    
    # Wait a moment for actions to complete
    sleep 0.5
}

# Post-resume actions
post_resume_actions() {
    log "INFO" "Running post-resume actions"
    
    # Restore audio settings
    pactl set-sink-volume @DEFAULT_SINK@ 50% 2>/dev/null || true
    
    # Reconnect to WiFi if needed
    # nmcli device connect wlan0 2>/dev/null || true
    
    # Add your custom post-resume actions here
}

# =============================================================================
# VALIDATION
# =============================================================================

# Check dependencies
check_dependencies() {
    local deps=("swaylock" "systemctl" "notify-send")
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" >/dev/null 2>&1; then
            log "ERROR" "Missing dependency: $dep"
            exit 1
        fi
    done
}

# Create log directory
setup_logging() {
    mkdir -p "$(dirname "$LOG_FILE")"
    touch "$LOG_FILE"
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================

main() {
    log "INFO" "Starting lid close handler"
    
    # Setup
    check_dependencies
    setup_logging
    
    # Exit if not on laptop
    if ! is_laptop; then
        log "INFO" "Not running on laptop, exiting"
        exit 0
    fi
    
    # Check if lid state file exists
    if [[ ! -f "$LID_STATE_FILE" ]]; then
        log "WARN" "Lid state file not found: $LID_STATE_FILE"
        log "INFO" "Lid close handler not needed, exiting"
        exit 0
    fi
    
    log "INFO" "Monitoring lid state"
    
    # Main monitoring loop
    local last_state=""
    
    while true; do
        local current_state=""
        
        if is_lid_closed; then
            current_state="closed"
        else
            current_state="open"
        fi
        
        # Handle state change
        if [[ "$current_state" != "$last_state" ]]; then
            if [[ "$current_state" == "closed" ]]; then
                handle_lid_close
            elif [[ "$current_state" == "open" ]]; then
                handle_lid_open
            fi
            last_state="$current_state"
        fi
        
        # Sleep to avoid excessive CPU usage
        sleep 1
    done
}

# Cleanup function
cleanup() {
    log "INFO" "Stopping lid close handler"
}

# =============================================================================
# SCRIPT EXECUTION
# =============================================================================

# Set up cleanup trap
trap cleanup EXIT

# Only run if called directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi 