#!/usr/bin/env bash
# Enhanced Power Management Script for Hyprland
# Intelligent energy management with security features

set -euo pipefail

# =============================================================================
# CONFIGURATION
# =============================================================================

# Paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$HOME/.config"
LOG_FILE="$HOME/.local/share/hyprland-dream/power-management.log"

# Commands
LOCK_CMD="swaylock -c $CONFIG_DIR/swaylock/config"
LOGOUT_CMD="loginctl terminate-session $XDG_SESSION_ID"

# Timeouts (in seconds)
INACTIVITY_LOCK=300      # 5 minutes - Lock screen
INACTIVITY_SUSPEND=900   # 15 minutes - Suspend
INACTIVITY_LOGOUT=3600   # 1 hour - Force logout
SESSION_TIMEOUT=7200     # 2 hours - Session timeout

# Battery thresholds (percentage)
BATTERY_LOW=20
BATTERY_CRITICAL=10

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

# Get battery percentage
get_battery_percentage() {
    if is_laptop; then
        cat /sys/class/power_supply/BAT*/capacity 2>/dev/null | head -1 || echo "100"
    else
        echo "100"
    fi
}

# Check if AC is connected
is_ac_connected() {
    if is_laptop; then
        [[ "$(cat /sys/class/power_supply/AC/online 2>/dev/null)" == "1" ]]
    else
        return 0
    fi
}

# Check if lid is closed (laptops only)
is_lid_closed() {
    if is_laptop; then
        [[ "$(cat /proc/acpi/button/lid/LID0/state 2>/dev/null)" == "closed" ]]
    else
        return 1
    fi
}

# =============================================================================
# SECURITY FUNCTIONS
# =============================================================================

# Lock screen with notification
lock_screen() {
    log "INFO" "Locking screen due to inactivity"
    notify-send -u normal -i "lock" "Pantalla bloqueada" "Por seguridad, la pantalla se ha bloqueado"
    $LOCK_CMD &
}

# Force logout with warning
force_logout() {
    log "WARN" "Force logout due to extended inactivity"
    notify-send -u critical -i "logout" "Sesión cerrada" "Sesión cerrada por inactividad prolongada"
    sleep 2
    $LOGOUT_CMD
}

# Session timeout handler
handle_session_timeout() {
    log "WARN" "Session timeout reached"
    notify-send -u critical -i "timeout" "Tiempo de sesión agotado" "La sesión se cerrará en 30 segundos"
    sleep 30
    $LOGOUT_CMD
}

# =============================================================================
# POWER MANAGEMENT FUNCTIONS
# =============================================================================

# Suspend system with pre/post hooks
suspend_system() {
    log "INFO" "Suspending system"
    
    # Pre-suspend actions
    pre_suspend_hooks
    
    # Suspend
    systemctl suspend
    
    # Post-suspend actions (will run after resume)
    post_suspend_hooks
}

# Pre-suspend hooks
pre_suspend_hooks() {
    log "INFO" "Running pre-suspend hooks"
    
    # Pause media players
    playerctl pause 2>/dev/null || true
    
    # Disconnect Bluetooth devices (optional)
    # bluetoothctl disconnect 2>/dev/null || true
    
    # Save any pending work
    # Add your custom pre-suspend actions here
    
    notify-send -u normal -i "suspend" "Suspensión" "Sistema suspendido"
}

# Post-suspend hooks
post_suspend_hooks() {
    log "INFO" "Running post-suspend hooks"
    
    # Reconnect to WiFi if needed
    # nmcli device connect wlan0 2>/dev/null || true
    
    # Restore audio settings
    # pactl set-sink-volume @DEFAULT_SINK@ 50% 2>/dev/null || true
    
    # Add your custom post-suspend actions here
    
    notify-send -u normal -i "resume" "Reanudado" "Sistema reanudado"
}

# Battery monitoring
monitor_battery() {
    if ! is_laptop; then
        return
    fi
    
    local battery_level=$(get_battery_percentage)
    
    if [[ $battery_level -le $BATTERY_CRITICAL ]]; then
        log "CRITICAL" "Battery critical: ${battery_level}%"
        notify-send -u critical -i "battery-critical" "Batería crítica" "Nivel de batería: ${battery_level}%"
        
        # Suspend if not on AC
        if ! is_ac_connected; then
            sleep 30
            suspend_system
        fi
    elif [[ $battery_level -le $BATTERY_LOW ]]; then
        log "WARN" "Battery low: ${battery_level}%"
        notify-send -u normal -i "battery-low" "Batería baja" "Nivel de batería: ${battery_level}%"
    fi
}

# =============================================================================
# LID CLOSE HANDLING
# =============================================================================

# Handle lid close events
handle_lid_close() {
    if is_laptop && is_lid_closed; then
        log "INFO" "Lid closed, suspending system"
        lock_screen
        sleep 1
        suspend_system
    fi
}

# =============================================================================
# VALIDATION
# =============================================================================

# Check dependencies
check_dependencies() {
    local deps=("swayidle" "swaylock" "systemctl" "notify-send")
    
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
    log "INFO" "Starting enhanced power management"
    
    # Setup
    check_dependencies
    setup_logging
    
    # Kill any existing swayidle processes
    pkill -f "swayidle" 2>/dev/null || true
    
    # Start battery monitoring in background
    if is_laptop; then
        (
            while true; do
                monitor_battery
                sleep 60  # Check every minute
            done
        ) &
        BATTERY_PID=$!
    fi
    
    # Start lid monitoring in background
    if is_laptop; then
        (
            while true; do
                handle_lid_close
                sleep 2
            done
        ) &
        LID_PID=$!
    fi
    
    # Start swayidle with enhanced configuration
    log "INFO" "Starting swayidle with enhanced timeouts"
    
    swayidle -w \
        timeout "$INACTIVITY_LOCK" "lock_screen" \
        timeout "$INACTIVITY_SUSPEND" "lock_screen && suspend_system" \
        timeout "$INACTIVITY_LOGOUT" "force_logout" \
        timeout "$SESSION_TIMEOUT" "handle_session_timeout" \
        before-sleep "lock_screen" \
        after-resume "post_suspend_hooks" \
        lock "lock_screen" \
        unlock "log 'INFO' 'Screen unlocked'"
    
    # Cleanup on exit
    trap 'cleanup' EXIT
    wait
}

# Cleanup function
cleanup() {
    log "INFO" "Stopping power management"
    
    # Kill background processes
    [[ -n "${BATTERY_PID:-}" ]] && kill "$BATTERY_PID" 2>/dev/null || true
    [[ -n "${LID_PID:-}" ]] && kill "$LID_PID" 2>/dev/null || true
    
    # Kill swayidle
    pkill -f "swayidle" 2>/dev/null || true
    
    log "INFO" "Power management stopped"
}

# =============================================================================
# SCRIPT EXECUTION
# =============================================================================

# Only run if called directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
