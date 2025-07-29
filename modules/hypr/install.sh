#!/usr/bin/env bash
# Instalador modular de Hyprland para hyprdream
set -e

SCRIPT_DIR="$(dirname "$0")"
ROOT_DIR="$SCRIPT_DIR/../.."
source "$ROOT_DIR/lib/utils.sh"

require_arch

install_hypr() {
    print_info "Instalando hyprland..."
    install_package "hyprland"
    copy_config "$SCRIPT_DIR/config"
    copy_scripts "$SCRIPT_DIR/scripts"
    print_ok "Hyprland instalado."
}

copy_only_config() {
    copy_config "$SCRIPT_DIR/config"
    copy_scripts "$SCRIPT_DIR/scripts"
}

show_menu() {
    echo -e "\n$CYAN=== Módulo Hyprland (hyprdream) ===$RESET"
    echo " 1) Instalar Hyprland (paquete + config)"
    echo " 2) Copiar solo configuración"
    echo " 0) Salir"
    echo -n "Opción: "
    read -r opt
    case $opt in
        1) install_hypr;;
        2) copy_only_config;;
        0) print_info "Saliendo..."; exit 0;;
        *) print_warn "Opción inválida.";;
    esac
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    show_menu
fi 