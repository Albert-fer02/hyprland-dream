#!/usr/bin/env bash
# Módulo de instalación de Temas para hyprdream
set -e

SCRIPT_DIR="$(dirname "$0")"
ROOT_DIR="$SCRIPT_DIR/../.."
source "$ROOT_DIR/lib/utils.sh"
source "$ROOT_DIR/core/logger.sh"

init_logger

install_gtk_themes() {
    log_info "Instalando temas GTK..."
    
    local gtk_themes=(
        "catppuccin-gtk-theme-mocha"
        "adw-gtk3"
        "orchis-theme"
        "fluent-gtk-theme"
    )
    
    for theme in "${gtk_themes[@]}"; do
        install_package "$theme"
    done
    
    log_ok "Temas GTK instalados"
}

install_icon_themes() {
    log_info "Instalando temas de iconos..."
    
    local icon_themes=(
        "papirus-icon-theme"
        "tela-icon-theme"
        "fluent-icon-theme"
        "beautyline"
    )
    
    for theme in "${icon_themes[@]}"; do
        install_package "$theme"
    done
    
    log_ok "Temas de iconos instalados"
}

install_cursor_themes() {
    log_info "Instalando temas de cursor..."
    
    local cursor_themes=(
        "catppuccin-cursors-mocha"
        "breeze"
        "capitaine-cursors"
    )
    
    for theme in "${cursor_themes[@]}"; do
        install_package "$theme"
    done
    
    log_ok "Temas de cursor instalados"
}

install_custom_themes() {
    log_info "Instalando temas personalizados..."
    
    # Crear directorios para temas personalizados
    local gtk_dir="$HOME/.local/share/themes"
    local icon_dir="$HOME/.local/share/icons"
    mkdir -p "$gtk_dir" "$icon_dir"
    
    # Copiar temas personalizados si existen
    if [[ -d "$SCRIPT_DIR/gtk" ]]; then
        cp -r "$SCRIPT_DIR/gtk/"* "$gtk_dir/"
        log_info "Temas GTK personalizados instalados"
    fi
    
    if [[ -d "$SCRIPT_DIR/icons" ]]; then
        cp -r "$SCRIPT_DIR/icons/"* "$icon_dir/"
        log_info "Iconos personalizados instalados"
    fi
    
    log_ok "Temas personalizados procesados"
}

install_all_themes() {
    install_gtk_themes
    install_icon_themes
    install_cursor_themes
    install_custom_themes
}

show_menu() {
    echo -e "\n$CYAN=== Módulo Temas (hyprdream) ===$RESET"
    echo " 1) Instalar todos los temas"
    echo " 2) Instalar solo temas GTK"
    echo " 3) Instalar solo temas de iconos"
    echo " 4) Instalar solo temas de cursor"
    echo " 5) Instalar solo temas personalizados"
    echo " 0) Salir"
    echo -n "Opción: "
    read -r opt
    
    case $opt in
        1) install_all_themes ;;
        2) install_gtk_themes ;;
        3) install_icon_themes ;;
        4) install_cursor_themes ;;
        5) install_custom_themes ;;
        0) log_info "Saliendo..."; exit 0 ;;
        *) log_warn "Opción inválida." ;;
    esac
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    show_menu
fi 