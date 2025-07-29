#!/usr/bin/env bash
# Sistema de rollback automático para hyprdream
# Maneja errores durante la instalación y restaura el sistema

source "$(dirname "$0")/colors.sh"
source "$(dirname "$0")/logger.sh"
source "$(dirname "$0")/progress.sh"

# Configuración
BACKUP_DIR="${BACKUP_DIR:-/tmp/hyprdream_backup}"
ROLLBACK_LOG="${ROLLBACK_LOG:-/tmp/hyprdream_rollback.log}"
MAX_BACKUPS="${MAX_BACKUPS:-5}"

# Variables globales
declare -A BACKUP_POINTS=()
declare -A INSTALLATION_STEPS=()
declare -A ROLLBACK_STACK=()

# Función para crear punto de backup
create_backup_point() {
    local point_name="$1"
    local description="${2:-}"
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_path="$BACKUP_DIR/${point_name}_${timestamp}"
    
    log_info "Creando punto de backup: $point_name"
    
    # Crear directorio de backup
    mkdir -p "$backup_path"
    
    # Backup de configuraciones existentes
    if [[ -d ~/.config ]]; then
        log_debug "Backup de ~/.config"
        cp -r ~/.config "$backup_path/" 2>/dev/null || true
    fi
    
    # Backup de archivos específicos
    local important_files=(
        "~/.bashrc"
        "~/.zshrc"
        "~/.profile"
        "~/.xinitrc"
        "~/.xsession"
    )
    
    for file in "${important_files[@]}"; do
        if [[ -f "$file" ]]; then
            log_debug "Backup de $file"
            cp "$file" "$backup_path/" 2>/dev/null || true
        fi
    done
    
    # Backup de paquetes instalados
    if command -v pacman &>/dev/null; then
        log_debug "Backup de lista de paquetes"
        pacman -Q > "$backup_path/packages.list" 2>/dev/null || true
    fi
    
    # Guardar información del punto de backup
    BACKUP_POINTS["$point_name"]="$backup_path"
    
    # Crear archivo de metadatos
    cat > "$backup_path/metadata" << EOF
Punto de backup: $point_name
Descripción: $description
Timestamp: $timestamp
Sistema: $(uname -a)
Usuario: $(whoami)
Directorio: $backup_path
EOF
    
    log_info "Punto de backup creado: $backup_path"
    return 0
}

# Función para registrar paso de instalación
register_installation_step() {
    local step_name="$1"
    local step_type="$2"  # install, config, service, etc.
    local step_data="$3"
    local timestamp=$(date +%Y%m%d_%H%M%S)
    
    INSTALLATION_STEPS["$step_name"]="$step_type:$step_data:$timestamp"
    
    log_debug "Paso registrado: $step_name ($step_type)"
}

# Función para registrar operación en el stack de rollback
push_rollback_operation() {
    local operation="$1"
    local data="$2"
    local timestamp=$(date +%Y%m%d_%H%M%S)
    
    ROLLBACK_STACK+=("$operation:$data:$timestamp")
    
    log_debug "Operación de rollback registrada: $operation"
}

# Función para ejecutar rollback
execute_rollback() {
    local error_point="$1"
    local error_message="${2:-Error desconocido}"
    
    log_error "Error detectado en: $error_point"
    log_error "Mensaje: $error_message"
    log_error "Iniciando rollback..."
    
    # Mostrar progress bar de rollback
    local rollback_steps=("Detectando cambios" "Restaurando configuraciones" "Desinstalando paquetes" "Limpiando archivos")
    show_rollback_progress "${rollback_steps[@]}"
    
    # Ejecutar operaciones de rollback en orden inverso
    local total_operations=${#ROLLBACK_STACK[@]}
    
    for ((i=total_operations-1; i>=0; i--)); do
        local operation_data="${ROLLBACK_STACK[$i]}"
        local operation=$(echo "$operation_data" | cut -d: -f1)
        local data=$(echo "$operation_data" | cut -d: -f2)
        
        log_info "Ejecutando rollback: $operation"
        
        case "$operation" in
            "package_install")
                rollback_package_install "$data"
                ;;
            "config_copy")
                rollback_config_copy "$data"
                ;;
            "service_enable")
                rollback_service_enable "$data"
                ;;
            "file_create")
                rollback_file_create "$data"
                ;;
            "permission_change")
                rollback_permission_change "$data"
                ;;
            "symlink_create")
                rollback_symlink_create "$data"
                ;;
            *)
                log_warn "Operación de rollback desconocida: $operation"
                ;;
        esac
    done
    
    # Restaurar desde el último punto de backup
    if [[ ${#BACKUP_POINTS[@]} -gt 0 ]]; then
        local last_backup=""
        for backup in "${!BACKUP_POINTS[@]}" 2>/dev/null || true; do
            last_backup="$backup"
        done
        
        if [[ -n "$last_backup" ]]; then
            log_info "Restaurando desde backup: $last_backup"
            restore_from_backup "$last_backup"
        fi
    fi
    
    # Limpiar stack de rollback
    ROLLBACK_STACK=()
    
    log_warn "Rollback completado. El sistema ha sido restaurado."
}

# Función para rollback de instalación de paquetes
rollback_package_install() {
    local packages="$1"
    
    log_info "Desinstalando paquetes: $packages"
    
    # Convertir string a array
    IFS=',' read -ra package_array <<< "$packages"
    
    for package in "${package_array[@]}"; do
        if pacman -Q "$package" &>/dev/null; then
            log_info "Desinstalando $package"
            sudo pacman -R --noconfirm "$package" 2>/dev/null || true
        fi
    done
}

# Función para rollback de copia de configuraciones
rollback_config_copy() {
    local config_path="$1"
    
    log_info "Restaurando configuración: $config_path"
    
    if [[ -d "$config_path" ]]; then
        rm -rf "$config_path" 2>/dev/null || true
        log_info "Configuración eliminada: $config_path"
    fi
}

# Función para rollback de habilitación de servicios
rollback_service_enable() {
    local service="$1"
    
    log_info "Deshabilitando servicio: $service"
    
    if systemctl is-enabled "$service" &>/dev/null; then
        sudo systemctl disable "$service" 2>/dev/null || true
        log_info "Servicio deshabilitado: $service"
    fi
}

# Función para rollback de creación de archivos
rollback_file_create() {
    local file_path="$1"
    
    log_info "Eliminando archivo: $file_path"
    
    if [[ -f "$file_path" ]]; then
        rm -f "$file_path" 2>/dev/null || true
        log_info "Archivo eliminado: $file_path"
    fi
}

# Función para rollback de cambio de permisos
rollback_permission_change() {
    local permission_data="$1"
    local file_path=$(echo "$permission_data" | cut -d'|' -f1)
    local old_permissions=$(echo "$permission_data" | cut -d'|' -f2)
    
    log_info "Restaurando permisos: $file_path -> $old_permissions"
    
    if [[ -f "$file_path" ]]; then
        chmod "$old_permissions" "$file_path" 2>/dev/null || true
        log_info "Permisos restaurados: $file_path"
    fi
}

# Función para rollback de creación de symlinks
rollback_symlink_create() {
    local symlink_path="$1"
    
    log_info "Eliminando symlink: $symlink_path"
    
    if [[ -L "$symlink_path" ]]; then
        rm -f "$symlink_path" 2>/dev/null || true
        log_info "Symlink eliminado: $symlink_path"
    fi
}

# Función para restaurar desde backup
restore_from_backup() {
    local backup_name="$1"
    local backup_path="${BACKUP_POINTS[$backup_name]}"
    
    if [[ -z "$backup_path" || ! -d "$backup_path" ]]; then
        log_error "Backup no encontrado: $backup_name"
        return 1
    fi
    
    log_info "Restaurando desde: $backup_path"
    
    # Restaurar configuraciones
    if [[ -d "$backup_path/.config" ]]; then
        log_info "Restaurando configuraciones"
        cp -r "$backup_path/.config" ~/ 2>/dev/null || true
    fi
    
    # Restaurar archivos importantes
    local important_files=(
        ".bashrc"
        ".zshrc"
        ".profile"
        ".xinitrc"
        ".xsession"
    )
    
    for file in "${important_files[@]}"; do
        if [[ -f "$backup_path/$file" ]]; then
            log_info "Restaurando $file"
            cp "$backup_path/$file" ~/ 2>/dev/null || true
        fi
    done
    
    log_info "Restauración completada desde: $backup_name"
}

# Función para limpiar backups antiguos
cleanup_old_backups() {
    log_info "Limpiando backups antiguos..."
    
    if [[ ! -d "$BACKUP_DIR" ]]; then
        return 0
    fi
    
    # Obtener lista de backups ordenados por fecha
    local backups=($(ls -1t "$BACKUP_DIR" 2>/dev/null | head -n $MAX_BACKUPS))
    
    # Eliminar backups excedentes
    local all_backups=($(ls -1t "$BACKUP_DIR" 2>/dev/null))
    local to_remove=${#all_backups[@]}
    to_remove=$((to_remove - MAX_BACKUPS))
    
    if [[ $to_remove -gt 0 ]]; then
        for ((i=0; i<to_remove; i++)); do
            local old_backup="${all_backups[$((MAX_BACKUPS + i))]}"
            if [[ -n "$old_backup" ]]; then
                log_info "Eliminando backup antiguo: $old_backup"
                rm -rf "$BACKUP_DIR/$old_backup" 2>/dev/null || true
            fi
        done
    fi
    
    log_info "Limpieza de backups completada"
}

# Función para listar puntos de backup
list_backup_points() {
    echo -e "\n${CYAN}=== Puntos de Backup Disponibles ===${RESET}"
    
    if [[ ${#BACKUP_POINTS[@]} -eq 0 ]]; then
        echo "No hay puntos de backup disponibles"
        return 0
    fi
    
    for backup_name in "${!BACKUP_POINTS[@]}" 2>/dev/null || true; do
        local backup_path="${BACKUP_POINTS[$backup_name]}"
        local metadata_file="$backup_path/metadata"
        
        echo -e "\n${BLUE}Backup:${RESET} $backup_name"
        echo "  Ruta: $backup_path"
        
        if [[ -f "$metadata_file" ]]; then
            echo "  Descripción: $(grep "Descripción:" "$metadata_file" | cut -d: -f2-)"
            echo "  Timestamp: $(grep "Timestamp:" "$metadata_file" | cut -d: -f2-)"
        fi
    done
    
    echo ""
}

# Función para verificar integridad de backups
verify_backup_integrity() {
    local backup_name="$1"
    local backup_path="${BACKUP_POINTS[$backup_name]}"
    
    if [[ -z "$backup_path" ]]; then
        log_error "Backup no encontrado: $backup_name"
        return 1
    fi
    
    log_info "Verificando integridad de backup: $backup_name"
    
    local integrity_ok=true
    
    # Verificar que el directorio existe
    if [[ ! -d "$backup_path" ]]; then
        log_error "Directorio de backup no existe: $backup_path"
        integrity_ok=false
    fi
    
    # Verificar archivo de metadatos
    if [[ ! -f "$backup_path/metadata" ]]; then
        log_error "Archivo de metadatos no encontrado"
        integrity_ok=false
    fi
    
    # Verificar configuraciones
    if [[ ! -d "$backup_path/.config" ]]; then
        log_warn "Directorio de configuraciones no encontrado"
    fi
    
    if [[ "$integrity_ok" == "true" ]]; then
        log_info "Integridad del backup verificada: OK"
        return 0
    else
        log_error "Integridad del backup verificada: ERROR"
        return 1
    fi
}

# Función para inicializar sistema de rollback
init_rollback_system() {
    log_info "Inicializando sistema de rollback..."
    
    # Crear directorio de backup
    mkdir -p "$BACKUP_DIR"
    
    # Limpiar backups antiguos
    cleanup_old_backups
    
    # Crear backup inicial
    create_backup_point "initial" "Estado inicial del sistema antes de la instalación"
    
    log_info "Sistema de rollback inicializado"
}

# Función para finalizar sistema de rollback
finalize_rollback_system() {
    log_info "Finalizando sistema de rollback..."
    
    # Crear backup final
    create_backup_point "final" "Estado final después de la instalación exitosa"
    
    # Limpiar stack de rollback
    ROLLBACK_STACK=()
    
    log_info "Sistema de rollback finalizado"
}

# Función para manejar errores
handle_error() {
    local error_code="$1"
    local error_message="$2"
    local error_point="$3"
    
    log_fatal "Error $error_code en $error_point: $error_message"
    
    # Ejecutar rollback automático
    execute_rollback "$error_point" "$error_message"
    
    # Mostrar información de recuperación
    echo -e "\n${RED}=== Error de Instalación ===${RESET}"
    echo "Se ha producido un error durante la instalación."
    echo "El sistema ha sido restaurado a su estado anterior."
    echo ""
    echo "Información del error:"
    echo "  Código: $error_code"
    echo "  Punto: $error_point"
    echo "  Mensaje: $error_message"
    echo ""
    echo "Logs disponibles en: $LOG_FILE"
    echo "Backup disponible en: $BACKUP_DIR"
    echo ""
    echo "Para intentar la instalación nuevamente, ejecute:"
    echo "  $0"
    
    exit "$error_code"
}

# Función para establecer trap de errores
setup_error_trap() {
    trap 'handle_error $? "Error inesperado" "unknown"' ERR
    trap 'handle_error 1 "Interrumpido por el usuario" "interrupt"' INT TERM
}

# Ejecutar si se llama directamente
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    init_logger
    
    case "${1:-help}" in
        "init")
            init_rollback_system
            ;;
        "list")
            list_backup_points
            ;;
        "verify")
            verify_backup_integrity "${2:-}"
            ;;
        "restore")
            restore_from_backup "${2:-}"
            ;;
        "cleanup")
            cleanup_old_backups
            ;;
        "test")
            # Test del sistema de rollback
            echo -e "${CYAN}=== Test del Sistema de Rollback ===${RESET}"
            
            init_rollback_system
            
            # Simular operaciones
            register_installation_step "test_package" "install" "test-package"
            push_rollback_operation "package_install" "test-package"
            
            register_installation_step "test_config" "config" "test.conf"
            push_rollback_operation "config_copy" "test.conf"
            
            # Simular error
            echo "Simulando error..."
            handle_error 1 "Error de prueba" "test_point"
            ;;
        *)
            echo "Uso: $0 [init|list|verify|restore|cleanup|test]"
            echo ""
            echo "Comandos:"
            echo "  init     - Inicializar sistema de rollback"
            echo "  list     - Listar puntos de backup"
            echo "  verify   - Verificar integridad de backup"
            echo "  restore  - Restaurar desde backup"
            echo "  cleanup  - Limpiar backups antiguos"
            echo "  test     - Probar sistema de rollback"
            ;;
    esac
fi 