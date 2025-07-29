#!/usr/bin/env bash
# Sistema de mantenimiento para hyprdream
# Maneja auto-updates, backup automático, health checks y cleanup

source "$(dirname "$0")/colors.sh"
source "$(dirname "$0")/logger.sh"
source "$(dirname "$0")/progress.sh"

# Configuración
MAINTENANCE_DIR="${MAINTENANCE_DIR:-/var/lib/hyprdream/maintenance}"
BACKUP_DIR="${BACKUP_DIR:-$MAINTENANCE_DIR/backups}"
HEALTH_LOG="${HEALTH_LOG:-$MAINTENANCE_DIR/health.log}"
UPDATE_LOG="${UPDATE_LOG:-$MAINTENANCE_DIR/updates.log}"
CLEANUP_LOG="${CLEANUP_LOG:-$MAINTENANCE_DIR/cleanup.log}"

# Variables globales
declare -A HEALTH_STATUS=()
declare -A UPDATE_STATUS=()
declare -A BACKUP_STATUS=()

# Función para auto-updates de configuraciones
auto_update_configurations() {
    log_info "Iniciando auto-update de configuraciones..."
    
    # Crear backup antes de actualizar
    create_configuration_backup "pre_update"
    
    # Lista de configuraciones a actualizar
    local configs_to_update=(
        "hyprland"
        "waybar"
        "dunst"
        "kitty"
        "rofi"
        "swww"
        "wlogout"
    )
    
    # Mostrar progress bar
    show_config_progress "${configs_to_update[@]}"
    
    local update_count=0
    local error_count=0
    
    for i in "${!configs_to_update[@]}"; do
        local config="${configs_to_update[$i]}"
        local current=$((i + 1))
        
        log_info "Actualizando configuración $current/${#configs_to_update[@]}: $config"
        
        # Verificar si hay actualizaciones disponibles
        if check_config_updates "$config"; then
            # Actualizar configuración
            if update_configuration "$config"; then
                UPDATE_STATUS["$config"]="updated"
                update_count=$((update_count + 1))
                log_info "Configuración $config actualizada"
            else
                UPDATE_STATUS["$config"]="error"
                error_count=$((error_count + 1))
                log_error "Error al actualizar $config"
            fi
        else
            UPDATE_STATUS["$config"]="up_to_date"
            log_debug "Configuración $config ya está actualizada"
        fi
    done
    
    # Crear backup después de actualizar
    create_configuration_backup "post_update"
    
    log_info "Auto-update completado: $update_count actualizadas, $error_count errores"
    
    # Generar reporte de actualizaciones
    generate_update_report
}

# Función para verificar actualizaciones de configuración
check_config_updates() {
    local config="$1"
    local config_dir="$ROOT_DIR/modules/$config/config"
    local user_config_dir="$HOME/.config/$config"
    
    # Verificar si existe la configuración del usuario
    if [[ ! -d "$user_config_dir" ]]; then
        return 0  # Necesita actualización
    fi
    
    # Comparar fechas de modificación
    local module_mtime=$(stat -c%Y "$config_dir" 2>/dev/null || echo 0)
    local user_mtime=$(stat -c%Y "$user_config_dir" 2>/dev/null || echo 0)
    
    # Si la configuración del módulo es más reciente, necesita actualización
    [[ $module_mtime -gt $user_mtime ]]
}

# Función para actualizar configuración específica
update_configuration() {
    local config="$1"
    local config_dir="$ROOT_DIR/modules/$config/config"
    local user_config_dir="$HOME/.config/$config"
    
    # Crear directorio si no existe
    mkdir -p "$user_config_dir"
    
    # Copiar configuraciones actualizadas
    if [[ -d "$config_dir" ]]; then
        cp -ru "$config_dir/"* "$user_config_dir/" 2>/dev/null || return 1
        return 0
    fi
    
    return 1
}

# Función para backup automático antes de cambios
create_configuration_backup() {
    local backup_type="$1"
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_name="${backup_type}_${timestamp}"
    local backup_path="$BACKUP_DIR/$backup_name"
    
    log_info "Creando backup automático: $backup_name"
    
    # Crear directorio de backup
    mkdir -p "$backup_path"
    
    # Backup de configuraciones de usuario
    if [[ -d "$HOME/.config" ]]; then
        log_debug "Backup de configuraciones de usuario"
        cp -r "$HOME/.config" "$backup_path/" 2>/dev/null || true
    fi
    
    # Backup de archivos específicos
    local important_files=(
        "$HOME/.bashrc"
        "$HOME/.zshrc"
        "$HOME/.profile"
        "$HOME/.xinitrc"
        "$HOME/.xsession"
    )
    
    for file in "${important_files[@]}"; do
        if [[ -f "$file" ]]; then
            log_debug "Backup de $file"
            cp "$file" "$backup_path/" 2>/dev/null || true
        fi
    done
    
    # Crear archivo de metadatos
    {
        echo "Backup: $backup_name"
        echo "Tipo: $backup_type"
        echo "Timestamp: $timestamp"
        echo "Usuario: $(whoami)"
        echo "Sistema: $(uname -a)"
    } > "$backup_path/metadata"
    
    BACKUP_STATUS["$backup_name"]="created"
    log_info "Backup creado: $backup_path"
}

# Función para health checks del sistema
run_health_checks() {
    log_info "Ejecutando health checks del sistema..."
    
    # Lista de health checks
    local health_checks=(
        "check_system_services"
        "check_configuration_files"
        "check_dependencies"
        "check_permissions"
        "check_disk_space"
        "check_memory_usage"
        "check_network_connectivity"
        "check_package_integrity"
    )
    
    # Mostrar progress bar
    local check_names=()
    for check in "${health_checks[@]}"; do
        check_names+=("${check#check_}")
    done
    show_verification_progress "${check_names[@]}"
    
    local healthy_count=0
    local warning_count=0
    local error_count=0
    
    for i in "${!health_checks[@]}"; do
        local check_function="${health_checks[$i]}"
        local check_name="${check_names[$i]}"
        local current=$((i + 1))
        
        log_info "Ejecutando health check $current/${#health_checks[@]}: $check_name"
        
        # Ejecutar health check
        case "$check_function" in
            "check_system_services")
                result=$(check_system_services)
                ;;
            "check_configuration_files")
                result=$(check_configuration_files)
                ;;
            "check_dependencies")
                result=$(check_dependencies)
                ;;
            "check_permissions")
                result=$(check_permissions)
                ;;
            "check_disk_space")
                result=$(check_disk_space)
                ;;
            "check_memory_usage")
                result=$(check_memory_usage)
                ;;
            "check_network_connectivity")
                result=$(check_network_connectivity)
                ;;
            "check_package_integrity")
                result=$(check_package_integrity)
                ;;
        esac
        
        # Evaluar resultado
        case "$result" in
            "healthy")
                HEALTH_STATUS["$check_name"]="healthy"
                healthy_count=$((healthy_count + 1))
                ;;
            "warning")
                HEALTH_STATUS["$check_name"]="warning"
                warning_count=$((warning_count + 1))
                ;;
            "error")
                HEALTH_STATUS["$check_name"]="error"
                error_count=$((error_count + 1))
                ;;
        esac
    done
    
    log_info "Health checks completados: $healthy_count healthy, $warning_count warnings, $error_count errors"
    
    # Generar reporte de health
    generate_health_report
    
    # Retornar estado general
    if [[ $error_count -gt 0 ]]; then
        return 1
    elif [[ $warning_count -gt 0 ]]; then
        return 2
    else
        return 0
    fi
}

# Función para verificar servicios del sistema
check_system_services() {
    local critical_services=(
        "bluetooth"
        "NetworkManager"
        "systemd-resolved"
        "pipewire"
    )
    
    local failed_services=0
    
    for service in "${critical_services[@]}"; do
        if ! systemctl is-active --quiet "$service.service" 2>/dev/null; then
            failed_services=$((failed_services + 1))
        fi
    done
    
    if [[ $failed_services -eq 0 ]]; then
        echo "healthy"
    elif [[ $failed_services -le 2 ]]; then
        echo "warning"
    else
        echo "error"
    fi
}

# Función para verificar archivos de configuración
check_configuration_files() {
    local config_files=(
        "$HOME/.config/hyprland/hyprland.conf"
        "$HOME/.config/waybar/config.json"
        "$HOME/.config/dunst/dunstrc"
        "$HOME/.config/kitty/kitty.conf"
    )
    
    local missing_files=0
    
    for file in "${config_files[@]}"; do
        if [[ ! -f "$file" ]]; then
            missing_files=$((missing_files + 1))
        fi
    done
    
    if [[ $missing_files -eq 0 ]]; then
        echo "healthy"
    elif [[ $missing_files -le 2 ]]; then
        echo "warning"
    else
        echo "error"
    fi
}

# Función para verificar dependencias
check_dependencies() {
    local critical_deps=(
        "hyprland"
        "waybar"
        "dunst"
        "kitty"
    )
    
    local missing_deps=0
    
    for dep in "${critical_deps[@]}"; do
        if ! pacman -Q "$dep" &>/dev/null; then
            missing_deps=$((missing_deps + 1))
        fi
    done
    
    if [[ $missing_deps -eq 0 ]]; then
        echo "healthy"
    elif [[ $missing_deps -le 1 ]]; then
        echo "warning"
    else
        echo "error"
    fi
}

# Función para verificar permisos
check_permissions() {
    local permission_issues=0
    
    # Verificar permisos de directorios importantes
    local important_dirs=(
        "$HOME/.config"
        "$HOME/.local"
        "$HOME/.cache"
    )
    
    for dir in "${important_dirs[@]}"; do
        if [[ -d "$dir" ]]; then
            local perms=$(stat -c%a "$dir")
            if [[ "$perms" != "755" && "$perms" != "750" ]]; then
                permission_issues=$((permission_issues + 1))
            fi
        fi
    done
    
    if [[ $permission_issues -eq 0 ]]; then
        echo "healthy"
    elif [[ $permission_issues -le 2 ]]; then
        echo "warning"
    else
        echo "error"
    fi
}

# Función para verificar espacio en disco
check_disk_space() {
    local available_space=$(df / | tail -1 | awk '{print $4}')
    local available_gb=$((available_space / 1024 / 1024))
    
    if [[ $available_gb -gt 10 ]]; then
        echo "healthy"
    elif [[ $available_gb -gt 5 ]]; then
        echo "warning"
    else
        echo "error"
    fi
}

# Función para verificar uso de memoria
check_memory_usage() {
    local total_mem=$(grep "MemTotal" /proc/meminfo | awk '{print $2}')
    local available_mem=$(grep "MemAvailable" /proc/meminfo | awk '{print $2}')
    local usage_percent=$((100 - (available_mem * 100 / total_mem)))
    
    if [[ $usage_percent -lt 80 ]]; then
        echo "healthy"
    elif [[ $usage_percent -lt 90 ]]; then
        echo "warning"
    else
        echo "error"
    fi
}

# Función para verificar conectividad de red
check_network_connectivity() {
    if ping -c 1 8.8.8.8 &>/dev/null; then
        echo "healthy"
    else
        echo "error"
    fi
}

# Función para verificar integridad de paquetes
check_package_integrity() {
    local broken_packages=$(pacman -Qk 2>&1 | grep -c "error" || echo 0)
    
    if [[ $broken_packages -eq 0 ]]; then
        echo "healthy"
    elif [[ $broken_packages -le 2 ]]; then
        echo "warning"
    else
        echo "error"
    fi
}

# Función para cleanup de archivos temporales
run_cleanup() {
    log_info "Ejecutando cleanup de archivos temporales..."
    
    # Lista de directorios y archivos a limpiar
    local cleanup_items=(
        "/tmp/hyprdream_*"
        "/var/tmp/hyprdream_*"
        "$HOME/.cache/hyprdream_*"
        "$HOME/.local/share/Trash"
        "/var/cache/pacman/pkg/*.pkg.tar.zst"
        "/var/cache/paru/pkg/*.pkg.tar.zst"
    )
    
    # Mostrar progress bar
    show_cleanup_progress "${cleanup_items[@]}"
    
    local cleaned_size=0
    local error_count=0
    
    for i in "${!cleanup_items[@]}"; do
        local item="${cleanup_items[$i]}"
        local current=$((i + 1))
        
        log_info "Limpiando item $current/${#cleanup_items[@]}: $item"
        
        # Calcular tamaño antes de limpiar
        local item_size=$(du -sb $item 2>/dev/null | awk '{sum+=$1} END {print sum+0}')
        
        # Limpiar item
        if rm -rf $item 2>/dev/null; then
            cleaned_size=$((cleaned_size + item_size))
            log_debug "Item limpiado: $item"
        else
            error_count=$((error_count + 1))
            log_warn "Error al limpiar: $item"
        fi
    done
    
    # Limpiar logs antiguos
    cleanup_old_logs
    
    # Limpiar backups antiguos
    cleanup_old_backups
    
    # Limpiar cache de paquetes
    cleanup_package_cache
    
    local cleaned_mb=$((cleaned_size / 1024 / 1024))
    log_info "Cleanup completado: ${cleaned_mb}MB liberados, $error_count errores"
    
    # Generar reporte de cleanup
    generate_cleanup_report "$cleaned_size" "$error_count"
}

# Función para limpiar logs antiguos
cleanup_old_logs() {
    log_info "Limpiando logs antiguos..."
    
    local log_dirs=(
        "/var/log"
        "$HOME/.cache"
        "/tmp"
    )
    
    for log_dir in "${log_dirs[@]}"; do
        if [[ -d "$log_dir" ]]; then
            # Eliminar logs más antiguos de 30 días
            find "$log_dir" -name "*.log*" -mtime +30 -delete 2>/dev/null || true
            find "$log_dir" -name "hyprdream*" -mtime +7 -delete 2>/dev/null || true
        fi
    done
}

# Función para limpiar backups antiguos
cleanup_old_backups() {
    log_info "Limpiando backups antiguos..."
    
    if [[ -d "$BACKUP_DIR" ]]; then
        # Mantener solo los últimos 10 backups
        local backup_count=$(ls -1 "$BACKUP_DIR" | wc -l)
        if [[ $backup_count -gt 10 ]]; then
            local to_remove=$((backup_count - 10))
            ls -1t "$BACKUP_DIR" | tail -n "$to_remove" | xargs -I {} rm -rf "$BACKUP_DIR/{}" 2>/dev/null || true
        fi
    fi
}

# Función para limpiar cache de paquetes
cleanup_package_cache() {
    log_info "Limpiando cache de paquetes..."
    
    # Limpiar cache de pacman
    sudo pacman -Sc --noconfirm 2>/dev/null || true
    
    # Limpiar cache de AUR helpers
    if command -v paru &>/dev/null; then
        paru -Sc --noconfirm 2>/dev/null || true
    fi
    
    if command -v yay &>/dev/null; then
        yay -Sc --noconfirm 2>/dev/null || true
    fi
}

# Función para generar reporte de health
generate_health_report() {
    local report_file="${1:-$HEALTH_LOG}"
    
    log_info "Generando reporte de health..."
    
    {
        echo "=== Reporte de Health Check hyprdream ==="
        echo "Fecha: $(date)"
        echo "Sistema: $(uname -a)"
        echo ""
        
        echo "--- Estado de Health Checks ---"
        for check in "${!HEALTH_STATUS[@]}"; do
            local status="${HEALTH_STATUS[$check]}"
            local status_icon=""
            
            case "$status" in
                "healthy") status_icon="✓" ;;
                "warning") status_icon="⚠" ;;
                "error") status_icon="✗" ;;
            esac
            
            echo "$status_icon $check: $status"
        done
        echo ""
        
        echo "--- Resumen ---"
        local healthy_count=0
        local warning_count=0
        local error_count=0
        
        for status in "${HEALTH_STATUS[@]}"; do
            case "$status" in
                "healthy") healthy_count=$((healthy_count + 1)) ;;
                "warning") warning_count=$((warning_count + 1)) ;;
                "error") error_count=$((error_count + 1)) ;;
            esac
        done
        
        echo "Healthy: $healthy_count"
        echo "Warnings: $warning_count"
        echo "Errors: $error_count"
        
    } > "$report_file"
    
    log_info "Reporte de health generado: $report_file"
}

# Función para generar reporte de actualizaciones
generate_update_report() {
    local report_file="${1:-$UPDATE_LOG}"
    
    log_info "Generando reporte de actualizaciones..."
    
    {
        echo "=== Reporte de Actualizaciones hyprdream ==="
        echo "Fecha: $(date)"
        echo ""
        
        echo "--- Estado de Actualizaciones ---"
        for config in "${!UPDATE_STATUS[@]}"; do
            local status="${UPDATE_STATUS[$config]}"
            echo "$config: $status"
        done
        echo ""
        
        echo "--- Backups Creados ---"
        for backup in "${!BACKUP_STATUS[@]}"; do
            local status="${BACKUP_STATUS[$backup]}"
            echo "$backup: $status"
        done
        
    } > "$report_file"
    
    log_info "Reporte de actualizaciones generado: $report_file"
}

# Función para generar reporte de cleanup
generate_cleanup_report() {
    local cleaned_size="$1"
    local error_count="$2"
    local report_file="${3:-$CLEANUP_LOG}"
    
    log_info "Generando reporte de cleanup..."
    
    {
        echo "=== Reporte de Cleanup hyprdream ==="
        echo "Fecha: $(date)"
        echo ""
        
        echo "--- Resumen de Cleanup ---"
        echo "Espacio liberado: $((cleaned_size / 1024 / 1024))MB"
        echo "Errores: $error_count"
        echo ""
        
        echo "--- Items Limpiados ---"
        echo "• Archivos temporales de hyprdream"
        echo "• Cache de paquetes"
        echo "• Logs antiguos"
        echo "• Backups antiguos"
        echo "• Papelera del usuario"
        
    } > "$report_file"
    
    log_info "Reporte de cleanup generado: $report_file"
}

# Función para inicializar sistema de mantenimiento
init_maintenance_system() {
    log_info "Inicializando sistema de mantenimiento..."
    
    # Crear directorios necesarios
    mkdir -p "$MAINTENANCE_DIR"
    mkdir -p "$BACKUP_DIR"
    
    # Configurar logs
    touch "$HEALTH_LOG"
    touch "$UPDATE_LOG"
    touch "$CLEANUP_LOG"
    
    log_info "Sistema de mantenimiento inicializado"
}

# Función principal de mantenimiento
run_maintenance() {
    log_info "Iniciando mantenimiento del sistema..."
    
    # Ejecutar health checks
    run_health_checks
    local health_result=$?
    
    # Ejecutar auto-updates si el sistema está saludable
    if [[ $health_result -eq 0 ]]; then
        auto_update_configurations
    else
        log_warn "Omitiendo auto-updates debido a problemas de health"
    fi
    
    # Ejecutar cleanup
    run_cleanup
    
    log_info "Mantenimiento completado"
}

# Ejecutar si se llama directamente
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    init_logger
    
    case "${1:-run}" in
        "run")
            run_maintenance
            ;;
        "health")
            run_health_checks
            ;;
        "update")
            auto_update_configurations
            ;;
        "cleanup")
            run_cleanup
            ;;
        "backup")
            create_configuration_backup "${2:-manual}"
            ;;
        "report")
            generate_health_report "${2:-}"
            ;;
        "init")
            init_maintenance_system
            ;;
        "test")
            # Test del sistema de mantenimiento
            echo -e "${CYAN}=== Test del Sistema de Mantenimiento ===${RESET}"
            
            init_maintenance_system
            run_health_checks
            create_configuration_backup "test"
            run_cleanup
            ;;
        *)
            echo "Uso: $0 [run|health|update|cleanup|backup|report|init|test]"
            echo ""
            echo "Comandos:"
            echo "  run      - Ejecutar mantenimiento completo"
            echo "  health   - Ejecutar health checks"
            echo "  update   - Auto-update de configuraciones"
            echo "  cleanup  - Limpiar archivos temporales"
            echo "  backup   - Crear backup manual"
            echo "  report   - Generar reporte de health"
            echo "  init     - Inicializar sistema de mantenimiento"
            echo "  test     - Probar sistema de mantenimiento"
            ;;
    esac
fi 