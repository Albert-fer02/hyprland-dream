#!/usr/bin/env bash
# Instalador modular de gestión de energía para hyprdream
set -e

SCRIPT_DIR="$(dirname "$0")"
ROOT_DIR="$SCRIPT_DIR/../.."
source "$ROOT_DIR/lib/utils.sh"

require_arch

# Instala y configura la gestión de energía
install_power_management() {
    print_info "Instalando gestión de energía..."
    install_package "swayidle"

    copy_scripts "$SCRIPT_DIR/scripts"

    # Copiar y habilitar el servicio de systemd
    local service_src="$SCRIPT_DIR/systemd/power-management.service"
    local service_dest="~/.config/systemd/user/power-management.service"
    mkdir -p "$(dirname "$service_dest")"
    cp -u "$service_src" "$service_dest"

    local service_src_headphones="$SCRIPT_DIR/systemd/auto-pause-headphones.service"
    local service_dest_headphones="~/.config/systemd/user/auto-pause-headphones.service"
    mkdir -p "$(dirname "$service_dest_headphones")"
    cp -u "$service_src_headphones" "$service_dest_headphones"

    systemctl --user daemon-reload
    systemctl --user enable power-management.service
    systemctl --user start power-management.service
    systemctl --user enable auto-pause-headphones.service
    systemctl --user start auto-pause-headphones.service

    print_ok "Gestión de energía instalada y configurada."
}

# Solo copiar configuración
copy_only_config() {
    copy_scripts "$SCRIPT_DIR/scripts"

    local service_src="$SCRIPT_DIR/systemd/power-management.service"
    local service_dest="~/.config/systemd/user/power-management.service"
    mkdir -p "$(dirname "$service_dest")"
    cp -u "$service_src" "$service_dest"

    local service_src_headphones="$SCRIPT_DIR/systemd/auto-pause-headphones.service"
    local service_dest_headphones="~/.config/systemd/user/auto-pause-headphones.service"
    mkdir -p "$(dirname "$service_dest_headphones")"
    cp -u "$service_src_headphones" "$service_dest_headphones"

    systemctl --user daemon-reload
    systemctl --user enable power-management.service
    systemctl --user start power-management.service
    systemctl --user enable auto-pause-headphones.service
    systemctl --user start auto-pause-headphones.service
}

# Menú interactivo
show_menu() {
    echo -e "\n$CYAN=== Módulo Gestión de Energía (hyprdream) ===$RESET"
    echo " 1) Instalar Gestión de Energía (paquete + config)"
    echo " 2) Copiar solo configuración"
    echo " 0) Salir"
    echo -n "Opción: "
    read -r opt
    case $opt in
        1) install_power_management;;
        2) copy_only_config;;
        0) print_info "Saliendo..."; exit 0;;
        *) print_warn "Opción inválida.";;
    esac
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    show_menu
fi
