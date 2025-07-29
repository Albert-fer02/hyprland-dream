#!/usr/bin/env bash
# Instalador modular de Swaylock para hyprdream
set -e

SCRIPT_DIR="$(dirname "$0")"
ROOT_DIR="$SCRIPT_DIR/../.."
source "$ROOT_DIR/lib/utils.sh"

require_arch

# Instala Swaylock y su configuración
install_swaylock() {
    print_info "Instalando swaylock..."
    install_package "swaylock"
    copy_config "$SCRIPT_DIR/config"
    print_ok "Swaylock instalado y configurado."
}

# Solo copiar configuración
copy_only_config() {
    copy_config "$SCRIPT_DIR/config"
}

# Menú interactivo
show_menu() {
    echo -e "\n$CYAN=== Módulo Swaylock (hyprdream) ===$RESET"
    echo " 1) Instalar Swaylock (paquete + config)"
    echo " 2) Copiar solo configuración"
    echo " 0) Salir"
    echo -n "Opción: "
    read -r opt
    case $opt in
        1) install_swaylock;;
        2) copy_only_config;;
        0) print_info "Saliendo..."; exit 0;;
        *) print_warn "Opción inválida.";;
    esac
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    show_menu
fi