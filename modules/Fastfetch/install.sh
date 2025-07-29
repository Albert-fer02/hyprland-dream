#!/usr/bin/env bash
# Instalador modular de Fastfetch para hyprdream
set -e

SCRIPT_DIR="$(dirname "$0")"
ROOT_DIR="$SCRIPT_DIR/../.."
source "$ROOT_DIR/lib/utils.sh"

require_arch

install_fastfetch() {
    print_info "Instalando fastfetch..."
    install_package "fastfetch"
    copy_config "$SCRIPT_DIR"
    print_ok "Fastfetch instalado."
}

copy_only_config() {
    copy_config "$SCRIPT_DIR"
}

show_menu() {
    echo -e "\n$CYAN=== Módulo Fastfetch (hyprdream) ===$RESET"
    echo " 1) Instalar Fastfetch (paquete + config)"
    echo " 2) Copiar solo configuración"
    echo " 0) Salir"
    echo -n "Opción: "
    read -r opt
    case $opt in
        1) install_fastfetch;;
        2) copy_only_config;;
        0) print_info "Saliendo..."; exit 0;;
        *) print_warn "Opción inválida.";;
    esac
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    show_menu
fi 