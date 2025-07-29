#!/usr/bin/env bash
# Módulo de instalación de Mako para hyprdream
set -e

SCRIPT_DIR="$(dirname "$0")"
ROOT_DIR="$SCRIPT_DIR/../.."
source "$ROOT_DIR/lib/utils.sh"
source "$ROOT_DIR/core/logger.sh"

init_logger

install_mako() {
    log_info "Instalando Mako..."
    
    # Instalar paquete
    install_package "mako"
    
    # Crear directorio de configuración si no existe
    if [[ -d "$SCRIPT_DIR/config" ]]; then
        copy_config "$SCRIPT_DIR/config"
        log_info "Configuración de Mako copiada"
    else
        log_warn "No se encontró configuración para Mako"
    fi
    
    log_ok "Mako instalado correctamente"
}

copy_only_config() {
    if [[ -d "$SCRIPT_DIR/config" ]]; then
        copy_config "$SCRIPT_DIR/config"
        log_ok "Configuración de Mako copiada"
    else
        log_error "No se encontró configuración para Mako"
        return 1
    fi
}

show_menu() {
    echo -e "\n$CYAN=== Módulo Mako (hyprdream) ===$RESET"
    echo " 1) Instalar Mako (paquete + config)"
    echo " 2) Copiar solo configuración"
    echo " 0) Salir"
    echo -n "Opción: "
    read -r opt
    
    case $opt in
        1) install_mako ;;
        2) copy_only_config ;;
        0) log_info "Saliendo..."; exit 0 ;;
        *) log_warn "Opción inválida." ;;
    esac
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    show_menu
fi 