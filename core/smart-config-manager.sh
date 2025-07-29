#!/usr/bin/env bash
# Gestor de configuración inteligente para hyprland-dream
# Detecta hardware y genera configuraciones optimizadas automáticamente

source "$(dirname "$0")/colors.sh"
source "$(dirname "$0")/logger.sh"
source "$(dirname "$0")/hardware-detector.sh"

# Configuración
CONFIG_TEMPLATES_DIR="${CONFIG_TEMPLATES_DIR:-$(dirname "$0")/../config/templates}"
GENERATED_CONFIG_DIR="${GENERATED_CONFIG_DIR:-$HOME/.config/hyprdream-generated}"
CONFIG_BACKUP_DIR="${CONFIG_BACKUP_DIR:-$HOME/.config/hyprdream-backup}"

# Variables globales
declare -A HARDWARE_CONFIG=()
declare -A OPTIMIZATION_RULES=()
declare -A CONFIG_VARIABLES=()

# Función para inicializar el gestor de configuración inteligente
init_smart_config_manager() {
    log_info "Inicializando gestor de configuración inteligente..."
    
    # Crear directorios necesarios
    mkdir -p "$GENERATED_CONFIG_DIR" "$CONFIG_BACKUP_DIR"
    
    # Detectar hardware
    detect_hardware
    
    # Cargar reglas de optimización
    load_optimization_rules
    
    # Generar variables de configuración
    generate_config_variables
    
    log_info "Gestor de configuración inteligente inicializado"
}

# Función para cargar reglas de optimización
load_optimization_rules() {
    log_info "Cargando reglas de optimización..."
    
    # Reglas para diferentes tipos de hardware
    OPTIMIZATION_RULES["laptop"]="power_saving,thermal_management,backlight_control"
    OPTIMIZATION_RULES["desktop"]="performance,multimonitor,high_refresh"
    OPTIMIZATION_RULES["nvidia"]="nvidia_optimizations,prime_support"
    OPTIMIZATION_RULES["amd"]="amd_optimizations,opencl_support"
    OPTIMIZATION_RULES["intel"]="intel_optimizations,quick_sync"
    OPTIMIZATION_RULES["low_memory"]="memory_optimization,swap_management"
    OPTIMIZATION_RULES["high_memory"]="memory_intensive_apps,cache_optimization"
}

# Función para generar variables de configuración
generate_config_variables() {
    log_info "Generando variables de configuración..."
    
    # Variables básicas del sistema
    CONFIG_VARIABLES["USER"]="$USER"
    CONFIG_VARIABLES["HOME"]="$HOME"
    CONFIG_VARIABLES["HOSTNAME"]=$(hostname)
    
    # Variables de hardware
    CONFIG_VARIABLES["CPU_CORES"]="${HARDWARE_INFO[cpu_cores]}"
    CONFIG_VARIABLES["IS_LAPTOP"]="${HARDWARE_INFO[is_laptop]}"
    CONFIG_VARIABLES["GPU_NVIDIA"]="${GPU_INFO[nvidia]:-false}"
    CONFIG_VARIABLES["GPU_AMD"]="${GPU_INFO[amd]:-false}"
    CONFIG_VARIABLES["GPU_INTEL"]="${GPU_INFO[intel]:-false}"
    
    # Variables de memoria
    local total_mem=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    CONFIG_VARIABLES["TOTAL_MEMORY_MB"]=$((total_mem / 1024))
    
    # Variables de monitores
    CONFIG_VARIABLES["MONITOR_COUNT"]=$(xrandr --listmonitors 2>/dev/null | grep -c "Monitor" || echo "1")
    
    # Variables de audio
    CONFIG_VARIABLES["AUDIO_CARD"]="${AUDIO_INFO[card]:-default}"
    CONFIG_VARIABLES["BLUETOOTH_AVAILABLE"]="${AUDIO_INFO[bluetooth]:-false}"
    
    log_info "Variables de configuración generadas"
}

# Función para generar configuración de Hyprland optimizada
generate_hyprland_config() {
    log_info "Generando configuración de Hyprland optimizada..."
    
    local config_file="$GENERATED_CONFIG_DIR/hyprland.conf"
    local template_file="$CONFIG_TEMPLATES_DIR/hyprland.conf"
    
    # Crear backup de configuración existente
    if [[ -f "$HOME/.config/hypr/hyprland.conf" ]]; then
        cp "$HOME/.config/hypr/hyprland.conf" "$CONFIG_BACKUP_DIR/hyprland.conf.backup"
        log_info "Backup creado: $CONFIG_BACKUP_DIR/hyprland.conf.backup"
    fi
    
    # Generar configuración basada en hardware
    {
        echo "# Configuración de Hyprland generada automáticamente"
        echo "# Hardware detectado:"
        echo "# - CPU: ${HARDWARE_INFO[cpu_model]} (${HARDWARE_INFO[cpu_cores]} cores)"
        echo "# - GPU: $(get_detected_gpu_info)"
        echo "# - Memoria: ${CONFIG_VARIABLES[TOTAL_MEMORY_MB]}MB"
        echo "# - Tipo: $([ "${HARDWARE_INFO[is_laptop]}" == "true" ] && echo "Laptop" || echo "Desktop")"
        echo ""
        
        # Configuración básica
        generate_basic_hyprland_config
        
        # Configuración específica de hardware
        generate_hardware_specific_config
        
        # Configuración de monitores
        generate_monitor_config
        
        # Configuración de entrada
        generate_input_config
        
        # Configuración de ventanas
        generate_window_config
        
        # Configuración de animaciones
        generate_animation_config
        
        # Configuración de autostart
        generate_autostart_config
        
    } > "$config_file"
    
    # Aplicar configuración
    apply_hyprland_config "$config_file"
    
    log_info "Configuración de Hyprland generada: $config_file"
}

# Función para generar configuración básica de Hyprland
generate_basic_hyprland_config() {
    cat << 'EOF'
# Configuración básica
env = XCURSOR_SIZE,24
env = QT_QPA_PLATFORMTHEME,qt5ct

# Configuración de entrada
input {
    kb_layout = us
    kb_variant =
    kb_model =
    kb_options =
    kb_rules =

    follow_mouse = 1
    touchpad {
        natural_scroll = yes
    }

    sensitivity = 0
}

# Configuración general
general {
    gaps_in = 5
    gaps_out = 20
    border_size = 2
    col.active_border = rgba(33ccffee) rgba(00ff99ee) 45deg
    col.inactive_border = rgba(595959aa)
    layout = dwindle
}

EOF
}

# Función para generar configuración específica de hardware
generate_hardware_specific_config() {
    echo "# Configuración específica de hardware"
    echo ""
    
    # Configuración para laptops
    if [[ "${HARDWARE_INFO[is_laptop]}" == "true" ]]; then
        cat << 'EOF'
# Configuración para laptop
misc {
    force_default_wallpaper = 0
    disable_hyprland_logo = true
    animate_mouse_windowdragging = false
}

# Gestión de energía
binds {
    # Control de brillo
    bind = ,XF86MonBrightnessUp, exec, brightnessctl set +5%
    bind = ,XF86MonBrightnessDown, exec, brightnessctl set 5%-
    
    # Control de volumen
    bind = ,XF86AudioRaiseVolume, exec, pactl set-sink-volume @DEFAULT_SINK@ +5%
    bind = ,XF86AudioLowerVolume, exec, pactl set-sink-volume @DEFAULT_SINK@ -5%
    bind = ,XF86AudioMute, exec, pactl set-sink-mute @DEFAULT_SINK@ toggle
    
    # Gestión de energía
    bind = ,XF86PowerOff, exec, wlogout
}

EOF
    fi
    
    # Configuración para NVIDIA
    if [[ "${GPU_INFO[nvidia]}" != "" ]]; then
        cat << 'EOF'
# Configuración para NVIDIA
env = LIBVA_DRIVER_NAME,nvidia
env = XDG_SESSION_TYPE,wayland
env = GBM_BACKEND,nvidia-drm
env = __GLX_VENDOR_LIBRARY_NAME,nvidia
env = WLR_NO_HARDWARE_CURSORS,1

EOF
    fi
    
    # Configuración para AMD
    if [[ "${GPU_INFO[amd]}" != "" ]]; then
        cat << 'EOF'
# Configuración para AMD
env = LIBVA_DRIVER_NAME,radeonsi
env = XDG_SESSION_TYPE,wayland
env = GBM_BACKEND,amdgpu
env = WLR_NO_HARDWARE_CURSORS,1

EOF
    fi
    
    # Configuración para Intel
    if [[ "${GPU_INFO[intel]}" != "" ]]; then
        cat << 'EOF'
# Configuración para Intel
env = LIBVA_DRIVER_NAME,i965
env = XDG_SESSION_TYPE,wayland
env = GBM_BACKEND,intel

EOF
    fi
}

# Función para generar configuración de monitores
generate_monitor_config() {
    echo "# Configuración de monitores"
    echo ""
    
    # Detectar monitores automáticamente
    if command -v hyprctl &>/dev/null; then
        local monitors=$(hyprctl monitors | grep -c "Monitor" 2>/dev/null || echo "1")
        
        if [[ $monitors -gt 1 ]]; then
            cat << 'EOF'
# Configuración para múltiples monitores
monitor = DP-1, 1920x1080@144, 0x0, 1
monitor = HDMI-A-1, 1920x1080@60, 1920x0, 1

workspace = DP-1,1
workspace = HDMI-A-1,2

EOF
        else
            cat << 'EOF'
# Configuración para monitor único
monitor = ,preferred,auto,auto

EOF
        fi
    else
        cat << 'EOF'
# Configuración de monitor por defecto
monitor = ,preferred,auto,auto

EOF
    fi
}

# Función para generar configuración de entrada
generate_input_config() {
    echo "# Configuración de entrada"
    echo ""
    
    # Detectar dispositivos de entrada
    if [[ -d /dev/input ]]; then
        cat << 'EOF'
# Configuración de dispositivos de entrada
device {
    name = epic-mouse-v1
    sensitivity = -0.5
}

device {
    name = at-translated-set-2-keyboard
    kb_layout = us
}

EOF
    fi
}

# Función para generar configuración de ventanas
generate_window_config() {
    echo "# Configuración de ventanas"
    echo ""
    
    cat << 'EOF'
# Reglas de ventanas
windowrule = float,^(pavucontrol)$
windowrule = float,^(blueman-manager)$
windowrule = float,^(nm-connection-editor)$
windowrule = float,^(chromium)$
windowrule = float,^(firefox)$
windowrule = float,^(thunderbird)$

# Reglas de workspace
windowrulev2 = workspace 1, class:^(kitty)$
windowrulev2 = workspace 2, class:^(firefox)$
windowrulev2 = workspace 3, class:^(thunderbird)$
windowrulev2 = workspace 4, class:^(code)$
windowrulev2 = workspace 5, class:^(spotify)$

EOF
}

# Función para generar configuración de animaciones
generate_animation_config() {
    echo "# Configuración de animaciones"
    echo ""
    
    # Animaciones optimizadas según hardware
    if [[ "${CONFIG_VARIABLES[TOTAL_MEMORY_MB]}" -lt 8000 ]]; then
        # Animaciones ligeras para sistemas con poca memoria
        cat << 'EOF'
# Animaciones ligeras
animations {
    enabled = yes
    bezier = myBezier, 0.05, 0.9, 0.1, 1.05
    animation = windows, 1, 7, myBezier
    animation = windowsOut, 1, 7, default, popin 80%
    animation = border, 1, 10, default
    animation = borderangle, 1, 8, default
    animation = fade, 1, 7, default
    animation = workspaces, 1, 6, default
}

EOF
    else
        # Animaciones completas para sistemas potentes
        cat << 'EOF'
# Animaciones completas
animations {
    enabled = yes
    bezier = myBezier, 0.05, 0.9, 0.1, 1.05
    bezier = linear, 0, 0, 1, 1
    bezier = wind, 0.05, 0.9, 0.1, 1.05
    bezier = winIn, 0.1, 1.1, 0.1, 1.1
    bezier = winOut, 0.3, -0.3, 0, 1
    bezier = slow, 0, 0.85, 0.3, 1
    bezier = bounce, 1.1, 1.6, 0.1, 0.85
    bezier = overshot, 0.13, 0.99, 0.29, 1.1
    animation = windows, 1, 6, bounce, popin
    animation = windowsOut, 1, 5, winOut, popin
    animation = windowsMove, 1, 5, wind, slide
    animation = border, 1, 10, linear
    animation = borderangle, 1, 8, linear, loop
    animation = fade, 1, 7, default
    animation = workspaces, 1, 6, wind, slide
    animation = specialWorkspace, 1, 6, wind, slidevert
}

EOF
    fi
}

# Función para generar configuración de autostart
generate_autostart_config() {
    echo "# Configuración de autostart"
    echo ""
    
    cat << 'EOF'
# Aplicaciones de autostart
exec-once = waybar
exec-once = dunst
exec-once = swww-daemon
exec-once = wl-paste --watch cliphist store
exec-once = systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP=Hyprland
exec-once = dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP=Hyprland

# Configuración específica de hardware
EOF
    
    # Autostart específico para laptops
    if [[ "${HARDWARE_INFO[is_laptop]}" == "true" ]]; then
        cat << 'EOF'
exec-once = systemctl --user enable --now power-management.service
exec-once = systemctl --user enable --now lid-close-handler.service
exec-once = systemctl --user enable --now auto-pause-headphones.service

EOF
    fi
    
    # Autostart específico para NVIDIA
    if [[ "${GPU_INFO[nvidia]}" != "" ]]; then
        cat << 'EOF'
exec-once = nvidia-settings --load-config-only

EOF
    fi
}

# Función para aplicar configuración de Hyprland
apply_hyprland_config() {
    local config_file="$1"
    local target_dir="$HOME/.config/hypr"
    
    # Crear directorio si no existe
    mkdir -p "$target_dir"
    
    # Copiar configuración
    cp "$config_file" "$target_dir/hyprland.conf"
    
    log_info "Configuración aplicada a $target_dir/hyprland.conf"
}

# Función para generar configuración de Waybar optimizada
generate_waybar_config() {
    log_info "Generando configuración de Waybar optimizada..."
    
    local config_dir="$GENERATED_CONFIG_DIR/waybar"
    mkdir -p "$config_dir"
    
    # Generar configuración JSON
    {
        echo "{"
        echo "  \"layer\": \"top\","
        echo "  \"position\": \"top\","
        echo "  \"height\": 30,"
        echo "  \"spacing\": 4,"
        echo "  \"modules-left\": [\"hyprland/workspaces\"],"
        echo "  \"modules-center\": [\"hyprland/window\"],"
        echo "  \"modules-right\": ["
        
        # Módulos específicos según hardware
        if [[ "${HARDWARE_INFO[is_laptop]}" == "true" ]]; then
            echo "    \"pulseaudio\","
            echo "    \"network\","
            echo "    \"battery\","
            echo "    \"backlight\","
            echo "    \"cpu\","
            echo "    \"memory\","
            echo "    \"clock\","
            echo "    \"tray\""
        else
            echo "    \"pulseaudio\","
            echo "    \"network\","
            echo "    \"cpu\","
            echo "    \"memory\","
            echo "    \"clock\","
            echo "    \"tray\""
        fi
        
        echo "  ],"
        echo "  \"hyprland/workspaces\": {"
        echo "    \"disable-scroll\": true,"
        echo "    \"all-outputs\": true,"
        echo "    \"format\": \"{name}\""
        echo "  },"
        echo "  \"clock\": {"
        echo "    \"tooltip-format\": \"<big>{:%Y %B}</big>\\n<tt><small>{calendar}</small></tt>\","
        echo "    \"format-alt\": \"{:%Y-%m-%d}\""
        echo "  },"
        echo "  \"cpu\": {"
        echo "    \"format\": \"{usage}% \","
        echo "    \"tooltip\": false"
        echo "  },"
        echo "  \"memory\": {"
        echo "    \"format\": \"{}% \","
        echo "    \"tooltip\": false"
        echo "  },"
        echo "  \"backlight\": {"
        echo "    \"device\": \"intel_backlight\","
        echo "    \"format\": \"{percent}% {icon}\","
        echo "    \"format-icons\": [\"\", \"\", \"\", \"\", \"\"]"
        echo "  },"
        echo "  \"battery\": {"
        echo "    \"states\": {"
        echo "      \"warning\": 30,"
        echo "      \"critical\": 15"
        echo "    },"
        echo "    \"format\": \"{capacity}% {icon}\","
        echo "    \"format-charging\": \"{capacity}% \","
        echo "    \"format-plugged\": \"{capacity}% \","
        echo "    \"format-alt\": \"{time} {icon}\","
        echo "    \"format-icons\": [\"\", \"\", \"\", \"\", \"\"]"
        echo "  },"
        echo "  \"network\": {"
        echo "    \"format-wifi\": \"{essid} ({signalStrength}%) \","
        echo "    \"format-ethernet\": \"{ipaddr}/{cidr} \","
        echo "    \"tooltip-format\": \"{ifname} via {gwaddr} \","
        echo "    \"format-linked\": \"{ifname} (No IP) \","
        echo "    \"format-disconnected\": \"Disconnected ⚠\","
        echo "    \"format-alt\": \"{ifname}: {ipaddr}/{cidr}\""
        echo "  },"
        echo "  \"pulseaudio\": {"
        echo "    \"format\": \"{volume}% {icon}\","
        echo "    \"format-bluetooth\": \"{volume}% {icon}\","
        echo "    \"format-bluetooth-muted\": \" {icon}\","
        echo "    \"format-muted\": \" {icon}\","
        echo "    \"format-icons\": {"
        echo "      \"headphone\": \"\","
        echo "      \"hands-free\": \"\","
        echo "      \"headset\": \"\","
        echo "      \"phone\": \"\","
        echo "      \"portable\": \"\","
        echo "      \"car\": \"\","
        echo "      \"default\": [\"\", \"\", \"\"]"
        echo "    },"
        echo "    \"on-click\": \"pavucontrol\""
        echo "  },"
        echo "  \"tray\": {"
        echo "    \"spacing\": 10"
        echo "  }"
        echo "}"
    } > "$config_dir/config.json"
    
    # Generar CSS optimizado
    generate_waybar_css "$config_dir/style.css"
    
    # Aplicar configuración
    apply_waybar_config "$config_dir"
    
    log_info "Configuración de Waybar generada: $config_dir"
}

# Función para generar CSS de Waybar
generate_waybar_css() {
    local css_file="$1"
    
    cat << 'EOF' > "$css_file"
* {
    border: none;
    border-radius: 0;
    font-family: "JetBrainsMono Nerd Font", "Font Awesome 6 Free";
    font-size: 13px;
    min-height: 0;
}

window#waybar {
    background-color: rgba(43, 48, 59, 0.5);
    border-bottom: 3px solid rgba(100, 115, 245, 0.5);
    color: #ffffff;
    transition-property: background-color;
    transition-duration: .5s;
}

window#waybar.hidden {
    opacity: 0.2;
}

window#waybar.termite {
    background-color: #3F3F3F;
}

window#waybar.chromium {
    background-color: #000000;
    border: none;
}

button {
    box-shadow: inset 0 -3px transparent;
    border: none;
    border-radius: 0;
}

button:hover {
    background: inherit;
    box-shadow: inset 0 -3px #ffffff;
}

#workspaces button {
    padding: 0 5px;
    background-color: transparent;
    color: #ffffff;
    border-bottom: 3px solid transparent;
}

#workspaces button:hover {
    background: rgba(0, 0, 0, 0.2);
    box-shadow: inset 0 -3px #ffffff;
}

#workspaces button.active {
    background-color: #64727D;
    box-shadow: inset 0 -3px #ffffff;
}

#workspaces button.urgent {
    background-color: #eb4d4b;
}

#mode {
    background-color: #64727D;
    border-bottom: 3px solid #ffffff;
}

#clock,
#battery,
#cpu,
#memory,
#disk,
#temperature,
#backlight,
#network,
#pulseaudio,
#wireplumber,
#custom-media,
#tray,
#mode,
#idle_inhibitor,
#mpd,
#bluetooth,
#network,
#pulseaudio,
#wireplumber,
#custom-media,
#tray,
#mode,
#idle_inhibitor,
#mpd,
#bluetooth {
    padding: 0 10px;
    margin: 0 4px;
    color: #ffffff;
}

#window,
#workspaces {
    margin: 0 4px;
}

.modules-left > widget:first-child > #workspaces {
    margin-left: 0;
}

.modules-right > widget:last-child > #workspaces {
    margin-right: 0;
}

#clock {
    background-color: #64727D;
}

#battery {
    background-color: #ffffff;
    color: #000000;
}

#battery.charging, #battery.plugged {
    color: #ffffff;
    background-color: #26A65B;
}

@keyframes blink {
    to {
        background-color: #ffffff;
        color: #000000;
    }
}

#battery.critical:not(.charging) {
    background-color: #f53c3c;
    color: #ffffff;
    animation-name: blink;
    animation-duration: 0.5s;
    animation-timing-function: linear;
    animation-iteration-count: infinite;
    animation-direction: alternate;
}

label:focus {
    background-color: #000000;
}

#cpu {
    background-color: #2ecc71;
    color: #000000;
}

#memory {
    background-color: #9b59b6;
}

#disk {
    background-color: #964B00;
}

#backlight {
    background-color: #90b1b1;
}

#network {
    background-color: #2980b9;
}

#network.disconnected {
    background-color: #f53c3c;
}

#pulseaudio {
    background-color: #f1c40f;
    color: #000000;
}

#pulseaudio.muted {
    background-color: #90b1b1;
}

#wireplumber {
    background-color: #fff0f5;
    color: #000000;
}

#wireplumber.muted {
    background-color: #f53c3c;
}

#custom-media {
    background-color: #66cc99;
    color: #2a5c45;
    min-width: 100px;
}

#custom-media.custom-spotify {
    background-color: #66cc99;
}

#custom-media.custom-vlc {
    background-color: #ffa000;
}

#temperature {
    background-color: #f0932b;
}

#temperature.critical {
    background-color: #eb4d4b;
}

#tray {
    background-color: #2980b9;
}

#tray > .passive {
    -gtk-icon-effect: dim;
}

#tray > .needs-attention {
    -gtk-icon-effect: highlight;
    background-color: #eb4d4b;
}

#idle_inhibitor {
    background-color: #2d3436;
}

#idle_inhibitor.activated {
    background-color: #ecf0f1;
    color: #2d3436;
}

#mpd {
    background-color: #66cc99;
    color: #2a5c45;
}

#mpd.disconnected {
    background-color: #f53c3c;
}

#mpd.stopped {
    background-color: #90b1b1;
}

#mpd.paused {
    background-color: #51a37a;
}

#language {
    background: #00b093;
    color: #740864;
    padding: 0 5px;
    margin: 0 5px;
    min-width: 16px;
}

#keyboard-state {
    background: #97e1ad;
    color: #000000;
    padding: 0 0px;
    margin: 0 5px;
    min-width: 16px;
}

#keyboard-state > label {
    padding: 0px 5px;
}

#keyboard-state > label.locked {
    background: rgba(0, 0, 0, 0.2);
}

#scratchpad {
    background: rgba(0, 0, 0, 0.2);
}

#scratchpad.empty {
	background-color: transparent;
}
EOF
}

# Función para aplicar configuración de Waybar
apply_waybar_config() {
    local config_dir="$1"
    local target_dir="$HOME/.config/waybar"
    
    # Crear backup
    if [[ -d "$target_dir" ]]; then
        cp -r "$target_dir" "$CONFIG_BACKUP_DIR/waybar.backup"
        log_info "Backup creado: $CONFIG_BACKUP_DIR/waybar.backup"
    fi
    
    # Crear directorio si no existe
    mkdir -p "$target_dir"
    
    # Copiar configuración
    cp "$config_dir/config.json" "$target_dir/"
    cp "$config_dir/style.css" "$target_dir/"
    
    log_info "Configuración aplicada a $target_dir"
}

# Función para generar configuración completa del sistema
generate_complete_system_config() {
    log_info "Generando configuración completa del sistema..."
    
    # Generar configuraciones principales
    generate_hyprland_config
    generate_waybar_config
    
    # Generar configuraciones adicionales según hardware
    if [[ "${HARDWARE_INFO[is_laptop]}" == "true" ]]; then
        generate_power_management_config
    fi
    
    if [[ "${GPU_INFO[nvidia]}" != "" ]]; then
        generate_nvidia_config
    fi
    
    # Generar configuración de temas
    generate_theme_config
    
    log_info "Configuración completa del sistema generada"
}

# Función para generar configuración de gestión de energía
generate_power_management_config() {
    log_info "Generando configuración de gestión de energía..."
    
    local config_dir="$GENERATED_CONFIG_DIR/power-management"
    mkdir -p "$config_dir"
    
    # Configuración de swayidle
    cat << 'EOF' > "$config_dir/swayidle.conf"
# Configuración de swayidle para laptop
timeout = 300
timeout = 600
timeout = 900
timeout = 1200

# Comandos de timeout
timeout {
    command = swaylock -f -c 000000
}

# Comandos de resume
resume {
    command = swaylock -f -c 000000
}

# Comandos antes de sleep
before-sleep {
    command = swaylock -f -c 000000
}
EOF
    
    log_info "Configuración de gestión de energía generada: $config_dir"
}

# Función para generar configuración de NVIDIA
generate_nvidia_config() {
    log_info "Generando configuración de NVIDIA..."
    
    local config_dir="$GENERATED_CONFIG_DIR/nvidia"
    mkdir -p "$config_dir"
    
    # Configuración de nvidia-settings
    cat << 'EOF' > "$config_dir/nvidia-settings.conf"
# Configuración de NVIDIA optimizada
# Generada automáticamente por hyprland-dream

# Configuración de rendimiento
Attribute "AllowFlipping" "1"
Attribute "PowerMizerEnable" "1"
Attribute "PowerMizerLevel" "1"
Attribute "PowerMizerDefault" "1"

# Configuración de sincronización
Attribute "SyncToVBlank" "0"
Attribute "AllowIndirectGLXProtocol" "off"
Attribute "TripleBuffer" "1"

# Configuración de memoria
Attribute "VideoMemory" "0"
EOF
    
    log_info "Configuración de NVIDIA generada: $config_dir"
}

# Función para generar configuración de temas
generate_theme_config() {
    log_info "Generando configuración de temas..."
    
    local config_dir="$GENERATED_CONFIG_DIR/themes"
    mkdir -p "$config_dir"
    
    # Configuración de GTK
    cat << 'EOF' > "$config_dir/gtk-settings.ini"
[Settings]
gtk-theme-name=Catppuccin-Mocha-Standard-Mauve-Dark
gtk-icon-theme-name=Papirus-Dark
gtk-font-name=JetBrainsMono Nerd Font 10
gtk-cursor-theme-name=Catppuccin-Mocha-Mauve-Cursors
gtk-cursor-theme-size=24
gtk-toolbar-style=GTK_TOOLBAR_BOTH
gtk-toolbar-icon-size=GTK_ICON_SIZE_LARGE_TOOLBAR
gtk-button-images=1
gtk-menu-images=1
gtk-enable-event-sounds=1
gtk-enable-input-feedback-sounds=1
gtk-xft-antialias=1
gtk-xft-hinting=1
gtk-xft-hintstyle=hintfull
gtk-xft-rgba=rgb
EOF
    
    # Configuración de Qt
    cat << 'EOF' > "$config_dir/qt5ct.conf"
[Appearance]
style=gtk2
icon_theme=Papirus-Dark
font=JetBrainsMono Nerd Font,10,-1,5,50,0,0,0,0,0

[Fonts]
fixed=JetBrainsMono Nerd Font,10,-1,5,50,0,0,0,0,0
general=JetBrainsMono Nerd Font,10,-1,5,50,0,0,0,0,0

[Interface]
activate_item_on_single_click=1
buttonbox_layout=0
cursor_flash_time=1000
dialog_buttons_have_icons=1
double_click_interval=400
gui_effects=General, AnimateMenu, AnimateCombo, AnimateTooltip, AnimateToolBox
keyboard_scheme=2
menus_have_icons=1
show_shortcuts_in_context_menus=1
stylesheets=@Invalid()
toolbutton_style=4
underline_shortcut=1
wheel_scroll_lines=3

[Palette]
base=#1e1e2e
alternate_base=#181825
button=#313244
button_text=#cdd6f4
bright_text=#f38ba8
dark=#11111b
highlight=#cba6f7
highlighted_text=#1e1e2e
link=#89b4fa
link_visited=#f5c2e7
mid=#313244
mid_light=#45475a
shadow=#11111b
text=#cdd6f4
window=#1e1e2e
window_text=#cdd6f4
EOF
    
    log_info "Configuración de temas generada: $config_dir"
}

# Función para restaurar configuración desde backup
restore_config_from_backup() {
    local module="$1"
    
    log_info "Restaurando configuración de $module desde backup..."
    
    local backup_dir="$CONFIG_BACKUP_DIR"
    local target_dir=""
    
    case "$module" in
        "hyprland")
            target_dir="$HOME/.config/hypr"
            local backup_file="$backup_dir/hyprland.conf.backup"
            if [[ -f "$backup_file" ]]; then
                cp "$backup_file" "$target_dir/hyprland.conf"
                log_info "Configuración de Hyprland restaurada"
            fi
            ;;
        "waybar")
            target_dir="$HOME/.config/waybar"
            local backup_dir_full="$backup_dir/waybar.backup"
            if [[ -d "$backup_dir_full" ]]; then
                rm -rf "$target_dir"
                cp -r "$backup_dir_full" "$target_dir"
                log_info "Configuración de Waybar restaurada"
            fi
            ;;
        *)
            log_error "Módulo desconocido: $module"
            return 1
            ;;
    esac
}

# Función para generar reporte de configuración
generate_config_report() {
    local report_file="${1:-/tmp/hyprdream_config_report.txt}"
    
    log_info "Generando reporte de configuración..."
    
    {
        echo "=== Reporte de Configuración Inteligente ==="
        echo "Fecha: $(date)"
        echo "Sistema: $(uname -a)"
        echo ""
        
        echo "--- Hardware Detectado ---"
        echo "CPU: ${HARDWARE_INFO[cpu_model]} (${HARDWARE_INFO[cpu_cores]} cores)"
        echo "GPU: $(get_detected_gpu_info)"
        echo "Memoria: ${CONFIG_VARIABLES[TOTAL_MEMORY_MB]}MB"
        echo "Tipo: $([ "${HARDWARE_INFO[is_laptop]}" == "true" ] && echo "Laptop" || echo "Desktop")"
        echo "Monitores: ${CONFIG_VARIABLES[MONITOR_COUNT]}"
        echo ""
        
        echo "--- Configuraciones Generadas ---"
        echo "Hyprland: $GENERATED_CONFIG_DIR/hyprland.conf"
        echo "Waybar: $GENERATED_CONFIG_DIR/waybar/"
        echo "Temas: $GENERATED_CONFIG_DIR/themes/"
        if [[ "${HARDWARE_INFO[is_laptop]}" == "true" ]]; then
            echo "Gestión de energía: $GENERATED_CONFIG_DIR/power-management/"
        fi
        if [[ "${GPU_INFO[nvidia]}" != "" ]]; then
            echo "NVIDIA: $GENERATED_CONFIG_DIR/nvidia/"
        fi
        echo ""
        
        echo "--- Optimizaciones Aplicadas ---"
        for rule in "${!OPTIMIZATION_RULES[@]}"; do
            local optimizations="${OPTIMIZATION_RULES[$rule]}"
            echo "$rule: $optimizations"
        done
        
    } > "$report_file"
    
    log_info "Reporte generado: $report_file"
}

# Función auxiliar para obtener información de GPU
get_detected_gpu_info() {
    if [[ "${GPU_INFO[nvidia]}" != "" ]]; then
        echo "NVIDIA: ${GPU_INFO[nvidia]}"
    elif [[ "${GPU_INFO[amd]}" != "" ]]; then
        echo "AMD: ${GPU_INFO[amd]}"
    elif [[ "${GPU_INFO[intel]}" != "" ]]; then
        echo "Intel: ${GPU_INFO[intel]}"
    else
        echo "No detectada"
    fi
}

# Ejecutar si se llama directamente
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    init_logger
    
    case "${1:-help}" in
        "init")
            init_smart_config_manager
            ;;
        "generate")
            shift
            case "${1:-all}" in
                "hyprland")
                    generate_hyprland_config
                    ;;
                "waybar")
                    generate_waybar_config
                    ;;
                "complete")
                    generate_complete_system_config
                    ;;
                *)
                    generate_complete_system_config
                    ;;
            esac
            ;;
        "restore")
            shift
            restore_config_from_backup "$1"
            ;;
        "report")
            generate_config_report
            ;;
        *)
            echo "Uso: $0 [init|generate|restore|report]"
            echo "  generate [hyprland|waybar|complete] - Generar configuraciones"
            echo "  restore [hyprland|waybar] - Restaurar desde backup"
            ;;
    esac
fi 