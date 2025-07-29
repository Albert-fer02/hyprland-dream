#!/usr/bin/env bash
# Script para mostrar información del sistema
set -e

ROOT_DIR="$(dirname "$0")/../.."
source "$ROOT_DIR/core/logger.sh"

init_logger

show_system_info() {
    echo -e "\n$CYAN=== Información del Sistema ===$RESET"
    
    # Información básica del sistema
    echo -e "$BLUE Sistema Operativo:$RESET"
    cat /etc/os-release | grep -E "^(NAME|VERSION)" | sed 's/"/ /g'
    
    echo -e "\n$BLUE Kernel:$RESET"
    uname -r
    
    echo -e "\n$BLUE Arquitectura:$RESET"
    uname -m
    
    echo -e "\n$BLUE Uptime:$RESET"
    uptime -p
    
    echo -e "\n$BLUE Memoria:$RESET"
    free -h | grep -E "^(Mem|Swap)"
    
    echo -e "\n$BLUE Disco:$RESET"
    df -h / | tail -1
    
    echo -e "\n$BLUE CPU:$RESET"
    lscpu | grep "Model name" | cut -d: -f2 | sed 's/^[ \t]*//'
    
    echo -e "\n$BLUE GPU:$RESET"
    if command -v lspci &>/dev/null; then
        lspci | grep -i vga | cut -d: -f3 | sed 's/^[ \t]*//'
    else
        echo "lspci no disponible"
    fi
}

show_hyprland_info() {
    echo -e "\n$CYAN=== Información de Hyprland ===$RESET"
    
    # Verificar si Hyprland está instalado
    if command -v hyprctl &>/dev/null; then
        echo -e "$BLUE Versión de Hyprland:$RESET"
        hyprctl version | head -1
        
        echo -e "\n$BLUE Monitores:$RESET"
        hyprctl monitors | grep -E "^(Monitor|resolution)" | head -6
        
        echo -e "\n$BLUE Workspaces:$RESET"
        hyprctl workspaces | grep -E "^(workspace|windows)" | head -10
    else
        echo "Hyprland no está instalado o no está ejecutándose"
    fi
}

show_package_info() {
    echo -e "\n$CYAN=== Información de Paquetes ===$RESET"
    
    # Paquetes instalados
    echo -e "$BLUE Total de paquetes instalados:$RESET"
    pacman -Q | wc -l
    
    echo -e "\n$BLUE Últimos paquetes instalados:$RESET"
    pacman -Q | tail -5
    
    # Verificar paquetes de Hyprland
    echo -e "\n$BLUE Paquetes de Hyprland:$RESET"
    pacman -Q | grep -i hypr || echo "No se encontraron paquetes de Hyprland"
}

main() {
    local section="${1:-all}"
    
    case "$section" in
        "system")
            show_system_info
            ;;
        "hyprland")
            show_hyprland_info
            ;;
        "packages")
            show_package_info
            ;;
        "all"|"")
            show_system_info
            show_hyprland_info
            show_package_info
            ;;
        *)
            log_error "Sección desconocida: $section"
            echo "Uso: $0 [system|hyprland|packages|all]"
            exit 1
            ;;
    esac
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main "$@"
fi 