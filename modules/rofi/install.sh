#!/usr/bin/env bash
# Instalador modular de Rofi para hyprdream
set -e

SCRIPT_DIR="$(dirname "$0")"
ROOT_DIR="$SCRIPT_DIR/../.."
source "$ROOT_DIR/lib/utils.sh"

require_arch

# Instala Rofi y su configuración
install_rofi() {
    print_info "Instalando rofi..."
    # Usamos rofi-wayland para mejor compatibilidad
    install_package "rofi-wayland"
    # Dependencias para los menús
    install_package "network-manager-applet" # Para nmcli
    install_package "noto-fonts-emoji" # Para el selector de emojis

    copy_config "$SCRIPT_DIR/config"
    copy_scripts "$SCRIPT_DIR/scripts"

    # Dar permisos de ejecución a los scripts
    chmod +x ~/.config/rofi/scripts/*

    print_ok "Rofi instalado y configurado."
}

# Solo copiar configuración
copy_only_config() {
    copy_config "$SCRIPT_DIR/config"
    copy_scripts "$SCRIPT_DIR/scripts"
    chmod +x ~/.config/rofi/scripts/*
}

# Menú interactivo
show_menu() {
    echo -e "\n$CYAN=== Módulo Rofi (hyprdream) ===$RESET"
    echo " 1) Instalar Rofi (paquete + config)"
    echo " 2) Copiar solo configuración"
    echo " 0) Salir"
    echo -n "Opción: "
    read -r opt
    case $opt in
        1) install_rofi;;
        2) copy_only_config;;
        0) print_info "Saliendo..."; exit 0;;
        *) print_warn "Opción inválida.";;
    esac
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    show_menu
}