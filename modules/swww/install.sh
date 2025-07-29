#!/usr/bin/env bash
# Instalador modular de swww para hyprdream
set -e

SCRIPT_DIR="$(dirname "$0")"
ROOT_DIR="$SCRIPT_DIR/../.."
source "$ROOT_DIR/lib/utils.sh"

require_arch

install_swww() {
    print_info "Instalando swww..."
    install_package "swww"
    copy_config "$SCRIPT_DIR/config"
    print_ok "swww instalado."
}

copy_only_config() {
    copy_config "$SCRIPT_DIR/config"
}

show_menu() {
    echo -e "\n$CYAN=== Módulo swww (hyprdream) ===$RESET"
    echo " 1) Instalar swww (paquete + config)"
    echo " 2) Copiar solo configuración"
    echo " 0) Salir"
    echo -n "Opción: "
    read -r opt
    case $opt in
        1) install_swww;;
        2) copy_only_config;;
        0) print_info "Saliendo..."; exit 0;;
        *) print_warn "Opción inválida.";;
    esac
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    show_menu
fi 