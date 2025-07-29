#!/usr/bin/env bash
# Instalador modular de scripts multimedia para hyprdream
set -e

SCRIPT_DIR="$(dirname "$0")"
ROOT_DIR="$SCRIPT_DIR/../.."
source "$ROOT_DIR/lib/utils.sh"

require_arch

# Instala y configura los scripts multimedia
install_media_scripts() {
    print_info "Instalando scripts multimedia..."
    install_package "playerctl"
    install_package "pamixer"
    install_package "wget" # Para descargar carátulas de álbum

    copy_scripts "$ROOT_DIR/scripts/media"

    print_ok "Scripts multimedia instalados y configurados."
}

# Solo copiar scripts
copy_only_scripts() {
    copy_scripts "$ROOT_DIR/scripts/media"
}

# Menú interactivo
show_menu() {
    echo -e "\n$CYAN=== Módulo Multimedia (hyprdream) ===$RESET"
    echo " 1) Instalar Scripts Multimedia (paquetes + scripts)"
    echo " 2) Copiar solo Scripts Multimedia"
    echo " 0) Salir"
    echo -n "Opción: "
    read -r opt
    case $opt in
        1) install_media_scripts;;
        2) copy_only_scripts;;
        0) print_info "Saliendo..."; exit 0;;
        *) print_warn "Opción inválida.";;
    esac
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    show_menu
fi
