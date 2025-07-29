#!/usr/bin/env bash
# Script maestro de instalación para hyprdream (solo Arch Linux)
set -e

ROOT_DIR="$(dirname "$0")"
source "$ROOT_DIR/core/logger.sh"
source "$ROOT_DIR/core/check-deps.sh"
source "$ROOT_DIR/lib/utils.sh"

# Inicializar logger
init_logger

require_arch

# Detectar módulos disponibles
get_modules() {
    find "$ROOT_DIR/modules" -mindepth 1 -maxdepth 1 -type d | xargs -n1 basename
}

# Verificar dependencias antes de instalar
check_prerequisites() {
    log_info "Verificando prerrequisitos..."
    
    # Verificar dependencias del sistema
    if ! check_dependencies "check"; then
        log_warn "Algunas dependencias del sistema están faltantes"
        echo -n "¿Deseas instalar las dependencias faltantes? (y/N): "
        read -r response
        if [[ "$response" =~ ^[Yy]$ ]]; then
            check_dependencies "install"
        fi
    fi
}

# Instalar módulo específico
install_module() {
    local module="$1"
    local mod_script="$ROOT_DIR/modules/$module/install.sh"
    
    if [[ -x "$mod_script" ]]; then
        log_info "Instalando módulo: $module"
        bash "$mod_script"
        log_ok "Módulo $module instalado correctamente"
    else
        log_error "No se encontró install.sh para $module"
        return 1
    fi
}

# Mostrar menú interactivo mejorado
show_menu() {
    local modules=( $(get_modules) )
    
    while true; do
        echo -e "\n$CYAN=== Instalador maestro hyprdream ===$RESET"
        echo "Módulos disponibles:"
        
        for i in "${!modules[@]}"; do
            local status=""
            if [[ -f "$ROOT_DIR/modules/${modules[$i]}/.installed" ]]; then
                status=" ✓"
            fi
            echo " $((i+1))) ${modules[$i]}$status"
        done
        
        echo ""
        echo "Opciones del sistema:"
        echo " d) Verificar dependencias"
        echo " i) Instalar dependencias faltantes"
        echo " r) Generar reporte de dependencias"
        echo " c) Limpiar cache"
        echo " 0) Salir"
        
        echo -n "Opción/es: "
        read -r opciones
        
        for opt in $opciones; do
            case $opt in
                "0")
                    log_info "Saliendo..."
                    exit 0
                    ;;
                "d")
                    check_dependencies "check"
                    ;;
                "i")
                    check_dependencies "install"
                    ;;
                "r")
                    check_dependencies "report"
                    ;;
                "c")
                    check_dependencies "clean"
                    ;;
                *)
                    if [[ "$opt" =~ ^[0-9]+$ && $opt -ge 1 && $opt -le ${#modules[@]} ]]; then
                        local mod="${modules[$((opt-1))]}"
                        install_module "$mod"
                    else
                        log_warn "Opción inválida: $opt"
                    fi
                    ;;
            esac
        done
        
        echo -e "\n$YELLOWPresiona Enter para continuar...$RESET"
        read -r
    done
}

# Función principal
main() {
    local action="${1:-menu}"
    
    case "$action" in
        "check")
            check_dependencies "check"
            ;;
        "install")
            check_dependencies "install"
            ;;
        "report")
            check_dependencies "report"
            ;;
        "clean")
            check_dependencies "clean"
            ;;
        "modules")
            get_modules
            ;;
        "menu"|"")
            check_prerequisites
            show_menu
            ;;
        *)
            log_error "Acción desconocida: $action"
            echo "Uso: $0 [check|install|report|clean|modules|menu]"
            exit 1
            ;;
    esac
}

# Ejecutar función principal
main "$@" 