#!/usr/bin/env bash
# Módulo de instalación de Fuentes para hyprdream
set -e

SCRIPT_DIR="$(dirname "$0")"
ROOT_DIR="$SCRIPT_DIR/../.."
source "$ROOT_DIR/lib/utils.sh"
source "$ROOT_DIR/core/logger.sh"

init_logger

install_basic_fonts() {
    log_info "Instalando fuentes básicas..."
    
    local fonts=(
        "noto-fonts"
        "noto-fonts-emoji"
        "ttf-dejavu"
    )
    
    for font in "${fonts[@]}"; do
        install_package "$font"
    done
    
    log_ok "Fuentes básicas instaladas"
}

install_nerd_fonts() {
    log_info "Instalando fuentes Nerd Fonts..."
    
    local nerd_fonts=(
        "nerd-fonts-jetbrains-mono"
        "nerd-fonts-fira-code"
        "nerd-fonts-hack"
        "nerd-fonts-source-code-pro"
    )
    
    for font in "${nerd_fonts[@]}"; do
        install_package "$font"
    done
    
    log_ok "Nerd Fonts instaladas"
}

install_custom_fonts() {
    log_info "Instalando fuentes personalizadas..."
    
    # Crear directorio para fuentes personalizadas
    local font_dir="$HOME/.local/share/fonts"
    mkdir -p "$font_dir"
    
    # Copiar fuentes personalizadas si existen
    if [[ -d "$SCRIPT_DIR/fonts" ]]; then
        cp -r "$SCRIPT_DIR/fonts/"* "$font_dir/"
        fc-cache -fv
        log_info "Fuentes personalizadas instaladas"
    else
        log_warn "No se encontraron fuentes personalizadas"
    fi
    
    log_ok "Fuentes personalizadas procesadas"
}

install_all_fonts() {
    install_basic_fonts
    install_nerd_fonts
    install_custom_fonts
}

show_menu() {
    echo -e "\n$CYAN=== Módulo Fuentes (hyprdream) ===$RESET"
    echo " 1) Instalar todas las fuentes"
    echo " 2) Instalar solo fuentes básicas"
    echo " 3) Instalar solo Nerd Fonts"
    echo " 4) Instalar solo fuentes personalizadas"
    echo " 0) Salir"
    echo -n "Opción: "
    read -r opt
    
    case $opt in
        1) install_all_fonts ;;
        2) install_basic_fonts ;;
        3) install_nerd_fonts ;;
        4) install_custom_fonts ;;
        0) log_info "Saliendo..."; exit 0 ;;
        *) log_warn "Opción inválida." ;;
    esac
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    show_menu
fi 