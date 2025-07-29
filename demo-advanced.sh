#!/usr/bin/env bash
# Script de demostración del sistema de instalación avanzado de hyprdream
# Muestra todas las funcionalidades implementadas

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

# Función para mostrar banner de demostración
show_demo_banner() {
    clear
    echo -e "${CYAN}"
    cat << 'EOF'
██████╗ ███████╗███╗   ███╗ ██████╗     █████╗ ██████╗ ██╗     ██╗   ██╗ ██████╗ ███████╗██████╗ 
██╔══██╗██╔════╝████╗ ████║██╔═══██╗    ██╔══██╗██╔══██╗██║     ██║   ██║██╔════╝ ██╔════╝██╔══██╗
██║  ██║█████╗  ██╔████╔██║██║   ██║    ███████║██║  ██║██║     ██║   ██║██║  ███╗█████╗  ██████╔╝
██║  ██║██╔══╝  ██║╚██╔╝██║██║   ██║    ██╔══██║██║  ██║██║     ██║   ██║██║   ██║██╔══╝  ██╔══██╗
██████╔╝███████╗██║ ╚═╝ ██║╚██████╔╝    ██║  ██║██████╔╝███████╗╚██████╔╝╚██████╔╝███████╗██║  ██║
╚═════╝ ╚══════╝╚═╝     ╚═╝ ╚═════╝     ╚═╝  ╚═╝╚═════╝ ╚══════╝ ╚═════╝  ╚═════╝ ╚══════╝╚═╝  ╚═╝
EOF
    echo -e "${RESET}"
    echo -e "${BLUE}=== Demostración del Sistema de Instalación Avanzado ===${RESET}"
    echo -e "${YELLOW}Versión: 2.0 - Todas las Funcionalidades${RESET}"
    echo ""
}

# Función para demostrar detección de hardware
demo_hardware_detection() {
    echo -e "${CYAN}=== Demostración: Detección de Hardware ===${RESET}"
    echo ""
    
    # Ejecutar detección de hardware
    detect_hardware
    
    # Mostrar resumen
    show_hardware_summary
    
    echo -e "\n${GREEN}✓ Detección de hardware completada${RESET}"
    echo ""
}

# Función para demostrar progress bars
demo_progress_bars() {
    echo -e "${CYAN}=== Demostración: Progress Bars Visuales ===${RESET}"
    echo ""
    
    # Demo de instalación de paquetes
    echo -e "${BLUE}Simulando instalación de paquetes...${RESET}"
    show_package_install_progress "hyprland" "waybar" "dunst" "kitty" "rofi"
    
    # Demo de configuración
    echo -e "\n${BLUE}Simulando configuración...${RESET}"
    show_config_progress "hyprland.conf" "waybar.css" "dunst.conf" "kitty.conf"
    
    # Demo de verificación
    echo -e "\n${BLUE}Simulando verificación...${RESET}"
    show_verification_progress "dependencias" "configuraciones" "servicios" "permisos"
    
    # Demo de finalización
    echo -e "\n${BLUE}Simulando finalización...${RESET}"
    show_finalization_progress "Creando shortcuts" "Configurando variables" "Iniciando servicios"
    
    echo -e "\n${GREEN}✓ Progress bars demostradas${RESET}"
    echo ""
}

# Función para demostrar sistema de rollback
demo_rollback_system() {
    echo -e "${CYAN}=== Demostración: Sistema de Rollback ===${RESET}"
    echo ""
    
    # Inicializar sistema de rollback
    echo -e "${BLUE}Inicializando sistema de rollback...${RESET}"
    init_rollback_system
    
    # Crear algunos puntos de backup
    echo -e "${BLUE}Creando puntos de backup...${RESET}"
    create_backup_point "demo_1" "Backup de demostración 1"
    create_backup_point "demo_2" "Backup de demostración 2"
    
    # Registrar algunas operaciones
    echo -e "${BLUE}Registrando operaciones...${RESET}"
    register_installation_step "demo_package" "install" "demo-package"
    push_rollback_operation "package_install" "demo-package"
    
    register_installation_step "demo_config" "config" "demo.conf"
    push_rollback_operation "config_copy" "demo.conf"
    
    # Listar puntos de backup
    echo -e "${BLUE}Listando puntos de backup...${RESET}"
    list_backup_points
    
    echo -e "\n${GREEN}✓ Sistema de rollback demostrado${RESET}"
    echo ""
}

# Función para demostrar gestor de dependencias
demo_dependency_manager() {
    echo -e "${CYAN}=== Demostración: Gestor de Dependencias ===${RESET}"
    echo ""
    
    # Inicializar gestor de dependencias
    echo -e "${BLUE}Inicializando gestor de dependencias...${RESET}"
    init_dependency_manager
    
    # Verificar repos AUR
    echo -e "${BLUE}Verificando repositorios AUR...${RESET}"
    local aur_info=$(check_aur_repos)
    local aur_enabled=$(echo "$aur_info" | cut -d: -f1)
    local aur_helper=$(echo "$aur_info" | cut -d: -f2)
    echo "AUR habilitado: $aur_enabled"
    echo "Helper AUR: ${aur_helper:-ninguno}"
    
    # Mostrar estado del cache
    echo -e "\n${BLUE}Estado del cache de paquetes:${RESET}"
    manage_package_cache "status"
    
    # Generar reporte de dependencias
    echo -e "\n${BLUE}Generando reporte de dependencias...${RESET}"
    generate_dependency_report "/tmp/demo_deps_report.txt"
    echo "Reporte generado en: /tmp/demo_deps_report.txt"
    
    echo -e "\n${GREEN}✓ Gestor de dependencias demostrado${RESET}"
    echo ""
}

# Función para demostrar post-instalación
demo_post_installation() {
    echo -e "${CYAN}=== Demostración: Sistema de Post-Instalación ===${RESET}"
    echo ""
    
    # Configurar servicios systemd (simulado)
    echo -e "${BLUE}Configurando servicios systemd...${RESET}"
    local services=("bluetooth" "NetworkManager" "pipewire")
    show_service_progress "${services[@]}"
    
    # Configurar variables de entorno
    echo -e "\n${BLUE}Configurando variables de entorno...${RESET}"
    setup_environment_variables
    
    # Generar shortcuts
    echo -e "\n${BLUE}Generando shortcuts de desktop...${RESET}"
    local shortcuts=("hyprland-settings" "waybar" "dunst" "kitty")
    show_config_progress "${shortcuts[@]}"
    
    # Configurar permisos
    echo -e "\n${BLUE}Configurando permisos y seguridad...${RESET}"
    local permissions=("~/.config" "~/.local" "~/.cache")
    show_permissions_progress "${permissions[@]}"
    
    # Generar reporte
    echo -e "\n${BLUE}Generando reporte de post-instalación...${RESET}"
    generate_post_install_report "/tmp/demo_post_install_report.txt"
    echo "Reporte generado en: /tmp/demo_post_install_report.txt"
    
    echo -e "\n${GREEN}✓ Sistema de post-instalación demostrado${RESET}"
    echo ""
}

# Función para demostrar sistema de mantenimiento
demo_maintenance_system() {
    echo -e "${CYAN}=== Demostración: Sistema de Mantenimiento ===${RESET}"
    echo ""
    
    # Inicializar sistema de mantenimiento
    echo -e "${BLUE}Inicializando sistema de mantenimiento...${RESET}"
    init_maintenance_system
    
    # Ejecutar health checks
    echo -e "${BLUE}Ejecutando health checks...${RESET}"
    run_health_checks
    
    # Auto-update de configuraciones
    echo -e "\n${BLUE}Auto-update de configuraciones...${RESET}"
    auto_update_configurations
    
    # Cleanup
    echo -e "\n${BLUE}Ejecutando cleanup...${RESET}"
    run_cleanup
    
    # Generar reportes
    echo -e "\n${BLUE}Generando reportes de mantenimiento...${RESET}"
    generate_health_report "/tmp/demo_health_report.txt"
    generate_update_report "/tmp/demo_update_report.txt"
    generate_cleanup_report "1048576" "0" "/tmp/demo_cleanup_report.txt"
    
    echo "Reportes generados en:"
    echo "  - /tmp/demo_health_report.txt"
    echo "  - /tmp/demo_update_report.txt"
    echo "  - /tmp/demo_cleanup_report.txt"
    
    echo -e "\n${GREEN}✓ Sistema de mantenimiento demostrado${RESET}"
    echo ""
}

# Función para mostrar menú de demostración
show_demo_menu() {
    while true; do
        clear
        show_demo_banner
        
        echo -e "${CYAN}=== Menú de Demostración ===${RESET}"
        echo ""
        echo "1) Detección de Hardware"
        echo "2) Progress Bars Visuales"
        echo "3) Sistema de Rollback"
        echo "4) Gestor de Dependencias"
        echo "5) Sistema de Post-Instalación"
        echo "6) Sistema de Mantenimiento"
        echo "7) Demostración Completa"
        echo ""
        echo "0) Salir"
        echo ""
        
        read -p "Selecciona una demostración: " choice
        
        case $choice in
            1)
                demo_hardware_detection
                ;;
            2)
                demo_progress_bars
                ;;
            3)
                demo_rollback_system
                ;;
            4)
                demo_dependency_manager
                ;;
            5)
                demo_post_installation
                ;;
            6)
                demo_maintenance_system
                ;;
            7)
                demo_complete_system
                ;;
            0)
                echo -e "\n${GREEN}¡Gracias por ver la demostración!${RESET}"
                exit 0
                ;;
            *)
                echo -e "\n${RED}Opción inválida${RESET}"
                ;;
        esac
        
        echo -e "\n${YELLOW}Presiona Enter para continuar...${RESET}"
        read -r
    done
}

# Función para demostración completa
demo_complete_system() {
    echo -e "${CYAN}=== Demostración Completa del Sistema ===${RESET}"
    echo ""
    
    echo -e "${BLUE}Iniciando demostración completa...${RESET}"
    echo ""
    
    # 1. Detección de hardware
    demo_hardware_detection
    
    # 2. Progress bars
    demo_progress_bars
    
    # 3. Sistema de rollback
    demo_rollback_system
    
    # 4. Gestor de dependencias
    demo_dependency_manager
    
    # 5. Post-instalación
    demo_post_installation
    
    # 6. Mantenimiento
    demo_maintenance_system
    
    echo -e "${GREEN}=== Demostración Completa Finalizada ===${RESET}"
    echo ""
    echo -e "${BLUE}Archivos de reporte generados:${RESET}"
    echo "  • /tmp/demo_deps_report.txt"
    echo "  • /tmp/demo_post_install_report.txt"
    echo "  • /tmp/demo_health_report.txt"
    echo "  • /tmp/demo_update_report.txt"
    echo "  • /tmp/demo_cleanup_report.txt"
    echo ""
    echo -e "${YELLOW}Estos archivos contienen información detallada de cada sistema.${RESET}"
}

# Función principal
main() {
    # Inicializar logger
    init_logger
    
    # Mostrar menú de demostración
    show_demo_menu
}

# Ejecutar si se llama directamente
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main "$@"
fi 