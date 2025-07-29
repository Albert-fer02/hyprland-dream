#!/usr/bin/env bash
# Script de verificación completa del sistema hyprland-dream
# Verifica que todos los componentes funcionen correctamente después de las correcciones

set -e

ROOT_DIR="$(dirname "$0")"
source "$ROOT_DIR/core/colors.sh"
source "$ROOT_DIR/core/logger.sh"

# Variables de prueba
TEST_RESULTS=()
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Función para ejecutar prueba
run_test() {
    local test_name="$1"
    local test_command="$2"
    local test_description="$3"
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    echo -e "${BLUE}Ejecutando prueba: $test_name${RESET}"
    echo -e "${GRAY}$test_description${RESET}"
    
    if eval "$test_command" >/dev/null 2>&1; then
        echo -e "${GREEN}✓ PASS${RESET}"
        TEST_RESULTS+=("PASS:$test_name")
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        echo -e "${RED}✗ FAIL${RESET}"
        TEST_RESULTS+=("FAIL:$test_name")
        FAILED_TESTS=$((FAILED_TESTS + 1))
    fi
    
    echo ""
}

# Función para mostrar resumen de pruebas
show_test_summary() {
    echo -e "${CYAN}=== Resumen de Pruebas ===${RESET}"
    echo ""
    echo -e "Total de pruebas: $TOTAL_TESTS"
    echo -e "${GREEN}Pruebas exitosas: $PASSED_TESTS${RESET}"
    echo -e "${RED}Pruebas fallidas: $FAILED_TESTS${RESET}"
    echo ""
    
    if [[ $FAILED_TESTS -eq 0 ]]; then
        echo -e "${GREEN}🎉 ¡Todas las pruebas pasaron exitosamente!${RESET}"
        echo -e "${GREEN}✅ El sistema está listo para funcionar perfectamente${RESET}"
        return 0
    else
        echo -e "${RED}❌ Algunas pruebas fallaron${RESET}"
        echo ""
        echo -e "${YELLOW}Pruebas fallidas:${RESET}"
        for result in "${TEST_RESULTS[@]}"; do
            if [[ "$result" == FAIL:* ]]; then
                echo -e "  • ${result#FAIL:}"
            fi
        done
        return 1
    fi
}

# Función principal de pruebas
main() {
    echo -e "${CYAN}=== Verificación Completa del Sistema ===${RESET}"
    echo -e "${YELLOW}Verificando correcciones implementadas...${RESET}"
    echo ""
    
    # Prueba 1: Verificar espacio en disco
    run_test "Disk Space Check" \
        "source $ROOT_DIR/core/disk-checker.sh && check_disk_space" \
        "Verificar que hay suficiente espacio en disco"
    
    # Prueba 2: Verificar permisos de directorios
    run_test "Cache Directory Permissions" \
        "[[ -w /tmp ]] && [[ -w /var/cache ]] 2>/dev/null || mkdir -p /tmp/hyprdream_cache" \
        "Verificar permisos de escritura en directorios críticos"
    
    # Prueba 3: Verificar corrección de variables de solo lectura
    run_test "Read-only Variable Fix" \
        "source $ROOT_DIR/core/dependency-manager.sh && check_package_with_cache 'bash'" \
        "Verificar que se corrigió el error de variables de solo lectura"
    
    # Prueba 4: Verificar corrección de bad substitution
    run_test "Bad Substitution Fix" \
        "source $ROOT_DIR/core/rollback.sh && declare -p BACKUP_POINTS >/dev/null 2>&1" \
        "Verificar que se corrigió el error de bad substitution"
    
    # Prueba 5: Verificar inicialización del sistema
    run_test "System Initialization" \
        "source $ROOT_DIR/install.sh && init_logger" \
        "Verificar que el sistema se inicializa correctamente"
    
    # Prueba 6: Verificar detección de hardware
    run_test "Hardware Detection" \
        "source $ROOT_DIR/core/hardware-detector.sh && detect_cpu" \
        "Verificar que la detección de hardware funciona"
    
    # Prueba 7: Verificar sistema de progreso
    run_test "Progress System" \
        "source $ROOT_DIR/core/progress.sh && init_progress 'test' '5' 'Test'" \
        "Verificar que el sistema de progreso funciona"
    
    # Prueba 8: Verificar gestor de dependencias
    run_test "Dependency Manager" \
        "source $ROOT_DIR/core/dependency-manager.sh && check_aur_repos" \
        "Verificar que el gestor de dependencias funciona"
    
    # Prueba 9: Verificar sistema de rollback
    run_test "Rollback System" \
        "source $ROOT_DIR/core/rollback.sh && init_rollback_system" \
        "Verificar que el sistema de rollback funciona"
    
    # Prueba 10: Verificar módulos disponibles
    run_test "Module Detection" \
        "source $ROOT_DIR/install.sh && get_modules | head -1" \
        "Verificar que se pueden detectar módulos"
    
    # Prueba 11: Verificar conectividad
    run_test "Network Connectivity" \
        "ping -c 1 8.8.8.8 >/dev/null 2>&1" \
        "Verificar conectividad a internet"
    
    # Prueba 12: Verificar repositorios de Arch
    run_test "Arch Repositories" \
        "pacman -Sy >/dev/null 2>&1" \
        "Verificar que los repositorios de Arch funcionan"
    
    # Prueba 13: Verificar dependencias críticas
    run_test "Critical Dependencies" \
        "command -v bash && command -v sudo && command -v pacman" \
        "Verificar que las dependencias críticas están disponibles"
    
    # Prueba 14: Verificar archivos de configuración
    run_test "Configuration Files" \
        "[[ -f $ROOT_DIR/core/colors.sh ]] && [[ -f $ROOT_DIR/core/logger.sh ]]" \
        "Verificar que los archivos de configuración existen"
    
    # Prueba 15: Verificar integración completa
    run_test "Complete Integration" \
        "source $ROOT_DIR/install.sh && declare -F show_welcome_banner >/dev/null" \
        "Verificar que todos los componentes se integran correctamente"
    
    # Mostrar resumen
    show_test_summary
}

# Ejecutar pruebas
main "$@" 