#!/usr/bin/env bash
# Enhanced Power Management Installer for Hyprland Dream
# Comprehensive security and power management system
set -e

SCRIPT_DIR="$(dirname "$0")"
ROOT_DIR="$SCRIPT_DIR/../.."
source "$ROOT_DIR/lib/utils.sh"

require_arch

# Install and configure enhanced power management
install_power_management() {
    print_info "Installing enhanced power management system..."
    
    # Install required packages
    install_package "swayidle"
    install_package "swaylock"
    install_package "playerctl"
    install_package "pamixer"
    
    # Copy scripts
    copy_scripts "$SCRIPT_DIR/scripts"
    
    # Make scripts executable
    chmod +x "$SCRIPT_DIR/scripts/power-management.sh"
    chmod +x "$SCRIPT_DIR/scripts/lid-close-handler.sh"
    
    # Copy and enable systemd services
    local user_systemd_dir="$HOME/.config/systemd/user"
    mkdir -p "$user_systemd_dir"
    
    # Power management service
    local service_src="$SCRIPT_DIR/systemd/power-management.service"
    local service_dest="$user_systemd_dir/power-management.service"
    cp -u "$service_src" "$service_dest"
    
    # Lid close handler service
    local lid_service_src="$SCRIPT_DIR/systemd/lid-close-handler.service"
    local lid_service_dest="$user_systemd_dir/lid-close-handler.service"
    cp -u "$lid_service_src" "$lid_service_dest"
    
    # Auto-pause headphones service (existing)
    local headphones_service_src="$SCRIPT_DIR/systemd/auto-pause-headphones.service"
    local headphones_service_dest="$user_systemd_dir/auto-pause-headphones.service"
    cp -u "$headphones_service_src" "$headphones_service_dest"
    
    # Configure systemd logind (requires sudo)
    configure_logind
    
    # Reload and enable services
    systemctl --user daemon-reload
    systemctl --user enable power-management.service
    systemctl --user enable lid-close-handler.service
    systemctl --user enable auto-pause-headphones.service
    
    # Start services
    systemctl --user start power-management.service
    systemctl --user start lid-close-handler.service
    systemctl --user start auto-pause-headphones.service
    
    # Create log directories
    mkdir -p "$HOME/.local/share/hyprland-dream"
    
    print_ok "Enhanced power management system installed and configured."
    print_info "Services enabled: power-management, lid-close-handler, auto-pause-headphones"
}

# Configure systemd logind
configure_logind() {
    print_info "Configuring systemd logind for enhanced power management..."
    
    local logind_conf="/etc/systemd/logind.conf"
    local backup_conf="/etc/systemd/logind.conf.backup"
    
    # Create backup
    if [[ -f "$logind_conf" ]]; then
        sudo cp "$logind_conf" "$backup_conf"
        print_info "Backup created: $backup_conf"
    fi
    
    # Copy our enhanced configuration
    local our_logind_conf="$SCRIPT_DIR/systemd/logind.conf"
    sudo cp "$our_logind_conf" "$logind_conf"
    
    # Restart systemd-logind
    sudo systemctl restart systemd-logind
    
    print_ok "Systemd logind configured for enhanced power management."
}

# Copy only configuration
copy_only_config() {
    print_info "Copying power management configuration only..."
    
    # Copy scripts
    copy_scripts "$SCRIPT_DIR/scripts"
    
    # Make scripts executable
    chmod +x "$SCRIPT_DIR/scripts/power-management.sh"
    chmod +x "$SCRIPT_DIR/scripts/lid-close-handler.sh"
    
    # Copy systemd services
    local user_systemd_dir="$HOME/.config/systemd/user"
    mkdir -p "$user_systemd_dir"
    
    local service_src="$SCRIPT_DIR/systemd/power-management.service"
    local service_dest="$user_systemd_dir/power-management.service"
    cp -u "$service_src" "$service_dest"
    
    local lid_service_src="$SCRIPT_DIR/systemd/lid-close-handler.service"
    local lid_service_dest="$user_systemd_dir/lid-close-handler.service"
    cp -u "$lid_service_src" "$lid_service_dest"
    
    local headphones_service_src="$SCRIPT_DIR/systemd/auto-pause-headphones.service"
    local headphones_service_dest="$user_systemd_dir/auto-pause-headphones.service"
    cp -u "$headphones_service_src" "$headphones_service_dest"
    
    # Reload and enable services
    systemctl --user daemon-reload
    systemctl --user enable power-management.service
    systemctl --user enable lid-close-handler.service
    systemctl --user enable auto-pause-headphones.service
    
    # Create log directories
    mkdir -p "$HOME/.local/share/hyprland-dream"
    
    print_ok "Power management configuration copied."
}

# Show status of services
show_status() {
    print_info "Power Management Services Status:"
    echo
    
    local services=("power-management" "lid-close-handler" "auto-pause-headphones")
    
    for service in "${services[@]}"; do
        if systemctl --user is-active --quiet "$service.service"; then
            print_ok "$service.service: ACTIVE"
        else
            print_warn "$service.service: INACTIVE"
        fi
        
        if systemctl --user is-enabled --quiet "$service.service"; then
            print_ok "$service.service: ENABLED"
        else
            print_warn "$service.service: DISABLED"
        fi
        echo
    done
}

# Interactive menu
show_menu() {
    echo -e "\n$CYAN=== Enhanced Power Management Module (Hyprland Dream) ===$RESET"
    echo " 1) Install Enhanced Power Management (packages + config)"
    echo " 2) Copy configuration only"
    echo " 3) Show service status"
    echo " 4) Configure systemd logind only"
    echo " 0) Exit"
    echo -n "Option: "
    read -r opt
    case $opt in
        1) install_power_management;;
        2) copy_only_config;;
        3) show_status;;
        4) configure_logind;;
        0) print_info "Exiting..."; exit 0;;
        *) print_warn "Invalid option.";;
    esac
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    show_menu
fi
