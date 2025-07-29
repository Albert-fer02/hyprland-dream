#!/usr/bin/env bash
# Instalador modular de Zsh para hyprdream
set -e

SCRIPT_DIR="$(dirname "$0")"
ROOT_DIR="$SCRIPT_DIR/../.."
source "$ROOT_DIR/lib/utils.sh"

require_arch

install_zsh() {
    print_info "Instalando zsh..."
    install_package "zsh"
    copy_config "$SCRIPT_DIR/config"
    print_ok "Zsh instalado."
}

copy_only_config() {
    copy_config "$SCRIPT_DIR/config"
}

show_menu() {
    echo -e "\n$CYAN=== Módulo Zsh (hyprdream) ===$RESET"
    echo " 1) Instalar Zsh (paquete + config)"
    echo " 2) Copiar solo configuración"
    echo " 0) Salir"
    echo -n "Opción: "
    read -r opt
    case $opt in
        1) install_zsh;;
        2) copy_only_config;;
        0) print_info "Saliendo..."; exit 0;;
        *) print_warn "Opción inválida.";;
    esac
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    show_menu
fi 