#!/usr/bin/env bash
# Instalador modular de Waybar para hyprdream
set -e

SCRIPT_DIR="$(dirname "$0")"
ROOT_DIR="$SCRIPT_DIR/../.."
source "$ROOT_DIR/lib/utils.sh"

require_arch

# Instala Waybar y su configuración
install_waybar() {
    print_info "Instalando waybar..."
    install_package "waybar"
    
    # Crear directorio de configuración
    local config_dir="$HOME/.config/waybar"
    mkdir -p "$config_dir"
    
    # Copiar configuración principal
    copy_config "$SCRIPT_DIR/config"
    
    # Hacer scripts ejecutables
    chmod +x "$config_dir/scripts/"*.sh 2>/dev/null || true
    
    # Crear enlace simbólico al tema por defecto
    if [[ ! -f "$config_dir/style.css" ]]; then
        ln -sf "$config_dir/themes/tokyo-night.css" "$config_dir/style.css"
    fi
    
    print_ok "Waybar instalado con configuración modular."
}

# Solo copiar configuración
copy_only_config() {
    local config_dir="$HOME/.config/waybar"
    mkdir -p "$config_dir"
    
    copy_config "$SCRIPT_DIR/config"
    
    # Hacer scripts ejecutables
    chmod +x "$config_dir/scripts/"*.sh 2>/dev/null || true
    
    # Crear enlace simbólico al tema por defecto si no existe
    if [[ ! -f "$config_dir/style.css" ]]; then
        ln -sf "$config_dir/themes/tokyo-night.css" "$config_dir/style.css"
    fi
    
    print_ok "Configuración de Waybar copiada."
}

# Instalar dependencias adicionales
install_dependencies() {
    print_info "Instalando dependencias adicionales..."
    
    # Dependencias para scripts
    local deps=(
        "rofi"           # Para menús interactivos
        "pulseaudio"     # Para control de audio
        "networkmanager" # Para gestión de red
        "bc"            # Para cálculos en scripts
        "lm_sensors"    # Para información de temperatura
    )
    
    for dep in "${deps[@]}"; do
        if ! pacman -Q "$dep" &>/dev/null; then
            print_info "Instalando $dep..."
            install_package "$dep"
        else
            print_info "$dep ya está instalado."
        fi
    done
    
    print_ok "Dependencias instaladas."
}

# Configurar autostart
setup_autostart() {
    print_info "Configurando autostart..."
    
    local hyprland_dir="$HOME/.config/hypr"
    mkdir -p "$hyprland_dir"
    
    # Agregar waybar al autostart si no existe
    if [[ ! -f "$hyprland_dir/hyprland.conf" ]] || ! grep -q "waybar" "$hyprland_dir/hyprland.conf"; then
        echo "# Autostart Waybar" >> "$hyprland_dir/hyprland.conf"
        echo "exec-once = waybar" >> "$hyprland_dir/hyprland.conf"
        print_ok "Waybar agregado al autostart de Hyprland."
    else
        print_info "Waybar ya está configurado en autostart."
    fi
}

# Mostrar información de la configuración
show_info() {
    echo -e "\n$CYAN=== Información de Waybar ===$RESET"
    echo "Configuración: $HOME/.config/waybar/"
    echo "Temas disponibles:"
    echo "  • Tokyo Night (por defecto)"
    echo "  • Nord"
    echo "  • Dracula"
    echo "  • Catppuccin"
    echo ""
    echo "Scripts disponibles:"
    echo "  • system-info.sh - Información del sistema"
    echo "  • network-menu.sh - Gestión de red"
    echo "  • volume-menu.sh - Control de audio"
    echo "  • battery-menu.sh - Información de batería"
    echo "  • calendar-menu.sh - Calendario y fecha"
    echo "  • theme-switcher.sh - Cambio de temas"
    echo ""
    echo "Comandos útiles:"
    echo "  • waybar - Iniciar Waybar"
    echo "  • pkill waybar - Detener Waybar"
    echo "  • ~/.config/waybar/scripts/theme-switcher.sh - Cambiar tema"
}

# Menú interactivo
show_menu() {
    echo -e "\n$CYAN=== Módulo Waybar (hyprdream) ===$RESET"
    echo " 1) Instalar Waybar completo (paquete + config + deps)"
    echo " 2) Copiar solo configuración"
    echo " 3) Instalar dependencias adicionales"
    echo " 4) Configurar autostart"
    echo " 5) Mostrar información"
    echo " 0) Salir"
    echo -n "Opción: "
    read -r opt
    case $opt in
        1) install_waybar; setup_autostart; show_info;;
        2) copy_only_config;;
        3) install_dependencies;;
        4) setup_autostart;;
        5) show_info;;
        0) print_info "Saliendo..."; exit 0;;
        *) print_warn "Opción inválida.";;
    esac
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    show_menu
fi 