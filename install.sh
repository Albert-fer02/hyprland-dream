#!/usr/bin/env bash
# Script maestro de instalación mejorado para hyprdream
# Sistema avanzado con detección de hardware, progress bars, rollback automático y más
set -e

ROOT_DIR="$(dirname "$0")"
source "$ROOT_DIR/core/colors.sh"
source "$ROOT_DIR/core/logger.sh"
source "$ROOT_DIR/core/hardware-detector.sh"
source "$ROOT_DIR/core/progress.sh"
source "$ROOT_DIR/core/rollback.sh"
source "$ROOT_DIR/core/dependency-manager.sh"
source "$ROOT_DIR/core/post-install.sh"
source "$ROOT_DIR/core/maintenance.sh"
source "$ROOT_DIR/core/disk-checker.sh"
source "$ROOT_DIR/lib/utils.sh"

# Configuración global
INSTALL_MODE="${INSTALL_MODE:-interactive}"  # interactive, automated, minimal
LOG_LEVEL="${LOG_LEVEL:-INFO}"
BACKUP_BEFORE_INSTALL="${BACKUP_BEFORE_INSTALL:-true}"
AUTO_ROLLBACK="${AUTO_ROLLBACK:-true}"

# Variables globales
declare -A SELECTED_MODULES=()
declare -A INSTALLATION_STATUS=()
declare -A HARDWARE_RECOMMENDATIONS=()

# Función para mostrar banner de bienvenida
show_welcome_banner() {
    clear
    echo -e "${CYAN}"
    cat << 'EOF'
██╗  ██╗██╗   ██╗██████╗ ██████╗ ██╗      ██████╗ ██████╗ ███████╗ █████╗ ███╗   ███╗
██║  ██║╚██╗ ██╔╝██╔══██╗██╔══██╗██║     ██╔═══██╗██╔══██╗██╔════╝██╔══██╗████╗ ████║
███████║ ╚████╔╝ ██████╔╝██████╔╝██║     ██║   ██║██║  ██║█████╗  ███████║██╔████╔██║
██╔══██║  ╚██╔╝  ██╔═══╝ ██╔══██╗██║     ██║   ██║██║  ██║██╔══╝  ██╔══██║██║╚██╔╝██║
██║  ██║   ██║   ██║     ██║  ██║███████╗╚██████╔╝██████╔╝███████╗██║  ██║██║ ╚═╝ ██║
╚═╝  ╚═╝   ╚═╝   ╚═╝     ╚═╝  ╚═╝╚══════╝ ╚═════╝ ╚═════╝ ╚══════╝╚═╝  ╚═╝╚═╝     ╚═╝
EOF
    echo -e "${RESET}"
    echo -e "${BLUE}=== Sistema de Instalación Avanzado ===${RESET}"
    echo -e "${YELLOW}Versión: 2.0 - Sistema Avanzado${RESET}"
    echo -e "${GREEN}Desarrollado para Arch Linux${RESET}"
    echo ""
}

# Función para inicializar sistema de instalación
init_installation_system() {
    log_info "Inicializando sistema de instalación avanzado..."
    
    # Inicializar logger
    init_logger
    
    # Verificar que estamos en Arch Linux
    require_arch
    
    # Verificar espacio en disco ANTES de cualquier operación
    log_info "Verificando espacio en disco..."
    if ! verify_disk_space "false"; then
        log_error "Verificación de espacio en disco falló"
        log_error "Por favor, libere espacio en disco antes de continuar"
        return 1
    fi
    
    # Configurar trap de errores si está habilitado
    if [[ "$AUTO_ROLLBACK" == "true" ]]; then
        setup_error_trap
        log_info "Sistema de rollback automático habilitado"
    fi
    
    # Inicializar sistema de rollback
    init_rollback_system
    
    # Inicializar gestor de dependencias
    init_dependency_manager
    
    # Inicializar sistema de mantenimiento
    init_maintenance_system
    
    log_info "Sistema de instalación inicializado"
}

# Detectar módulos disponibles
get_modules() {
    find "$ROOT_DIR/modules" -mindepth 1 -maxdepth 1 -type d | xargs -n1 basename
}

# Función para detectar hardware y generar recomendaciones
detect_hardware_and_recommend() {
    log_info "Detectando hardware del sistema..."
    
    # Ejecutar detección de hardware
    detect_hardware
    
    # Obtener recomendaciones basadas en hardware
    local recommendations=$(get_hardware_recommendations)
    
    # Mostrar resumen de hardware
    show_hardware_summary
    
    # Procesar recomendaciones
    for rec in $recommendations; do
        HARDWARE_RECOMMENDATIONS["$rec"]="recommended"
    done
    
    log_info "Detección de hardware completada"
}

# Función para mostrar módulos disponibles con información detallada
show_modules_detailed() {
    local modules=( $(get_modules) )
    
    echo -e "\n${CYAN}=== Módulos Disponibles ===${RESET}"
    echo ""
    
    for i in "${!modules[@]}"; do
        local module="${modules[$i]}"
        local status=""
        local recommendation=""
        
        # Verificar si está instalado
        if [[ -f "$ROOT_DIR/modules/$module/.installed" ]]; then
            status="${GREEN}✓ Instalado${RESET}"
        else
            status="${YELLOW}○ Pendiente${RESET}"
        fi
        
        # Verificar si es recomendado por hardware
        if [[ -n "${HARDWARE_RECOMMENDATIONS[$module]}" ]]; then
            recommendation="${BLUE}🔧 Recomendado${RESET}"
        fi
        
        # Mostrar información del módulo
        echo -e " $((i+1))) ${BLUE}${module}${RESET} $status $recommendation"
        
        # Mostrar descripción si existe
        if [[ -f "$ROOT_DIR/modules/$module/README.md" ]]; then
            local description=$(head -n 3 "$ROOT_DIR/modules/$module/README.md" | grep -v "^#" | head -n 1)
            if [[ -n "$description" ]]; then
                echo -e "     ${GRAY}$description${RESET}"
            fi
        fi
        echo ""
    done
}

# Función para selección interactiva de módulos
select_modules_interactive() {
    local modules=( $(get_modules) )
    
    echo -e "${CYAN}Selección de Módulos${RESET}"
    echo "Ingresa los números de los módulos que deseas instalar (separados por espacios)"
    echo "Ejemplo: 1 3 5 7"
    echo "O ingresa 'all' para instalar todos los módulos"
    echo "O ingresa 'recommended' para instalar solo los recomendados"
    echo ""
    
    read -p "Selección: " selection
    
    if [[ "$selection" == "all" ]]; then
        # Instalar todos los módulos
        for module in "${modules[@]}"; do
            SELECTED_MODULES["$module"]="selected"
        done
        log_info "Todos los módulos seleccionados"
        
    elif [[ "$selection" == "recommended" ]]; then
        # Instalar solo los recomendados
        for module in "${modules[@]}"; do
            if [[ -n "${HARDWARE_RECOMMENDATIONS[$module]}" ]]; then
                SELECTED_MODULES["$module"]="selected"
            fi
        done
        log_info "Módulos recomendados seleccionados"
        
    else
        # Procesar selección específica
        for num in $selection; do
            if [[ "$num" =~ ^[0-9]+$ && $num -ge 1 && $num -le ${#modules[@]} ]]; then
                local module="${modules[$((num-1))]}"
                SELECTED_MODULES["$module"]="selected"
                log_info "Módulo seleccionado: $module"
            else
                log_warn "Número inválido: $num"
            fi
        done
    fi
    
    # Mostrar resumen de selección
    show_selection_summary
}

# Función para mostrar resumen de selección
show_selection_summary() {
    echo -e "\n${CYAN}=== Resumen de Selección ===${RESET}"
    
    if [[ ${#SELECTED_MODULES[@]} -eq 0 ]]; then
        echo -e "${YELLOW}No se seleccionaron módulos${RESET}"
        return
    fi
    
    echo -e "${GREEN}Módulos seleccionados:${RESET}"
    for module in "${!SELECTED_MODULES[@]}"; do
        echo "  • $module"
    done
    
    echo ""
    echo -e "${BLUE}Total: ${#SELECTED_MODULES[@]} módulos${RESET}"
}

# Función para verificar prerrequisitos
check_prerequisites() {
    log_info "Verificando prerrequisitos del sistema..."
    
    # Verificar dependencias del sistema
    check_system_dependencies
    
    # Verificar dependencias de desarrollo
    check_development_dependencies
    
    # Verificar espacio en disco
    local available_space=$(df / | tail -1 | awk '{print $4}')
    local available_gb=$((available_space / 1024 / 1024))
    
    if [[ $available_gb -lt 5 ]]; then
        log_error "Espacio insuficiente en disco: ${available_gb}GB disponible, se requieren al menos 5GB"
        return 1
    fi
    
    log_info "Prerrequisitos verificados: OK"
}

# Función para instalar módulo con progress bar y rollback
install_module_advanced() {
    local module="$1"
    local mod_script="$ROOT_DIR/modules/$module/install.sh"
    
    log_info "Instalando módulo: $module"
    
    # Registrar paso de instalación
    register_installation_step "install_$module" "install" "$module"
    
    # Crear punto de backup antes de instalar
    create_backup_point "pre_$module" "Backup antes de instalar $module"
    
    # Verificar si el script existe
    if [[ ! -x "$mod_script" ]]; then
        log_error "Script de instalación no encontrado: $mod_script"
        return 1
    fi
    
    # Instalar módulo
    if bash "$mod_script"; then
        # Marcar como instalado
        touch "$ROOT_DIR/modules/$module/.installed"
        INSTALLATION_STATUS["$module"]="installed"
        
        # Registrar operación de rollback
        push_rollback_operation "module_install" "$module"
        
        log_ok "Módulo $module instalado correctamente"
        return 0
    else
        INSTALLATION_STATUS["$module"]="failed"
        log_error "Error al instalar módulo $module"
        return 1
    fi
}

# Función para instalar módulos seleccionados
install_selected_modules() {
    local modules=("${!SELECTED_MODULES[@]}")
    local total=${#modules[@]}
    
    if [[ $total -eq 0 ]]; then
        log_warn "No hay módulos seleccionados para instalar"
        return 0
    fi
    
    log_info "Instalando $total módulos seleccionados..."
    
    # Mostrar progress bar de instalación de módulos
    show_module_progress "${modules[@]}"
    
    local success_count=0
    local error_count=0
    
    for i in "${!modules[@]}"; do
        local module="${modules[$i]}"
        local current=$((i + 1))
        
        log_info "Instalando módulo $current/$total: $module"
        
        if install_module_advanced "$module"; then
            success_count=$((success_count + 1))
        else
            error_count=$((error_count + 1))
            
            # Si está habilitado el rollback automático, ejecutarlo
            if [[ "$AUTO_ROLLBACK" == "true" ]]; then
                log_error "Error en instalación, ejecutando rollback..."
                execute_rollback "module_install" "Error al instalar $module"
                return 1
            fi
        fi
    done
    
    log_info "Instalación de módulos completada: $success_count exitosos, $error_count errores"
    
    return $error_count
}

# Función para ejecutar post-instalación
run_post_installation_advanced() {
    log_info "Ejecutando post-instalación avanzada..."
    
    # Ejecutar post-instalación
    run_post_installation
    
    log_info "Post-instalación completada"
}

# Función para mostrar menú principal mejorado
show_advanced_menu() {
    while true; do
        clear
        show_welcome_banner
        
        echo -e "${CYAN}=== Menú Principal ===${RESET}"
        echo ""
        echo "1) Detectar hardware y mostrar recomendaciones"
        echo "2) Seleccionar módulos para instalar"
        echo "3) Instalar módulos seleccionados"
        echo "4) Ejecutar post-instalación"
        echo "5) Ejecutar mantenimiento del sistema"
        echo ""
        echo "6) Verificar dependencias"
        echo "7) Gestionar cache de paquetes"
        echo "8) Generar reportes"
        echo "9) Configurar sistema"
        echo ""
        echo "0) Salir"
        echo ""
        
        read -p "Opción: " choice
        
        case $choice in
            1)
                detect_hardware_and_recommend
                echo -e "\n${YELLOW}Presiona Enter para continuar...${RESET}"
                read -r
                ;;
            2)
                show_modules_detailed
                select_modules_interactive
                echo -e "\n${YELLOW}Presiona Enter para continuar...${RESET}"
                read -r
                ;;
            3)
                if [[ ${#SELECTED_MODULES[@]} -eq 0 ]]; then
                    echo -e "\n${RED}No hay módulos seleccionados. Selecciona módulos primero.${RESET}"
                    echo -e "\n${YELLOW}Presiona Enter para continuar...${RESET}"
                    read -r
                    continue
                fi
                
                check_prerequisites
                install_selected_modules
                echo -e "\n${YELLOW}Presiona Enter para continuar...${RESET}"
                read -r
                ;;
            4)
                run_post_installation_advanced
                echo -e "\n${YELLOW}Presiona Enter para continuar...${RESET}"
                read -r
                ;;
            5)
                run_maintenance
                echo -e "\n${YELLOW}Presiona Enter para continuar...${RESET}"
                read -r
                ;;
            6)
                check_dependencies "check"
                echo -e "\n${YELLOW}Presiona Enter para continuar...${RESET}"
                read -r
                ;;
            7)
                manage_package_cache "status"
                echo -e "\n${YELLOW}Presiona Enter para continuar...${RESET}"
                read -r
                ;;
            8)
                show_reports_menu
                ;;
            9)
                show_configuration_menu
                ;;
            0)
                log_info "Saliendo del instalador..."
                exit 0
                ;;
            *)
                echo -e "\n${RED}Opción inválida${RESET}"
                echo -e "\n${YELLOW}Presiona Enter para continuar...${RESET}"
                read -r
                ;;
        esac
    done
}

# Función para mostrar menú de reportes
show_reports_menu() {
    while true; do
        clear
        echo -e "${CYAN}=== Menú de Reportes ===${RESET}"
        echo ""
        echo "1) Reporte de dependencias"
        echo "2) Reporte de hardware"
        echo "3) Reporte de health check"
        echo "4) Reporte de post-instalación"
        echo "5) Reporte de mantenimiento"
        echo "6) Reporte de rollback"
        echo ""
        echo "0) Volver al menú principal"
        echo ""
        
        read -p "Opción: " choice
        
        case $choice in
            1)
                generate_dependency_report
                ;;
            2)
                export_hardware_info
                ;;
            3)
                generate_health_report
                ;;
            4)
                generate_post_install_report
                ;;
            5)
                generate_health_report
                ;;
            6)
                list_backup_points
                ;;
            0)
                break
                ;;
            *)
                echo -e "\n${RED}Opción inválida${RESET}"
                ;;
        esac
        
        echo -e "\n${YELLOW}Presiona Enter para continuar...${RESET}"
        read -r
    done
}

# Función para mostrar menú de configuración
show_configuration_menu() {
    while true; do
        clear
        echo -e "${CYAN}=== Menú de Configuración ===${RESET}"
        echo ""
        echo "1) Configurar nivel de log"
        echo "2) Configurar modo de instalación"
        echo "3) Configurar backup automático"
        echo "4) Configurar rollback automático"
        echo "5) Configurar cache de paquetes"
        echo ""
        echo "0) Volver al menú principal"
        echo ""
        
        read -p "Opción: " choice
        
        case $choice in
            1)
                echo -e "\n${BLUE}Nivel de log actual: $LOG_LEVEL${RESET}"
                echo "Opciones: DEBUG, INFO, WARN, ERROR, FATAL"
                read -p "Nuevo nivel: " new_level
                if [[ -n "$new_level" ]]; then
                    LOG_LEVEL="$new_level"
                    echo -e "${GREEN}Nivel de log actualizado a: $LOG_LEVEL${RESET}"
                fi
                ;;
            2)
                echo -e "\n${BLUE}Modo de instalación actual: $INSTALL_MODE${RESET}"
                echo "Opciones: interactive, automated, minimal"
                read -p "Nuevo modo: " new_mode
                if [[ -n "$new_mode" ]]; then
                    INSTALL_MODE="$new_mode"
                    echo -e "${GREEN}Modo de instalación actualizado a: $INSTALL_MODE${RESET}"
                fi
                ;;
            3)
                echo -e "\n${BLUE}Backup automático actual: $BACKUP_BEFORE_INSTALL${RESET}"
                read -p "Habilitar backup automático? (y/N): " enable_backup
                if [[ "$enable_backup" =~ ^[Yy]$ ]]; then
                    BACKUP_BEFORE_INSTALL="true"
                    echo -e "${GREEN}Backup automático habilitado${RESET}"
                else
                    BACKUP_BEFORE_INSTALL="false"
                    echo -e "${YELLOW}Backup automático deshabilitado${RESET}"
                fi
                ;;
            4)
                echo -e "\n${BLUE}Rollback automático actual: $AUTO_ROLLBACK${RESET}"
                read -p "Habilitar rollback automático? (Y/n): " enable_rollback
                if [[ "$enable_rollback" =~ ^[Nn]$ ]]; then
                    AUTO_ROLLBACK="false"
                    echo -e "${YELLOW}Rollback automático deshabilitado${RESET}"
                else
                    AUTO_ROLLBACK="true"
                    echo -e "${GREEN}Rollback automático habilitado${RESET}"
                fi
                ;;
            5)
                manage_package_cache "status"
                echo ""
                echo "1) Limpiar cache"
                echo "2) Actualizar cache"
                echo "3) Optimizar cache"
                read -p "Opción: " cache_choice
                case $cache_choice in
                    1) manage_package_cache "clean" ;;
                    2) manage_package_cache "update" ;;
                    3) manage_package_cache "optimize" ;;
                esac
                ;;
            0)
                break
                ;;
            *)
                echo -e "\n${RED}Opción inválida${RESET}"
                ;;
        esac
        
        echo -e "\n${YELLOW}Presiona Enter para continuar...${RESET}"
        read -r
    done
}

# Función para instalación automática
run_automated_installation() {
    log_info "Iniciando instalación automática..."
    
    # Detectar hardware
    detect_hardware_and_recommend
    
    # Seleccionar módulos recomendados automáticamente
    for module in $(get_modules); do
        if [[ -n "${HARDWARE_RECOMMENDATIONS[$module]}" ]]; then
            SELECTED_MODULES["$module"]="selected"
        fi
    done
    
    # Verificar prerrequisitos
    check_prerequisites
    
    # Instalar módulos
    install_selected_modules
    
    # Ejecutar post-instalación
    run_post_installation_advanced
    
    log_info "Instalación automática completada"
}

# Función para instalación mínima
run_minimal_installation() {
    log_info "Iniciando instalación mínima..."
    
    # Solo instalar módulos básicos
    local basic_modules=("hypr" "waybar" "dunst")
    
    for module in "${basic_modules[@]}"; do
        SELECTED_MODULES["$module"]="selected"
    done
    
    # Verificar prerrequisitos
    check_prerequisites
    
    # Instalar módulos
    install_selected_modules
    
    log_info "Instalación mínima completada"
}

# Función principal
main() {
    local action="${1:-menu}"
    
    # Mostrar banner de bienvenida
    show_welcome_banner
    
    # Inicializar sistema de instalación
    if ! init_installation_system; then
        log_error "Error al inicializar el sistema de instalación"
        log_error "Verifique el espacio en disco y los permisos del sistema"
        exit 1
    fi
    
    case "$action" in
        "auto")
            run_automated_installation
            ;;
        "minimal")
            run_minimal_installation
            ;;
        "hardware")
            detect_hardware_and_recommend
            ;;
        "modules")
            get_modules
            ;;
        "install")
            shift
            for module in "$@"; do
                SELECTED_MODULES["$module"]="selected"
            done
            check_prerequisites
            install_selected_modules
            ;;
        "post-install")
            run_post_installation_advanced
            ;;
        "maintenance")
            run_maintenance
            ;;
        "health")
            run_health_checks
            ;;
        "menu"|"")
            show_advanced_menu
            ;;
        *)
            log_error "Acción desconocida: $action"
            echo "Uso: $0 [auto|minimal|hardware|modules|install|post-install|maintenance|health|menu]"
            exit 1
            ;;
    esac
}

# Ejecutar función principal
main "$@" 