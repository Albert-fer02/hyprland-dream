#!/usr/bin/env bash
# Script de prueba rápida para el sistema de instalación avanzado
# Verifica que todos los componentes funcionen correctamente

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
    echo -e "${CYAN}=== Pruebas del Sistema de Instalación Avanzado ===${RESET}"
    echo ""
    
    # Prueba 1: Verificar que estamos en Arch Linux
    run_test "Arch Linux Detection" \
        "grep -qi arch /etc/os-release" \
        "Verificar que el sistema es Arch Linux"
    
    # Prueba 2: Verificar scripts principales
    run_test "Install Script" \
        "[[ -x $ROOT_DIR/install.sh ]]" \
        "Verificar que install.sh existe y es ejecutable"
    
    run_test "Demo Script" \
        "[[ -x $ROOT_DIR/demo-advanced.sh ]]" \
        "Verificar que demo-advanced.sh existe y es ejecutable"
    
    # Prueba 3: Verificar scripts del core
    run_test "Hardware Detector" \
        "[[ -x $ROOT_DIR/core/hardware-detector.sh ]]" \
        "Verificar que hardware-detector.sh existe y es ejecutable"
    
    run_test "Progress System" \
        "[[ -x $ROOT_DIR/core/progress.sh ]]" \
        "Verificar que progress.sh existe y es ejecutable"
    
    run_test "Rollback System" \
        "[[ -x $ROOT_DIR/core/rollback.sh ]]" \
        "Verificar que rollback.sh existe y es ejecutable"
    
    run_test "Dependency Manager" \
        "[[ -x $ROOT_DIR/core/dependency-manager.sh ]]" \
        "Verificar que dependency-manager.sh existe y es ejecutable"
    
    run_test "Post Install" \
        "[[ -x $ROOT_DIR/core/post-install.sh ]]" \
        "Verificar que post-install.sh existe y es ejecutable"
    
    run_test "Maintenance System" \
        "[[ -x $ROOT_DIR/core/maintenance.sh ]]" \
        "Verificar que maintenance.sh existe y es ejecutable"
    
    # Prueba 4: Verificar dependencias básicas
    run_test "Bash Availability" \
        "command -v bash >/dev/null" \
        "Verificar que bash está disponible"
    
    run_test "Sudo Availability" \
        "command -v sudo >/dev/null" \
        "Verificar que sudo está disponible"
    
    run_test "Pacman Availability" \
        "command -v pacman >/dev/null" \
        "Verificar que pacman está disponible"
    
    # Prueba 5: Verificar directorios necesarios
    run_test "Core Directory" \
        "[[ -d $ROOT_DIR/core ]]" \
        "Verificar que el directorio core existe"
    
    run_test "Modules Directory" \
        "[[ -d $ROOT_DIR/modules ]]" \
        "Verificar que el directorio modules existe"
    
    run_test "Lib Directory" \
        "[[ -d $ROOT_DIR/lib ]]" \
        "Verificar que el directorio lib existe"
    
    # Prueba 6: Verificar archivos de configuración
    run_test "Colors Script" \
        "[[ -f $ROOT_DIR/core/colors.sh ]]" \
        "Verificar que colors.sh existe"
    
    run_test "Logger Script" \
        "[[ -f $ROOT_DIR/core/logger.sh ]]" \
        "Verificar que logger.sh existe"
    
    run_test "Utils Script" \
        "[[ -f $ROOT_DIR/lib/utils.sh ]]" \
        "Verificar que utils.sh existe"
    
    # Prueba 7: Verificar módulos básicos
    run_test "Hypr Module" \
        "[[ -d $ROOT_DIR/modules/hypr ]]" \
        "Verificar que el módulo hypr existe"
    
    run_test "Waybar Module" \
        "[[ -d $ROOT_DIR/modules/waybar ]]" \
        "Verificar que el módulo waybar existe"
    
    run_test "Dunst Module" \
        "[[ -d $ROOT_DIR/modules/dunst ]]" \
        "Verificar que el módulo dunst existe"
    
    # Prueba 8: Verificar permisos de escritura
    run_test "Write Permissions" \
        "[[ -w $ROOT_DIR ]]" \
        "Verificar permisos de escritura en el directorio raíz"
    
    run_test "Temp Directory" \
        "[[ -w /tmp ]]" \
        "Verificar permisos de escritura en /tmp"
    
    # Prueba 9: Verificar funciones básicas
    run_test "Logger Initialization" \
        "source $ROOT_DIR/core/logger.sh && init_logger" \
        "Verificar inicialización del logger"
    
    run_test "Hardware Detection Function" \
        "source $ROOT_DIR/core/hardware-detector.sh && declare -F detect_hardware >/dev/null" \
        "Verificar que la función detect_hardware existe"
    
    run_test "Progress System Function" \
        "source $ROOT_DIR/core/progress.sh && declare -F init_progress >/dev/null" \
        "Verificar que la función init_progress existe"
    
    # Prueba 10: Verificar integración básica
    run_test "Module Detection" \
        "source $ROOT_DIR/install.sh && declare -F get_modules >/dev/null" \
        "Verificar que la función get_modules existe"
    
    # Mostrar resumen
    show_test_summary
}

# Ejecutar pruebas
main "$@" 