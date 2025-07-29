#!/usr/bin/env bash
# Verificador de espacio en disco para hyprdream
# Previene errores por falta de espacio durante la instalación

source "$(dirname "$0")/colors.sh"
source "$(dirname "$0")/logger.sh"

# Configuración
MIN_REQUIRED_SPACE_MB=5000  # 5GB mínimo
RECOMMENDED_SPACE_MB=10000  # 10GB recomendado
CACHE_SPACE_MB=2000         # 2GB para cache

# Función para verificar espacio en disco
check_disk_space() {
    local mount_point="${1:-/}"
    local required_space_mb="${2:-$MIN_REQUIRED_SPACE_MB}"
    
    log_info "Verificando espacio en disco en $mount_point..."
    
    # Obtener espacio disponible
    local available_space_mb=0
    if command -v df &>/dev/null; then
        available_space_mb=$(df "$mount_point" | awk 'NR==2 {print $4}')
        available_space_mb=$((available_space_mb / 1024))  # Convertir a MB
    else
        log_error "Comando 'df' no disponible"
        return 1
    fi
    
    log_info "Espacio disponible: ${available_space_mb}MB"
    log_info "Espacio requerido: ${required_space_mb}MB"
    
    # Verificar si hay suficiente espacio
    if [[ $available_space_mb -lt $required_space_mb ]]; then
        log_error "Espacio insuficiente en $mount_point"
        log_error "Disponible: ${available_space_mb}MB, Requerido: ${required_space_mb}MB"
        return 1
    fi
    
    # Verificar espacio recomendado
    if [[ $available_space_mb -lt $RECOMMENDED_SPACE_MB ]]; then
        log_warn "Espacio bajo en $mount_point"
        log_warn "Disponible: ${available_space_mb}MB, Recomendado: ${RECOMMENDED_SPACE_MB}MB"
    fi
    
    log_info "Verificación de espacio completada: OK"
    return 0
}

# Función para verificar espacio en directorios específicos
check_specific_directories() {
    local directories=("/tmp" "/var/cache" "/home/$USER")
    local total_required_mb=0
    
    log_info "Verificando espacio en directorios específicos..."
    
    for dir in "${directories[@]}"; do
        if [[ -d "$dir" ]]; then
            local available_mb=$(df "$dir" | awk 'NR==2 {print $4}')
            available_mb=$((available_mb / 1024))
            
            log_info "Directorio $dir: ${available_mb}MB disponible"
            
            # Verificar permisos de escritura
            if [[ -w "$dir" ]]; then
                log_info "  ✓ Permisos de escritura OK"
            else
                log_warn "  ⚠ Sin permisos de escritura"
            fi
        else
            log_warn "Directorio no existe: $dir"
        fi
    done
}

# Función para limpiar espacio automáticamente
cleanup_disk_space() {
    local target_space_mb="${1:-$MIN_REQUIRED_SPACE_MB}"
    
    log_info "Iniciando limpieza automática de espacio..."
    
    local freed_space_mb=0
    
    # Limpiar cache de pacman
    if command -v pacman &>/dev/null; then
        log_info "Limpiando cache de pacman..."
        local pacman_cache_size=$(du -sm /var/cache/pacman/pkg 2>/dev/null | cut -f1 || echo "0")
        sudo pacman -Sc --noconfirm &>/dev/null
        log_info "Cache de pacman limpiado (liberado ~${pacman_cache_size}MB)"
        freed_space_mb=$((freed_space_mb + pacman_cache_size))
    fi
    
    # Limpiar logs del sistema
    if command -v journalctl &>/dev/null; then
        log_info "Limpiando logs del sistema..."
        local logs_size=$(du -sm /var/log/journal 2>/dev/null | cut -f1 || echo "0")
        sudo journalctl --vacuum-time=3d &>/dev/null
        log_info "Logs del sistema limpiados (liberado ~${logs_size}MB)"
        freed_space_mb=$((freed_space_mb + logs_size))
    fi
    
    # Limpiar cache de AUR helpers
    for helper_cache in "/var/cache/paru" "/var/cache/yay"; do
        if [[ -d "$helper_cache" ]]; then
            local cache_size=$(du -sm "$helper_cache" 2>/dev/null | cut -f1 || echo "0")
            sudo rm -rf "$helper_cache"/* &>/dev/null
            log_info "Cache de $(basename "$helper_cache") limpiado (liberado ~${cache_size}MB)"
            freed_space_mb=$((freed_space_mb + cache_size))
        fi
    done
    
    # Limpiar archivos temporales
    local tmp_size=$(du -sm /tmp 2>/dev/null | cut -f1 || echo "0")
    sudo find /tmp -type f -atime +7 -delete &>/dev/null
    log_info "Archivos temporales antiguos eliminados (liberado ~${tmp_size}MB)"
    
    log_info "Limpieza completada. Espacio liberado: ~${freed_space_mb}MB"
    return 0
}

# Función para mostrar recomendaciones de limpieza
show_cleanup_recommendations() {
    echo -e "\n${YELLOW}=== RECOMENDACIONES DE LIMPIEZA ===${RESET}"
    echo ""
    echo "1. Limpiar cache de paquetes:"
    echo "   sudo pacman -Sc"
    echo ""
    echo "2. Limpiar logs del sistema:"
    echo "   sudo journalctl --vacuum-time=3d"
    echo ""
    echo "3. Limpiar cache de AUR helpers:"
    echo "   sudo rm -rf /var/cache/paru/*"
    echo "   sudo rm -rf /var/cache/yay/*"
    echo ""
    echo "4. Eliminar paquetes huérfanos:"
    echo "   sudo pacman -Rns \$(pacman -Qtdq)"
    echo ""
    echo "5. Limpiar archivos temporales:"
    echo "   sudo find /tmp -type f -atime +7 -delete"
    echo ""
}

# Función para verificación completa de espacio
verify_disk_space() {
    local auto_cleanup="${1:-false}"
    
    log_info "Iniciando verificación completa de espacio en disco..."
    
    # Verificar espacio principal
    if ! check_disk_space "/" "$MIN_REQUIRED_SPACE_MB"; then
        log_error "Verificación de espacio falló"
        
        if [[ "$auto_cleanup" == "true" ]]; then
            log_info "Intentando limpieza automática..."
            cleanup_disk_space
            check_disk_space "/" "$MIN_REQUIRED_SPACE_MB"
        else
            show_cleanup_recommendations
            return 1
        fi
    fi
    
    # Verificar directorios específicos
    check_specific_directories
    
    log_info "Verificación de espacio completada exitosamente"
    return 0
}

# Función para monitorear espacio durante la instalación
monitor_disk_space() {
    local mount_point="${1:-/}"
    local threshold_mb="${2:-1000}"  # Alertar cuando queden menos de 1GB
    
    while true; do
        local available_mb=$(df "$mount_point" | awk 'NR==2 {print $4}')
        available_mb=$((available_mb / 1024))
        
        if [[ $available_mb -lt $threshold_mb ]]; then
            log_warn "¡ADVERTENCIA! Espacio bajo: ${available_mb}MB disponible"
            return 1
        fi
        
        sleep 30  # Verificar cada 30 segundos
    done
}

# Ejecutar si se llama directamente
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    init_logger
    
    case "${1:-check}" in
        "check")
            verify_disk_space
            ;;
        "cleanup")
            cleanup_disk_space
            ;;
        "monitor")
            monitor_disk_space
            ;;
        *)
            echo "Uso: $0 [check|cleanup|monitor]"
            ;;
    esac
fi 