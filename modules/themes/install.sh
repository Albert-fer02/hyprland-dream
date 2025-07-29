#!/usr/bin/env bash
# Módulo de instalación de Temas para hyprdream
set -e

SCRIPT_DIR="$(dirname "$0")"
ROOT_DIR="$SCRIPT_DIR/../.."
source "$ROOT_DIR/lib/utils.sh"
source "$ROOT_DIR/core/logger.sh"

init_logger

install_theme_dependencies() {
    log_info "Instalando dependencias para el sistema de temas..."
    
    local dependencies=(
        "nerd-fonts-jetbrains-mono"
        "nerd-fonts-fira-code"
        "nerd-fonts-hack"
        "feh"
        "imagemagick"
        "swww"
    )
    
    for dep in "${dependencies[@]}"; do
        install_package "$dep"
    done
    
    log_ok "Dependencias de temas instaladas"
}

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

setup_theme_system() {
    log_info "Configurando sistema de temas..."
    
    # Crear directorios necesarios
    local config_dir="$HOME/.config/hyprdream"
    local cache_dir="$HOME/.cache/hyprdream-themes"
    
    mkdir -p "$config_dir" "$cache_dir"
    
    # Hacer el theme-switcher ejecutable
    chmod +x "$SCRIPT_DIR/theme-switcher.sh"
    
    # Crear enlace simbólico para fácil acceso
    local bin_dir="$ROOT_DIR/bin"
    mkdir -p "$bin_dir"
    
    if [[ ! -L "$bin_dir/theme-switcher" ]]; then
        ln -sf "$SCRIPT_DIR/theme-switcher.sh" "$bin_dir/theme-switcher"
        log_info "Enlace simbólico creado: $bin_dir/theme-switcher"
    fi
    
    # Crear configuración inicial
    if [[ ! -f "$config_dir/theme-config.conf" ]]; then
        cat > "$config_dir/theme-config.conf" << EOF
# Configuración del sistema de temas Hyprland Dream

# Tema por defecto
DEFAULT_THEME="catppuccin"

# Configuración de blur
DEFAULT_BLUR_LEVEL="medium"

# Configuración de transparencia
DEFAULT_TRANSPARENCY="0.85"

# Habilitar sincronización de wallpapers
SYNC_WALLPAPERS=true

# Habilitar preview automático
AUTO_PREVIEW=false

# Configuración de cambio automático día/noche
AUTO_SWITCH_ENABLED=false
DAY_THEME="catppuccin"
NIGHT_THEME="tokyo-night"
DAY_START_HOUR=6
NIGHT_START_HOUR=18
EOF
        log_info "Configuración inicial creada"
    fi
    
    log_ok "Sistema de temas configurado"
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

apply_default_theme() {
    log_info "Aplicando tema por defecto..."
    
    # Aplicar tema Catppuccin por defecto
    if [[ -f "$SCRIPT_DIR/theme-switcher.sh" ]]; then
        "$SCRIPT_DIR/theme-switcher.sh" apply catppuccin --no-preview
        log_ok "Tema por defecto aplicado"
    else
        log_warn "theme-switcher.sh no encontrado, no se puede aplicar tema por defecto"
    fi
}

install_all_themes() {
    install_theme_dependencies
    install_gtk_themes
    install_icon_themes
    install_cursor_themes
    install_custom_themes
    setup_theme_system
    apply_default_theme
    
    log_ok "Sistema de temas completamente instalado"
    echo -e "\n${GREEN}¡Sistema de temas instalado exitosamente!${RESET}"
    echo -e "${CYAN}Comandos disponibles:${RESET}"
    echo -e "  theme-switcher apply <tema>    - Aplicar tema específico"
    echo -e "  theme-switcher list            - Listar temas disponibles"
    echo -e "  theme-switcher preview <tema>  - Mostrar preview del tema"
    echo -e "  theme-switcher schedule <día> <noche> - Programar cambio automático"
    echo -e "\n${YELLOW}Temas disponibles:${RESET} nord, dracula, catppuccin, tokyo-night, custom"
}

show_menu() {
    echo -e "\n$CYAN=== Módulo Temas (hyprdream) ===$RESET"
    echo " 1) Instalar sistema completo de temas"
    echo " 2) Instalar solo dependencias"
    echo " 3) Instalar solo temas GTK"
    echo " 4) Instalar solo temas de iconos"
    echo " 5) Instalar solo temas de cursor"
    echo " 6) Configurar sistema de temas"
    echo " 7) Aplicar tema por defecto"
    echo " 8) Mostrar comandos disponibles"
    echo " 0) Salir"
    echo -n "Opción: "
    read -r opt
    
    case $opt in
        1) install_all_themes ;;
        2) install_theme_dependencies ;;
        3) install_gtk_themes ;;
        4) install_icon_themes ;;
        5) install_cursor_themes ;;
        6) setup_theme_system ;;
        7) apply_default_theme ;;
        8)
            echo -e "\n${CYAN}Comandos del sistema de temas:${RESET}"
            echo -e "  theme-switcher apply <tema>    - Aplicar tema específico"
            echo -e "  theme-switcher list            - Listar temas disponibles"
            echo -e "  theme-switcher current         - Mostrar tema actual"
            echo -e "  theme-switcher preview <tema>  - Mostrar preview del tema"
            echo -e "  theme-switcher backup          - Crear backup"
            echo -e "  theme-switcher restore <path>  - Restaurar backup"
            echo -e "  theme-switcher schedule <día> <noche> - Programar cambio automático"
            echo -e "  theme-switcher create <nombre> - Crear tema personalizado"
            echo -e "\n${YELLOW}Temas disponibles:${RESET} nord, dracula, catppuccin, tokyo-night, custom"
            ;;
        0) log_info "Saliendo..."; exit 0 ;;
        *) log_warn "Opción inválida." ;;
    esac
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    show_menu
fi 