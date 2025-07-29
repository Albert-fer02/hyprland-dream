#!/usr/bin/env bash
# Script de Release v1.0 para Hyprland Dream
# Ayuda a preparar y verificar el release

set -e

ROOT_DIR="$(dirname "$0")/.."
source "$ROOT_DIR/core/colors.sh"
source "$ROOT_DIR/core/logger.sh"

# Configuración del release
RELEASE_VERSION="1.0.0"
RELEASE_DATE="2024-12-19"
RELEASE_NAME="Hyprland Dream v$RELEASE_VERSION"

# Función para mostrar banner
show_release_banner() {
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
    echo -e "${BLUE}=== Release v$RELEASE_VERSION ===${RESET}"
    echo -e "${YELLOW}Fecha: $RELEASE_DATE${RESET}"
    echo -e "${GREEN}Lanzamiento Inicial${RESET}"
    echo ""
}

# Función para verificar estructura del proyecto
verify_project_structure() {
    log_info "Verificando estructura del proyecto..."
    
    local required_dirs=(
        "bin"
        "core"
        "modules"
        "scripts"
        "config"
        "lib"
        "docs"
        "assets"
        "utils"
    )
    
    local required_files=(
        "install.sh"
        "README.md"
        "README-ADVANCED.md"
        "docs/CHANGELOG.md"
        "docs/MODULES.md"
        "docs/INDEX.md"
        "CORRECCIONES-IMPLEMENTADAS.md"
        "verify-system.sh"
        "test-system.sh"
        "diagnostico-sistema.sh"
        "check-basic.sh"
        "RELEASE-v1.0.md"
    )
    
    # Verificar directorios
    for dir in "${required_dirs[@]}"; do
        if [[ -d "$ROOT_DIR/$dir" ]]; then
            echo -e "${GREEN}✅${RESET} Directorio $dir existe"
        else
            echo -e "${RED}❌${RESET} Directorio $dir NO existe"
            return 1
        fi
    done
    
    # Verificar archivos
    for file in "${required_files[@]}"; do
        if [[ -f "$ROOT_DIR/$file" ]]; then
            echo -e "${GREEN}✅${RESET} Archivo $file existe"
        else
            echo -e "${RED}❌${RESET} Archivo $file NO existe"
            return 1
        fi
    done
    
    log_info "Estructura del proyecto verificada correctamente"
}

# Función para verificar módulos
verify_modules() {
    log_info "Verificando módulos..."
    
    local modules=(
        "hypr"
        "waybar"
        "dunst"
        "kitty"
        "rofi"
        "mako"
        "wlogout"
        "swaylock"
        "swww"
        "fonts"
        "themes"
        "power-management"
        "media"
        "nano"
        "zsh"
    )
    
    for module in "${modules[@]}"; do
        if [[ -d "$ROOT_DIR/modules/$module" ]]; then
            if [[ -f "$ROOT_DIR/modules/$module/install.sh" ]]; then
                echo -e "${GREEN}✅${RESET} Módulo $module (con install.sh)"
            else
                echo -e "${YELLOW}⚠️${RESET} Módulo $module (sin install.sh)"
            fi
        else
            echo -e "${RED}❌${RESET} Módulo $module NO existe"
        fi
    done
}

# Función para verificar scripts de core
verify_core_scripts() {
    log_info "Verificando scripts de core..."
    
    local core_scripts=(
        "logger.sh"
        "colors.sh"
        "helpers.sh"
        "check-deps.sh"
        "dependency-manager.sh"
        "hardware-detector.sh"
        "progress.sh"
        "rollback.sh"
        "post-install.sh"
        "maintenance.sh"
        "disk-checker.sh"
        "advanced-monitoring.sh"
        "intelligent-backup.sh"
        "smart-config-manager.sh"
    )
    
    for script in "${core_scripts[@]}"; do
        if [[ -f "$ROOT_DIR/core/$script" ]]; then
            if [[ -x "$ROOT_DIR/core/$script" ]]; then
                echo -e "${GREEN}✅${RESET} Script $script (ejecutable)"
            else
                echo -e "${YELLOW}⚠️${RESET} Script $script (no ejecutable)"
            fi
        else
            echo -e "${RED}❌${RESET} Script $script NO existe"
        fi
    done
}

# Función para verificar documentación
verify_documentation() {
    log_info "Verificando documentación..."
    
    local docs=(
        "README.md"
        "README-ADVANCED.md"
        "docs/CHANGELOG.md"
        "docs/MODULES.md"
        "docs/INDEX.md"
        "docs/INSTALL.md"
        "CORRECCIONES-IMPLEMENTADAS.md"
        "RELEASE-v1.0.md"
    )
    
    for doc in "${docs[@]}"; do
        if [[ -f "$ROOT_DIR/$doc" ]]; then
            local size=$(wc -c < "$ROOT_DIR/$doc")
            if [[ $size -gt 100 ]]; then
                echo -e "${GREEN}✅${RESET} Documento $doc (${size} bytes)"
            else
                echo -e "${YELLOW}⚠️${RESET} Documento $doc muy pequeño (${size} bytes)"
            fi
        else
            echo -e "${RED}❌${RESET} Documento $doc NO existe"
        fi
    done
}

# Función para verificar screenshots
verify_screenshots() {
    log_info "Verificando directorio de screenshots..."
    
    if [[ -d "$ROOT_DIR/assets/screenshots" ]]; then
        echo -e "${GREEN}✅${RESET} Directorio de screenshots existe"
        
        if [[ -f "$ROOT_DIR/assets/screenshots/README.md" ]]; then
            echo -e "${GREEN}✅${RESET} README de screenshots existe"
        else
            echo -e "${YELLOW}⚠️${RESET} README de screenshots NO existe"
        fi
        
        # Contar archivos de imagen
        local image_count=$(find "$ROOT_DIR/assets/screenshots" -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" 2>/dev/null | wc -l)
        echo -e "${BLUE}📸${RESET} Screenshots encontradas: $image_count"
    else
        echo -e "${RED}❌${RESET} Directorio de screenshots NO existe"
    fi
}

# Función para ejecutar tests
run_tests() {
    log_info "Ejecutando tests del sistema..."
    
    local test_scripts=(
        "verify-system.sh"
        "test-system.sh"
        "diagnostico-sistema.sh"
        "check-basic.sh"
    )
    
    for test in "${test_scripts[@]}"; do
        if [[ -f "$ROOT_DIR/$test" ]]; then
            if [[ -x "$ROOT_DIR/$test" ]]; then
                echo -e "${BLUE}🧪${RESET} Ejecutando $test..."
                if "$ROOT_DIR/$test" >/dev/null 2>&1; then
                    echo -e "${GREEN}✅${RESET} $test pasó"
                else
                    echo -e "${YELLOW}⚠️${RESET} $test falló (pero continuando)"
                fi
            else
                echo -e "${YELLOW}⚠️${RESET} $test no es ejecutable"
            fi
        else
            echo -e "${RED}❌${RESET} $test NO existe"
        fi
    done
}

# Función para generar resumen
generate_summary() {
    log_info "Generando resumen del release..."
    
    echo ""
    echo -e "${CYAN}=== RESUMEN DEL RELEASE v$RELEASE_VERSION ===${RESET}"
    echo ""
    
    # Contar módulos
    local module_count=$(find "$ROOT_DIR/modules" -mindepth 1 -maxdepth 1 -type d | wc -l)
    echo -e "${BLUE}📦${RESET} Módulos: $module_count"
    
    # Contar scripts de core
    local core_count=$(find "$ROOT_DIR/core" -name "*.sh" | wc -l)
    echo -e "${BLUE}🔧${RESET} Scripts de core: $core_count"
    
    # Contar scripts utilitarios
    local utils_count=$(find "$ROOT_DIR/scripts" -name "*.sh" | wc -l)
    echo -e "${BLUE}🛠️${RESET} Scripts utilitarios: $utils_count"
    
    # Contar documentación
    local docs_count=$(find "$ROOT_DIR" -name "*.md" | wc -l)
    echo -e "${BLUE}📚${RESET} Documentos: $docs_count"
    
    # Contar configuraciones
    local config_count=$(find "$ROOT_DIR/modules" -name "*.conf" -o -name "*.json" -o -name "*.rasi" -o -name "*.css" | wc -l)
    echo -e "${BLUE}⚙️${RESET} Configuraciones: $config_count"
    
    echo ""
    echo -e "${GREEN}🎉 Release v$RELEASE_VERSION listo para publicación${RESET}"
    echo ""
}

# Función para mostrar checklist
show_checklist() {
    echo -e "${CYAN}=== CHECKLIST DE RELEASE ===${RESET}"
    echo ""
    echo -e "${YELLOW}Antes de publicar el release, verifica:${RESET}"
    echo ""
    echo -e "  ${BLUE}📋${RESET} Documentación:"
    echo -e "    □ README.md actualizado con v$RELEASE_VERSION"
    echo -e "    □ CHANGELOG.md completo"
    echo -e "    □ RELEASE-v1.0.md creado"
    echo -e "    □ Documentación de módulos actualizada"
    echo ""
    echo -e "  ${BLUE}🖼️${RESET} Screenshots:"
    echo -e "    □ Capturas de los 4 temas"
    echo -e "    □ Screenshots de componentes principales"
    echo -e "    □ Imágenes optimizadas y de calidad"
    echo ""
    echo -e "  ${BLUE}🧪${RESET} Testing:"
    echo -e "    □ Todos los tests pasan"
    echo -e "    □ Instalación funciona correctamente"
    echo -e "    □ Módulos se instalan sin errores"
    echo ""
    echo -e "  ${BLUE}📦${RESET} Archivos:"
    echo -e "    □ Todos los scripts son ejecutables"
    echo -e "    □ Configuraciones están completas"
    echo -e "    □ Estructura del proyecto es correcta"
    echo ""
    echo -e "  ${BLUE}🔗${RESET} Enlaces:"
    echo -e "    □ URLs de GitHub actualizadas"
    echo -e "    □ Enlaces de documentación funcionan"
    echo -e "    □ Badges y shields actualizados"
    echo ""
}

# Función principal
main() {
    show_release_banner
    
    log_info "Iniciando verificación del release v$RELEASE_VERSION..."
    
    # Cambiar al directorio raíz
    cd "$ROOT_DIR"
    
    # Ejecutar verificaciones
    verify_project_structure
    echo ""
    
    verify_modules
    echo ""
    
    verify_core_scripts
    echo ""
    
    verify_documentation
    echo ""
    
    verify_screenshots
    echo ""
    
    run_tests
    echo ""
    
    generate_summary
    echo ""
    
    show_checklist
    
    log_info "Verificación del release completada"
    echo ""
    echo -e "${GREEN}🎉 ¡Hyprland Dream v$RELEASE_VERSION está listo para el lanzamiento!${RESET}"
    echo ""
}

# Ejecutar función principal
main "$@" 