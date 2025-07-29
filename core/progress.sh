#!/usr/bin/env bash
# Sistema de progress bars visuales para hyprdream
# Proporciona barras de progreso atractivas para la instalación

source "$(dirname "$0")/colors.sh"
source "$(dirname "$0")/logger.sh"

# Configuración de progress bars
PROGRESS_WIDTH="${PROGRESS_WIDTH:-50}"
PROGRESS_CHAR="${PROGRESS_CHAR:-█}"
PROGRESS_EMPTY_CHAR="${PROGRESS_EMPTY_CHAR:-░}"
PROGRESS_STYLE="${PROGRESS_STYLE:-block}"  # block, arrow, dots

# Variables globales
declare -A PROGRESS_BARS=()
declare -A PROGRESS_STEPS=()
declare -A PROGRESS_CURRENT=()

# Función para inicializar una progress bar
init_progress() {
    local id="$1"
    local total_steps="$2"
    local description="${3:-Progreso}"
    
    PROGRESS_BARS["$id"]="$total_steps"
    PROGRESS_STEPS["$id"]="$description"
    PROGRESS_CURRENT["$id"]="0"
    
    log_debug "Progress bar inicializada: $id ($total_steps pasos)"
}

# Función para actualizar una progress bar
update_progress() {
    local id="$1"
    local current="$2"
    local message="${3:-}"
    
    if [[ -z "${PROGRESS_BARS[$id]}" ]]; then
        log_warn "Progress bar no inicializada: $id"
        return 1
    fi
    
    local total="${PROGRESS_BARS[$id]}"
    local description="${PROGRESS_STEPS[$id]}"
    
    # Actualizar contador
    PROGRESS_CURRENT["$id"]="$current"
    
    # Calcular porcentaje
    local percentage=$((current * 100 / total))
    
    # Calcular barras completadas
    local filled=$((current * PROGRESS_WIDTH / total))
    local empty=$((PROGRESS_WIDTH - filled))
    
    # Construir la barra
    local bar=""
    case "$PROGRESS_STYLE" in
        "block")
            bar=$(printf "%${filled}s" | tr ' ' "$PROGRESS_CHAR")
            bar+=$(printf "%${empty}s" | tr ' ' "$PROGRESS_EMPTY_CHAR")
            ;;
        "arrow")
            bar=$(printf "%${filled}s" | tr ' ' ">")
            bar+=$(printf "%${empty}s" | tr ' ' "-")
            ;;
        "dots")
            bar=$(printf "%${filled}s" | tr ' ' "●")
            bar+=$(printf "%${empty}s" | tr ' ' "○")
            ;;
    esac
    
    # Mostrar progress bar
    printf "\r${CYAN}[${RESET}%s${CYAN}]${RESET} %s [%s] %d%% %s" \
        "$description" "$bar" "$current/$total" "$percentage" "$message"
    
    # Nueva línea si está completo
    if [[ $current -eq $total ]]; then
        echo ""
        log_info "Progress bar completada: $id"
    fi
}

# Función para incrementar una progress bar
increment_progress() {
    local id="$1"
    local message="${2:-}"
    
    local current="${PROGRESS_CURRENT[$id]}"
    local new_current=$((current + 1))
    
    update_progress "$id" "$new_current" "$message"
}

# Función para mostrar progress bar de descarga
show_download_progress() {
    local url="$1"
    local filename="$2"
    local total_size="$3"
    
    echo -e "${BLUE}Descargando:${RESET} $filename"
    
    # Usar wget con progress bar si está disponible
    if command -v wget &>/dev/null; then
        wget --progress=bar:force:noscroll -O "$filename" "$url" 2>&1 | \
        while read -r line; do
            if [[ "$line" =~ ([0-9]+%) ]]; then
                local percentage="${BASH_REMATCH[1]}"
                printf "\r${CYAN}Progreso:${RESET} %s" "$percentage"
            fi
        done
        echo ""
    else
        # Fallback con curl
        curl -L -o "$filename" "$url" --progress-bar
    fi
    
    log_info "Descarga completada: $filename"
}

# Función para mostrar progress bar de instalación de paquetes
show_package_install_progress() {
    local packages=("$@")
    local total=${#packages[@]}
    
    echo -e "${BLUE}Instalando paquetes...${RESET}"
    init_progress "package_install" "$total" "Instalación"
    
    for i in "${!packages[@]}"; do
        local package="${packages[$i]}"
        local current=$((i + 1))
        
        update_progress "package_install" "$current" "Instalando $package"
        
        # Simular instalación (aquí iría la instalación real)
        sleep 0.1
    done
    
    echo -e "${GREEN}✓ Instalación de paquetes completada${RESET}"
}

# Función para mostrar progress bar de configuración
show_config_progress() {
    local configs=("$@")
    local total=${#configs[@]}
    
    echo -e "${BLUE}Configurando sistema...${RESET}"
    init_progress "config_setup" "$total" "Configuración"
    
    for i in "${!configs[@]}"; do
        local config="${configs[$i]}"
        local current=$((i + 1))
        
        update_progress "config_setup" "$current" "Configurando $config"
        
        # Simular configuración
        sleep 0.1
    done
    
    echo -e "${GREEN}✓ Configuración completada${RESET}"
}

# Función para mostrar progress bar de verificación
show_verification_progress() {
    local checks=("$@")
    local total=${#checks[@]}
    
    echo -e "${BLUE}Verificando sistema...${RESET}"
    init_progress "system_verify" "$total" "Verificación"
    
    for i in "${!checks[@]}"; do
        local check="${checks[$i]}"
        local current=$((i + 1))
        
        update_progress "system_verify" "$current" "Verificando $check"
        
        # Simular verificación
        sleep 0.1
    done
    
    echo -e "${GREEN}✓ Verificación completada${RESET}"
}

# Función para mostrar progress bar de backup
show_backup_progress() {
    local files=("$@")
    local total=${#files[@]}
    
    echo -e "${BLUE}Creando backup...${RESET}"
    init_progress "backup" "$total" "Backup"
    
    for i in "${!files[@]}"; do
        local file="${files[$i]}"
        local current=$((i + 1))
        
        update_progress "backup" "$current" "Backup de $file"
        
        # Simular backup
        sleep 0.1
    done
    
    echo -e "${GREEN}✓ Backup completado${RESET}"
}

# Función para mostrar progress bar de cleanup
show_cleanup_progress() {
    local items=("$@")
    local total=${#items[@]}
    
    echo -e "${BLUE}Limpiando archivos temporales...${RESET}"
    init_progress "cleanup" "$total" "Limpieza"
    
    for i in "${!items[@]}"; do
        local item="${items[$i]}"
        local current=$((i + 1))
        
        update_progress "cleanup" "$current" "Limpiando $item"
        
        # Simular limpieza
        sleep 0.1
    done
    
    echo -e "${GREEN}✓ Limpieza completada${RESET}"
}

# Función para mostrar progress bar de módulos
show_module_progress() {
    local modules=("$@")
    local total=${#modules[@]}
    
    echo -e "${BLUE}Instalando módulos...${RESET}"
    init_progress "module_install" "$total" "Módulos"
    
    for i in "${!modules[@]}"; do
        local module="${modules[$i]}"
        local current=$((i + 1))
        
        update_progress "module_install" "$current" "Instalando $module"
        
        # Aquí se ejecutaría la instalación real del módulo
        # install_module "$module"
        
        # Simular instalación
        sleep 0.2
    done
    
    echo -e "${GREEN}✓ Instalación de módulos completada${RESET}"
}

# Función para mostrar progress bar de servicios systemd
show_service_progress() {
    local services=("$@")
    local total=${#services[@]}
    
    echo -e "${BLUE}Configurando servicios systemd...${RESET}"
    init_progress "service_setup" "$total" "Servicios"
    
    for i in "${!services[@]}"; do
        local service="${services[$i]}"
        local current=$((i + 1))
        
        update_progress "service_setup" "$current" "Configurando $service"
        
        # Simular configuración de servicio
        sleep 0.1
    done
    
    echo -e "${GREEN}✓ Configuración de servicios completada${RESET}"
}

# Función para mostrar progress bar de permisos
show_permissions_progress() {
    local files=("$@")
    local total=${#files[@]}
    
    echo -e "${BLUE}Ajustando permisos...${RESET}"
    init_progress "permissions" "$total" "Permisos"
    
    for i in "${!files[@]}"; do
        local file="${files[$i]}"
        local current=$((i + 1))
        
        update_progress "permissions" "$current" "Ajustando $file"
        
        # Simular ajuste de permisos
        sleep 0.05
    done
    
    echo -e "${GREEN}✓ Permisos ajustados${RESET}"
}

# Función para mostrar progress bar de validación
show_validation_progress() {
    local validations=("$@")
    local total=${#validations[@]}
    
    echo -e "${BLUE}Validando instalación...${RESET}"
    init_progress "validation" "$total" "Validación"
    
    for i in "${!validations[@]}"; do
        local validation="${validations[$i]}"
        local current=$((i + 1))
        
        update_progress "validation" "$current" "Validando $validation"
        
        # Simular validación
        sleep 0.1
    done
    
    echo -e "${GREEN}✓ Validación completada${RESET}"
}

# Función para mostrar progress bar de optimización
show_optimization_progress() {
    local optimizations=("$@")
    local total=${#optimizations[@]}
    
    echo -e "${BLUE}Optimizando sistema...${RESET}"
    init_progress "optimization" "$total" "Optimización"
    
    for i in "${!optimizations[@]}"; do
        local optimization="${optimizations[$i]}"
        local current=$((i + 1))
        
        update_progress "optimization" "$current" "Optimizando $optimization"
        
        # Simular optimización
        sleep 0.15
    done
    
    echo -e "${GREEN}✓ Optimización completada${RESET}"
}

# Función para mostrar progress bar de finalización
show_finalization_progress() {
    local steps=("$@")
    local total=${#steps[@]}
    
    echo -e "${BLUE}Finalizando instalación...${RESET}"
    init_progress "finalization" "$total" "Finalización"
    
    for i in "${!steps[@]}"; do
        local step="${steps[$i]}"
        local current=$((i + 1))
        
        update_progress "finalization" "$current" "$step"
        
        # Simular paso de finalización
        sleep 0.1
    done
    
    echo -e "${GREEN}✓ Instalación finalizada exitosamente${RESET}"
}

# Función para mostrar progress bar de rollback
show_rollback_progress() {
    local steps=("$@")
    local total=${#steps[@]}
    
    echo -e "${RED}Ejecutando rollback...${RESET}"
    init_progress "rollback" "$total" "Rollback"
    
    for i in "${!steps[@]}"; do
        local step="${steps[$i]}"
        local current=$((i + 1))
        
        update_progress "rollback" "$current" "$step"
        
        # Simular rollback
        sleep 0.1
    done
    
    echo -e "${YELLOW}⚠ Rollback completado${RESET}"
}

# Función para limpiar progress bars
cleanup_progress() {
    unset PROGRESS_BARS
    unset PROGRESS_STEPS
    unset PROGRESS_CURRENT
    log_debug "Progress bars limpiadas"
}

# Ejecutar si se llama directamente
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    init_logger
    
    case "${1:-demo}" in
        "demo")
            echo -e "${CYAN}=== Demo de Progress Bars ===${RESET}"
            
            # Demo de instalación de paquetes
            show_package_install_progress "hyprland" "waybar" "dunst" "kitty"
            
            # Demo de configuración
            show_config_progress "hyprland.conf" "waybar.css" "dunst.conf"
            
            # Demo de verificación
            show_verification_progress "dependencias" "configuraciones" "servicios"
            
            # Demo de finalización
            show_finalization_progress "Creando shortcuts" "Configurando variables" "Iniciando servicios"
            ;;
        "test")
            # Test simple
            init_progress "test" "10" "Test"
            for i in {1..10}; do
                update_progress "test" "$i" "Paso $i"
                sleep 0.2
            done
            ;;
        *)
            echo "Uso: $0 [demo|test]"
            ;;
    esac
fi 