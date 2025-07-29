#!/usr/bin/env bash
# Sistema de post-instalación para hyprdream
# Maneja configuración automática, servicios systemd, variables de entorno y first-run wizard

source "$(dirname "$0")/colors.sh"
source "$(dirname "$0")/logger.sh"
source "$(dirname "$0")/progress.sh"

# Configuración
POST_INSTALL_DIR="${POST_INSTALL_DIR:-/etc/hyprdream}"
ENV_FILE="${ENV_FILE:-~/.config/hyprdream/env.conf}"
SHORTCUTS_DIR="${SHORTCUTS_DIR:-~/.local/share/applications}"
FIRST_RUN_FILE="${FIRST_RUN_FILE:-~/.config/hyprdream/first_run}"

# Variables globales
declare -A SYSTEMD_SERVICES=()
declare -A ENV_VARIABLES=()
declare -A DESKTOP_SHORTCUTS=()

# Función para configurar servicios systemd
setup_systemd_services() {
    log_info "Configurando servicios systemd..."
    
    # Servicios básicos de Hyprland
    local basic_services=(
        "bluetooth"
        "NetworkManager"
        "systemd-resolved"
        "systemd-timesyncd"
    )
    
    # Servicios opcionales basados en hardware
    local optional_services=(
        "power-profiles-daemon"
        "thermald"
        "upower"
    )
    
    # Servicios de audio
    local audio_services=(
        "pipewire"
        "pipewire-pulse"
        "wireplumber"
    )
    
    # Servicios de seguridad
    local security_services=(
        "fprintd"
        "polkit"
    )
    
    local all_services=("${basic_services[@]}" "${optional_services[@]}" "${audio_services[@]}" "${security_services[@]}")
    
    # Mostrar progress bar
    show_service_progress "${all_services[@]}"
    
    for i in "${!all_services[@]}"; do
        local service="${all_services[$i]}"
        local current=$((i + 1))
        
        log_info "Configurando servicio $current/${#all_services[@]}: $service"
        
        # Verificar si el servicio existe
        if systemctl list-unit-files | grep -q "$service.service"; then
            # Habilitar servicio
            if ! systemctl is-enabled "$service.service" &>/dev/null; then
                log_info "Habilitando $service"
                sudo systemctl enable "$service.service" 2>/dev/null || true
            fi
            
            # Iniciar servicio si no está corriendo
            if ! systemctl is-active --quiet "$service.service"; then
                log_info "Iniciando $service"
                sudo systemctl start "$service.service" 2>/dev/null || true
            fi
            
            SYSTEMD_SERVICES["$service"]="enabled"
        else
            log_warn "Servicio no encontrado: $service"
            SYSTEMD_SERVICES["$service"]="not_found"
        fi
    done
    
    log_info "Configuración de servicios systemd completada"
}

# Función para configurar variables de entorno
setup_environment_variables() {
    log_info "Configurando variables de entorno..."
    
    # Crear directorio de configuración
    mkdir -p "$(dirname "$ENV_FILE")"
    
    # Variables básicas de Hyprland
    ENV_VARIABLES["XDG_CURRENT_DESKTOP"]="Hyprland"
    ENV_VARIABLES["XDG_SESSION_TYPE"]="wayland"
    ENV_VARIABLES["XDG_SESSION_DESKTOP"]="hyprland"
    ENV_VARIABLES["QT_QPA_PLATFORM"]="wayland"
    ENV_VARIABLES["QT_WAYLAND_DISABLE_WINDOWDECORATION"]="1"
    ENV_VARIABLES["MOZ_ENABLE_WAYLAND"]="1"
    ENV_VARIABLES["_JAVA_AWT_WM_NONREPARENTING"]="1"
    ENV_VARIABLES["GTK_USE_PORTAL"]="1"
    ENV_VARIABLES["XDG_CONFIG_HOME"]="$HOME/.config"
    ENV_VARIABLES["XDG_CACHE_HOME"]="$HOME/.cache"
    ENV_VARIABLES["XDG_DATA_HOME"]="$HOME/.local/share"
    
    # Variables de rendimiento
    ENV_VARIABLES["LIBVA_DRIVER_NAME"]="nvidia"
    ENV_VARIABLES["NVD_BACKEND"]="direct"
    ENV_VARIABLES["__GLX_VENDOR_LIBRARY_NAME"]="nvidia"
    
    # Variables de tema
    ENV_VARIABLES["GTK_THEME"]="Adwaita-dark"
    ENV_VARIABLES["QT_STYLE_OVERRIDE"]="adwaita-dark"
    
    # Generar archivo de variables de entorno
    {
        echo "# Variables de entorno para hyprdream"
        echo "# Generado automáticamente el $(date)"
        echo ""
        
        for var in "${!ENV_VARIABLES[@]}"; do
            local value="${ENV_VARIABLES[$var]}"
            echo "export $var=\"$value\""
        done
        
    } > "$ENV_FILE"
    
    # Agregar a archivos de shell
    local shell_files=(
        "~/.bashrc"
        "~/.zshrc"
        "~/.profile"
    )
    
    for shell_file in "${shell_files[@]}"; do
        if [[ -f "$shell_file" ]]; then
            if ! grep -q "source.*env.conf" "$shell_file"; then
                echo "" >> "$shell_file"
                echo "# Variables de entorno hyprdream" >> "$shell_file"
                echo "[[ -f $ENV_FILE ]] && source $ENV_FILE" >> "$shell_file"
                log_info "Variables agregadas a $shell_file"
            fi
        fi
    done
    
    log_info "Variables de entorno configuradas en $ENV_FILE"
}

# Función para generar shortcuts de desktop
generate_desktop_shortcuts() {
    log_info "Generando shortcuts de desktop..."
    
    # Crear directorio de shortcuts
    mkdir -p "$SHORTCUTS_DIR"
    
    # Shortcuts básicos de Hyprland
    local shortcuts=(
        "hyprland-settings:Hyprland Settings:hyprland-settings:Settings"
        "waybar:Waybar:waybar:Panel"
        "dunst:Notifications:dunst:Notifications"
        "kitty:Terminal:kitty:Terminal"
        "rofi:App Launcher:rofi -show drun:Launcher"
        "swww:Wallpaper:swww:Wallpaper"
        "wlogout:Logout Menu:wlogout:Logout"
    )
    
    # Mostrar progress bar
    local shortcut_names=()
    for shortcut in "${shortcuts[@]}"; do
        shortcut_names+=("$(echo "$shortcut" | cut -d: -f2)")
    done
    show_config_progress "${shortcut_names[@]}"
    
    for i in "${!shortcuts[@]}"; do
        local shortcut_data="${shortcuts[$i]}"
        local name=$(echo "$shortcut_data" | cut -d: -f1)
        local display_name=$(echo "$shortcut_data" | cut -d: -f2)
        local command=$(echo "$shortcut_data" | cut -d: -f3)
        local category=$(echo "$shortcut_data" | cut -d: -f4)
        
        local desktop_file="$SHORTCUTS_DIR/hyprdream-$name.desktop"
        
        # Generar archivo .desktop
        {
            echo "[Desktop Entry]"
            echo "Version=1.0"
            echo "Type=Application"
            echo "Name=$display_name"
            echo "Comment=Hyprdream $display_name"
            echo "Exec=$command"
            echo "Icon=hyprland"
            echo "Terminal=false"
            echo "Categories=System;$category;"
            echo "Keywords=hyprland;wayland;desktop;"
        } > "$desktop_file"
        
        # Hacer ejecutable
        chmod +x "$desktop_file"
        
        DESKTOP_SHORTCUTS["$name"]="$desktop_file"
        log_info "Shortcut creado: $desktop_file"
    done
    
    # Actualizar base de datos de aplicaciones
    if command -v update-desktop-database &>/dev/null; then
        update-desktop-database "$SHORTCUTS_DIR"
        log_info "Base de datos de aplicaciones actualizada"
    fi
    
    log_info "Shortcuts de desktop generados"
}

# Función para configurar permisos y seguridad
setup_permissions_and_security() {
    log_info "Configurando permisos y seguridad..."
    
    # Configurar permisos de usuario
    local user_permissions=(
        "~/.config:755"
        "~/.local:755"
        "~/.cache:755"
        "~/.config/hyprland:755"
        "~/.config/waybar:755"
        "~/.config/dunst:755"
        "~/.config/kitty:755"
        "~/.config/rofi:755"
    )
    
    for permission in "${user_permissions[@]}"; do
        local path=$(echo "$permission" | cut -d: -f1)
        local mode=$(echo "$permission" | cut -d: -f2)
        
        if [[ -e "$path" ]]; then
            chmod "$mode" "$path"
            log_debug "Permisos configurados: $path -> $mode"
        fi
    done
    
    # Configurar sudoers para comandos específicos
    local sudo_commands=(
        "systemctl"
        "pacman"
        "paru"
        "yay"
    )
    
    local sudoers_file="/etc/sudoers.d/hyprdream"
    {
        echo "# Permisos sudo para hyprdream"
        echo "# Generado automáticamente el $(date)"
        echo ""
        echo "$(whoami) ALL=(ALL) NOPASSWD: /usr/bin/systemctl"
        echo "$(whoami) ALL=(ALL) NOPASSWD: /usr/bin/pacman"
        if command -v paru &>/dev/null; then
            echo "$(whoami) ALL=(ALL) NOPASSWD: /usr/bin/paru"
        fi
        if command -v yay &>/dev/null; then
            echo "$(whoami) ALL=(ALL) NOPASSWD: /usr/bin/yay"
        fi
    } | sudo tee "$sudoers_file" > /dev/null
    
    chmod 440 "$sudoers_file"
    log_info "Permisos sudo configurados en $sudoers_file"
    
    # Configurar polkit para acciones específicas
    setup_polkit_rules
    
    log_info "Configuración de permisos y seguridad completada"
}

# Función para configurar reglas de polkit
setup_polkit_rules() {
    log_info "Configurando reglas de polkit..."
    
    local polkit_dir="/etc/polkit-1/rules.d"
    local polkit_file="$polkit_dir/10-hyprdream.rules"
    
    # Crear reglas de polkit
    {
        echo "// Reglas de polkit para hyprdream"
        echo "// Generado automáticamente el $(date)"
        echo ""
        echo "polkit.addRule(function(action, subject) {"
        echo "    if (action.id == \"org.freedesktop.systemd1.manage-units\" &&"
        echo "        subject.local && subject.active && subject.isInGroup(\"wheel\")) {"
        echo "        return polkit.Result.YES;"
        echo "    }"
        echo "    if (action.id == \"org.freedesktop.packagekit.package-install\" &&"
        echo "        subject.local && subject.active && subject.isInGroup(\"wheel\")) {"
        echo "        return polkit.Result.YES;"
        echo "    }"
        echo "    if (action.id == \"org.freedesktop.packagekit.package-remove\" &&"
        echo "        subject.local && subject.active && subject.isInGroup(\"wheel\")) {"
        echo "        return polkit.Result.YES;"
        echo "    }"
        echo "});"
    } | sudo tee "$polkit_file" > /dev/null
    
    log_info "Reglas de polkit configuradas en $polkit_file"
}

# Función para first-run wizard
run_first_run_wizard() {
    if [[ -f "$FIRST_RUN_FILE" ]]; then
        log_info "First-run wizard ya ejecutado anteriormente"
        return 0
    fi
    
    log_info "Ejecutando first-run wizard..."
    
    echo -e "\n${CYAN}=== Bienvenido a hyprdream ===${RESET}"
    echo "Este es el asistente de configuración inicial."
    echo "Te ayudará a configurar tu entorno Hyprland."
    echo ""
    
    # Preguntas de configuración
    local user_preferences=()
    
    # Tema preferido
    echo -e "${BLUE}Temas disponibles:${RESET}"
    echo "1) Catppuccin (oscuro, moderno)"
    echo "2) Dracula (oscuro, elegante)"
    echo "3) Nord (claro, minimalista)"
    echo "4) Tokyo Night (oscuro, japonés)"
    echo "5) Personalizado"
    
    read -p "Selecciona un tema (1-5): " theme_choice
    case "$theme_choice" in
        1) user_preferences["theme"]="catppuccin" ;;
        2) user_preferences["theme"]="dracula" ;;
        3) user_preferences["theme"]="nord" ;;
        4) user_preferences["theme"]="tokyo-night" ;;
        5) user_preferences["theme"]="custom" ;;
        *) user_preferences["theme"]="catppuccin" ;;
    esac
    
    # Terminal preferida
    echo -e "\n${BLUE}Terminales disponibles:${RESET}"
    echo "1) kitty (recomendado)"
    echo "2) alacritty"
    echo "3) foot"
    echo "4) gnome-terminal"
    
    read -p "Selecciona una terminal (1-4): " terminal_choice
    case "$terminal_choice" in
        1) user_preferences["terminal"]="kitty" ;;
        2) user_preferences["terminal"]="alacritty" ;;
        3) user_preferences["terminal"]="foot" ;;
        4) user_preferences["terminal"]="gnome-terminal" ;;
        *) user_preferences["terminal"]="kitty" ;;
    esac
    
    # Notificaciones
    echo -e "\n${BLUE}Sistema de notificaciones:${RESET}"
    echo "1) dunst (recomendado)"
    echo "2) mako"
    echo "3) swaync"
    
    read -p "Selecciona sistema de notificaciones (1-3): " notification_choice
    case "$notification_choice" in
        1) user_preferences["notifications"]="dunst" ;;
        2) user_preferences["notifications"]="mako" ;;
        3) user_preferences["notifications"]="swaync" ;;
        *) user_preferences["notifications"]="dunst" ;;
    esac
    
    # Configuraciones adicionales
    echo -e "\n${BLUE}Configuraciones adicionales:${RESET}"
    read -p "¿Habilitar auto-login? (y/N): " autologin_choice
    if [[ "$autologin_choice" =~ ^[Yy]$ ]]; then
        user_preferences["autologin"]="true"
    else
        user_preferences["autologin"]="false"
    fi
    
    read -p "¿Habilitar efectos de transparencia? (Y/n): " transparency_choice
    if [[ "$transparency_choice" =~ ^[Nn]$ ]]; then
        user_preferences["transparency"]="false"
    else
        user_preferences["transparency"]="true"
    fi
    
    # Aplicar configuraciones
    apply_user_preferences "${user_preferences[@]}"
    
    # Marcar como completado
    mkdir -p "$(dirname "$FIRST_RUN_FILE")"
    echo "$(date)" > "$FIRST_RUN_FILE"
    
    echo -e "\n${GREEN}✓ Configuración inicial completada${RESET}"
    echo "Tu entorno hyprdream está listo para usar."
    echo ""
    echo "Para reiniciar y aplicar todos los cambios:"
    echo "  systemctl reboot"
    echo ""
    echo "Para iniciar Hyprland manualmente:"
    echo "  hyprland"
}

# Función para aplicar preferencias del usuario
apply_user_preferences() {
    local -A preferences=("$@")
    
    log_info "Aplicando preferencias del usuario..."
    
    # Aplicar tema
    if [[ -n "${preferences[theme]}" ]]; then
        log_info "Aplicando tema: ${preferences[theme]}"
        # Aquí se aplicaría el tema seleccionado
    fi
    
    # Aplicar terminal
    if [[ -n "${preferences[terminal]}" ]]; then
        log_info "Configurando terminal: ${preferences[terminal]}"
        # Aquí se configuraría la terminal seleccionada
    fi
    
    # Aplicar notificaciones
    if [[ -n "${preferences[notifications]}" ]]; then
        log_info "Configurando notificaciones: ${preferences[notifications]}"
        # Aquí se configuraría el sistema de notificaciones
    fi
    
    # Configurar auto-login
    if [[ "${preferences[autologin]}" == "true" ]]; then
        log_info "Configurando auto-login..."
        setup_autologin
    fi
    
    # Configurar transparencia
    if [[ "${preferences[transparency]}" == "true" ]]; then
        log_info "Habilitando efectos de transparencia..."
        # Aquí se habilitarían los efectos de transparencia
    fi
    
    log_info "Preferencias del usuario aplicadas"
}

# Función para configurar auto-login
setup_autologin() {
    log_info "Configurando auto-login..."
    
    # Configurar auto-login para display manager
    if [[ -f /etc/gdm/custom.conf ]]; then
        # GDM
        sudo sed -i 's/#AutomaticLoginEnable=true/AutomaticLoginEnable=true/' /etc/gdm/custom.conf
        sudo sed -i "s/#AutomaticLogin=user/AutomaticLogin=$(whoami)/" /etc/gdm/custom.conf
        log_info "Auto-login configurado para GDM"
    elif [[ -f /etc/lightdm/lightdm.conf ]]; then
        # LightDM
        sudo sed -i "s/#autologin-user=/autologin-user=$(whoami)/" /etc/lightdm/lightdm.conf
        log_info "Auto-login configurado para LightDM"
    fi
}

# Función para generar reporte de post-instalación
generate_post_install_report() {
    local report_file="${1:-/tmp/hyprdream_post_install_report.txt}"
    
    log_info "Generando reporte de post-instalación..."
    
    {
        echo "=== Reporte de Post-Instalación hyprdream ==="
        echo "Fecha: $(date)"
        echo "Usuario: $(whoami)"
        echo ""
        
        echo "--- Servicios Systemd ---"
        for service in "${!SYSTEMD_SERVICES[@]}"; do
            local status="${SYSTEMD_SERVICES[$service]}"
            echo "$service: $status"
        done
        echo ""
        
        echo "--- Variables de Entorno ---"
        echo "Archivo: $ENV_FILE"
        for var in "${!ENV_VARIABLES[@]}"; do
            local value="${ENV_VARIABLES[$var]}"
            echo "$var=$value"
        done
        echo ""
        
        echo "--- Shortcuts de Desktop ---"
        for shortcut in "${!DESKTOP_SHORTCUTS[@]}"; do
            local file="${DESKTOP_SHORTCUTS[$shortcut]}"
            echo "$shortcut: $file"
        done
        echo ""
        
        echo "--- Estado de First-Run ---"
        if [[ -f "$FIRST_RUN_FILE" ]]; then
            echo "Completado: $(cat "$FIRST_RUN_FILE")"
        else
            echo "Pendiente"
        fi
        
    } > "$report_file"
    
    log_info "Reporte generado: $report_file"
}

# Función principal de post-instalación
run_post_installation() {
    log_info "Iniciando post-instalación..."
    
    # Configurar servicios systemd
    setup_systemd_services
    
    # Configurar variables de entorno
    setup_environment_variables
    
    # Generar shortcuts de desktop
    generate_desktop_shortcuts
    
    # Configurar permisos y seguridad
    setup_permissions_and_security
    
    # Ejecutar first-run wizard si es necesario
    run_first_run_wizard
    
    # Generar reporte
    generate_post_install_report
    
    log_info "Post-instalación completada"
}

# Ejecutar si se llama directamente
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    init_logger
    
    case "${1:-run}" in
        "run")
            run_post_installation
            ;;
        "services")
            setup_systemd_services
            ;;
        "env")
            setup_environment_variables
            ;;
        "shortcuts")
            generate_desktop_shortcuts
            ;;
        "security")
            setup_permissions_and_security
            ;;
        "wizard")
            run_first_run_wizard
            ;;
        "report")
            generate_post_install_report "${2:-}"
            ;;
        "test")
            # Test del sistema de post-instalación
            echo -e "${CYAN}=== Test del Sistema de Post-Instalación ===${RESET}"
            
            setup_systemd_services
            setup_environment_variables
            generate_desktop_shortcuts
            setup_permissions_and_security
            generate_post_install_report
            ;;
        *)
            echo "Uso: $0 [run|services|env|shortcuts|security|wizard|report|test]"
            echo ""
            echo "Comandos:"
            echo "  run       - Ejecutar post-instalación completa"
            echo "  services  - Configurar servicios systemd"
            echo "  env       - Configurar variables de entorno"
            echo "  shortcuts - Generar shortcuts de desktop"
            echo "  security  - Configurar permisos y seguridad"
            echo "  wizard    - Ejecutar first-run wizard"
            echo "  report    - Generar reporte de post-instalación"
            echo "  test      - Probar sistema de post-instalación"
            ;;
    esac
fi 