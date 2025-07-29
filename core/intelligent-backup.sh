#!/usr/bin/env bash
# Sistema de backup inteligente para hyprland-dream
# Backups incrementales, automáticos y restauración inteligente

source "$(dirname "$0")/colors.sh"
source "$(dirname "$0")/logger.sh"

# Configuración
BACKUP_ROOT="${BACKUP_ROOT:-$HOME/.local/share/hyprland-dream/backups}"
BACKUP_RETENTION_DAYS="${BACKUP_RETENTION_DAYS:-30}"
BACKUP_COMPRESSION="${BACKUP_COMPRESSION:-true}"
BACKUP_ENCRYPTION="${BACKUP_ENCRYPTION:-false}"
AUTO_BACKUP="${AUTO_BACKUP:-true}"
BACKUP_INTERVAL_HOURS="${BACKUP_INTERVAL_HOURS:-24}"

# Variables globales
declare -A BACKUP_CONFIGS=()
declare -A BACKUP_HISTORY=()
declare -A RESTORE_POINTS=()

# Función para inicializar sistema de backup inteligente
init_intelligent_backup() {
    log_info "Inicializando sistema de backup inteligente..."
    
    # Crear directorios necesarios
    mkdir -p "$BACKUP_ROOT"/{configs,scripts,data,logs}
    
    # Configurar directorios de backup
    setup_backup_directories
    
    # Cargar configuraciones de backup
    load_backup_configurations
    
    # Verificar herramientas de backup
    check_backup_tools
    
    # Limpiar backups antiguos
    cleanup_old_backups
    
    log_info "Sistema de backup inteligente inicializado"
}

# Función para configurar directorios de backup
setup_backup_directories() {
    log_info "Configurando directorios de backup..."
    
    # Directorios principales
    local backup_dirs=(
        "configs/hypr"
        "configs/waybar"
        "configs/dunst"
        "configs/kitty"
        "configs/rofi"
        "configs/themes"
        "scripts/system"
        "scripts/media"
        "scripts/workspace"
        "data/user"
        "data/system"
        "logs/backup"
        "logs/restore"
    )
    
    for dir in "${backup_dirs[@]}"; do
        mkdir -p "$BACKUP_ROOT/$dir"
    done
    
    log_info "Directorios de backup configurados"
}

# Función para cargar configuraciones de backup
load_backup_configurations() {
    log_info "Cargando configuraciones de backup..."
    
    # Configuraciones críticas (siempre backup)
    BACKUP_CONFIGS["critical"]="
        $HOME/.config/hypr
        $HOME/.config/waybar
        $HOME/.config/dunst
        $HOME/.config/kitty
        $HOME/.config/rofi
        $HOME/.config/swww
        $HOME/.config/wlogout
        $HOME/.config/swaylock
    "
    
    # Configuraciones importantes (backup frecuente)
    BACKUP_CONFIGS["important"]="
        $HOME/.config/fish
        $HOME/.config/zsh
        $HOME/.config/nvim
        $HOME/.config/code
        $HOME/.config/spotify
        $HOME/.config/discord
    "
    
    # Datos de usuario (backup ocasional)
    BACKUP_CONFIGS["user_data"]="
        $HOME/Documents
        $HOME/Pictures
        $HOME/Music
        $HOME/Videos
        $HOME/Downloads
    "
    
    # Configuraciones del sistema (backup manual)
    BACKUP_CONFIGS["system"]="
        /etc/pacman.conf
        /etc/systemd
        /etc/fstab
        /etc/hosts
    "
    
    log_info "Configuraciones de backup cargadas"
}

# Función para verificar herramientas de backup
check_backup_tools() {
    log_info "Verificando herramientas de backup..."
    
    local required_tools=("rsync" "tar" "gzip")
    local optional_tools=("btrfs" "zstd" "gpg")
    
    for tool in "${required_tools[@]}"; do
        if ! command -v "$tool" &>/dev/null; then
            log_error "Herramienta de backup requerida faltante: $tool"
            return 1
        fi
    done
    
    for tool in "${optional_tools[@]}"; do
        if command -v "$tool" &>/dev/null; then
            log_info "Herramienta opcional disponible: $tool"
        fi
    done
    
    log_info "Herramientas de backup verificadas"
}

# Función para crear backup incremental
create_incremental_backup() {
    local backup_type="${1:-critical}"
    local backup_name="${2:-$(date +%Y%m%d_%H%M%S)}"
    local backup_dir="$BACKUP_ROOT/configs/$backup_name"
    
    log_info "Creando backup incremental: $backup_type ($backup_name)"
    
    # Crear directorio de backup
    mkdir -p "$backup_dir"
    
    # Obtener configuraciones para este tipo
    local configs="${BACKUP_CONFIGS[$backup_type]}"
    
    if [[ -z "$configs" ]]; then
        log_error "Tipo de backup desconocido: $backup_type"
        return 1
    fi
    
    # Crear backup de cada configuración
    local success_count=0
    local total_count=0
    
    while IFS= read -r config_path; do
        [[ -z "$config_path" ]] && continue
        total_count=$((total_count + 1))
        
        if create_single_backup "$config_path" "$backup_dir"; then
            success_count=$((success_count + 1))
        fi
    done <<< "$configs"
    
    # Crear metadatos del backup
    create_backup_metadata "$backup_dir" "$backup_type" "$success_count" "$total_count"
    
    # Registrar en historial
    BACKUP_HISTORY["$backup_name"]="$backup_type:$success_count/$total_count:$(date +%s)"
    
    log_info "Backup incremental completado: $success_count/$total_count configuraciones"
    return 0
}

# Función para crear backup de una configuración individual
create_single_backup() {
    local source_path="$1"
    local backup_dir="$2"
    
    if [[ ! -e "$source_path" ]]; then
        log_debug "Ruta no existe, omitiendo: $source_path"
        return 0
    fi
    
    local basename_path=$(basename "$source_path")
    local backup_path="$backup_dir/$basename_path"
    
    # Crear backup usando rsync
    if rsync -av --delete "$source_path/" "$backup_path/" 2>/dev/null; then
        log_debug "Backup exitoso: $source_path"
        return 0
    else
        log_warn "Error en backup: $source_path"
        return 1
    fi
}

# Función para crear metadatos del backup
create_backup_metadata() {
    local backup_dir="$1"
    local backup_type="$2"
    local success_count="$3"
    local total_count="$4"
    
    local metadata_file="$backup_dir/backup_metadata.txt"
    
    {
        echo "=== Metadatos de Backup ==="
        echo "Fecha: $(date)"
        echo "Tipo: $backup_type"
        echo "Configuraciones exitosas: $success_count/$total_count"
        echo "Tamaño: $(du -sh "$backup_dir" | cut -f1)"
        echo "Compresión: $BACKUP_COMPRESSION"
        echo "Encriptación: $BACKUP_ENCRYPTION"
        echo ""
        echo "--- Contenido ---"
        find "$backup_dir" -type f -name "backup_metadata.txt" -prune -o -type f -print | sort
        echo ""
        echo "--- Checksums ---"
        find "$backup_dir" -type f -name "backup_metadata.txt" -prune -o -type f -exec sha256sum {} \;
    } > "$metadata_file"
}

# Función para crear backup completo
create_full_backup() {
    local backup_name="${1:-$(date +%Y%m%d_%H%M%S)_full}"
    local backup_file="$BACKUP_ROOT/data/${backup_name}.tar.gz"
    
    log_info "Creando backup completo: $backup_name"
    
    # Crear backup temporal
    local temp_dir=$(mktemp -d)
    
    # Copiar configuraciones críticas
    create_incremental_backup "critical" "temp_critical"
    
    # Copiar configuraciones importantes
    create_incremental_backup "important" "temp_important"
    
    # Crear archivo comprimido
    if [[ "$BACKUP_COMPRESSION" == "true" ]]; then
        if command -v zstd &>/dev/null; then
            tar -cf - -C "$BACKUP_ROOT" configs/ | zstd -9 > "${backup_file%.tar.gz}.tar.zst"
            backup_file="${backup_file%.tar.gz}.tar.zst"
        else
            tar -czf "$backup_file" -C "$BACKUP_ROOT" configs/
        fi
    else
        tar -cf "$backup_file" -C "$BACKUP_ROOT" configs/
    fi
    
    # Encriptar si está habilitado
    if [[ "$BACKUP_ENCRYPTION" == "true" ]] && command -v gpg &>/dev/null; then
        gpg --encrypt --recipient "$USER" "$backup_file"
        rm "$backup_file"
        backup_file="$backup_file.gpg"
    fi
    
    # Crear metadatos
    create_full_backup_metadata "$backup_file" "$backup_name"
    
    # Limpiar archivos temporales
    rm -rf "$BACKUP_ROOT/configs/temp_"*
    
    log_info "Backup completo creado: $backup_file"
}

# Función para crear metadatos de backup completo
create_full_backup_metadata() {
    local backup_file="$1"
    local backup_name="$2"
    
    local metadata_file="${backup_file%.*}.metadata"
    
    {
        echo "=== Metadatos de Backup Completo ==="
        echo "Fecha: $(date)"
        echo "Nombre: $backup_name"
        echo "Archivo: $backup_file"
        echo "Tamaño: $(du -h "$backup_file" | cut -f1)"
        echo "Compresión: $BACKUP_COMPRESSION"
        echo "Encriptación: $BACKUP_ENCRYPTION"
        echo "Checksum: $(sha256sum "$backup_file" | cut -d' ' -f1)"
        echo ""
        echo "--- Contenido ---"
        echo "Configuraciones críticas e importantes incluidas"
        echo "Backup incremental de configuraciones de hyprland-dream"
    } > "$metadata_file"
}

# Función para restaurar desde backup
restore_from_backup() {
    local backup_name="$1"
    local restore_type="${2:-critical}"
    local backup_dir="$BACKUP_ROOT/configs/$backup_name"
    
    log_info "Restaurando desde backup: $backup_name ($restore_type)"
    
    if [[ ! -d "$backup_dir" ]]; then
        log_error "Backup no encontrado: $backup_name"
        return 1
    fi
    
    # Crear punto de restauración
    create_restore_point "before_restore_$backup_name"
    
    # Restaurar configuraciones
    local success_count=0
    local total_count=0
    
    for config_dir in "$backup_dir"/*; do
        if [[ -d "$config_dir" ]]; then
            local config_name=$(basename "$config_dir")
            local target_dir="$HOME/.config/$config_name"
            
            total_count=$((total_count + 1))
            
            if restore_single_config "$config_dir" "$target_dir"; then
                success_count=$((success_count + 1))
            fi
        fi
    done
    
    # Crear metadatos de restauración
    create_restore_metadata "$backup_name" "$restore_type" "$success_count" "$total_count"
    
    log_info "Restauración completada: $success_count/$total_count configuraciones"
    return 0
}

# Función para restaurar configuración individual
restore_single_config() {
    local source_dir="$1"
    local target_dir="$2"
    
    # Crear backup del directorio actual si existe
    if [[ -d "$target_dir" ]]; then
        local backup_name="pre_restore_$(basename "$target_dir")_$(date +%Y%m%d_%H%M%S)"
        cp -r "$target_dir" "$BACKUP_ROOT/data/$backup_name"
    fi
    
    # Restaurar configuración
    if rsync -av --delete "$source_dir/" "$target_dir/" 2>/dev/null; then
        log_debug "Restauración exitosa: $target_dir"
        return 0
    else
        log_warn "Error en restauración: $target_dir"
        return 1
    fi
}

# Función para crear punto de restauración
create_restore_point() {
    local point_name="$1"
    local point_dir="$BACKUP_ROOT/data/restore_points/$point_name"
    
    mkdir -p "$point_dir"
    
    # Crear backup rápido de configuraciones críticas
    create_incremental_backup "critical" "restore_point_$point_name"
    
    RESTORE_POINTS["$point_name"]="$(date +%s)"
    
    log_info "Punto de restauración creado: $point_name"
}

# Función para crear metadatos de restauración
create_restore_metadata() {
    local backup_name="$1"
    local restore_type="$2"
    local success_count="$3"
    local total_count="$4"
    
    local metadata_file="$BACKUP_ROOT/logs/restore/restore_$(date +%Y%m%d_%H%M%S).log"
    
    {
        echo "=== Metadatos de Restauración ==="
        echo "Fecha: $(date)"
        echo "Backup origen: $backup_name"
        echo "Tipo: $restore_type"
        echo "Configuraciones restauradas: $success_count/$total_count"
        echo "Usuario: $USER"
        echo "Sistema: $(uname -a)"
    } > "$metadata_file"
}

# Función para listar backups disponibles
list_available_backups() {
    log_info "Listando backups disponibles..."
    
    echo -e "${CYAN}=== Backups Disponibles ===${RESET}"
    echo ""
    
    # Backups incrementales
    echo -e "${BLUE}Backups Incrementales:${RESET}"
    for backup_dir in "$BACKUP_ROOT/configs"/*; do
        if [[ -d "$backup_dir" ]]; then
            local backup_name=$(basename "$backup_dir")
            local metadata_file="$backup_dir/backup_metadata.txt"
            
            if [[ -f "$metadata_file" ]]; then
                local backup_type=$(grep "Tipo:" "$metadata_file" | cut -d: -f2 | tr -d ' ')
                local backup_date=$(grep "Fecha:" "$metadata_file" | cut -d: -f2- | tr -d ' ')
                local backup_size=$(du -sh "$backup_dir" | cut -f1)
                
                echo "  • $backup_name ($backup_type) - $backup_date - $backup_size"
            else
                echo "  • $backup_name (sin metadatos)"
            fi
        fi
    done
    echo ""
    
    # Backups completos
    echo -e "${BLUE}Backups Completos:${RESET}"
    for backup_file in "$BACKUP_ROOT/data"/*.tar.*; do
        if [[ -f "$backup_file" ]]; then
            local backup_name=$(basename "$backup_file")
            local backup_size=$(du -h "$backup_file" | cut -f1)
            local backup_date=$(stat -c %y "$backup_file" | cut -d' ' -f1)
            
            echo "  • $backup_name - $backup_date - $backup_size"
        fi
    done
    echo ""
    
    # Puntos de restauración
    echo -e "${BLUE}Puntos de Restauración:${RESET}"
    for point_dir in "$BACKUP_ROOT/data/restore_points"/*; do
        if [[ -d "$point_dir" ]]; then
            local point_name=$(basename "$point_dir")
            local point_date=$(stat -c %y "$point_dir" | cut -d' ' -f1)
            
            echo "  • $point_name - $point_date"
        fi
    done
}

# Función para limpiar backups antiguos
cleanup_old_backups() {
    log_info "Limpiando backups antiguos..."
    
    local cutoff_date=$(date -d "$BACKUP_RETENTION_DAYS days ago" +%s)
    local removed_count=0
    
    # Limpiar backups incrementales
    for backup_dir in "$BACKUP_ROOT/configs"/*; do
        if [[ -d "$backup_dir" ]]; then
            local backup_date=$(stat -c %Y "$backup_dir")
            if [[ $backup_date -lt $cutoff_date ]]; then
                rm -rf "$backup_dir"
                removed_count=$((removed_count + 1))
                log_info "Backup antiguo eliminado: $(basename "$backup_dir")"
            fi
        fi
    done
    
    # Limpiar backups completos
    for backup_file in "$BACKUP_ROOT/data"/*.tar.*; do
        if [[ -f "$backup_file" ]]; then
            local backup_date=$(stat -c %Y "$backup_file")
            if [[ $backup_date -lt $cutoff_date ]]; then
                rm "$backup_file"
                removed_count=$((removed_count + 1))
                log_info "Backup completo eliminado: $(basename "$backup_file")"
            fi
        fi
    done
    
    # Limpiar puntos de restauración antiguos
    for point_dir in "$BACKUP_ROOT/data/restore_points"/*; do
        if [[ -d "$point_dir" ]]; then
            local point_date=$(stat -c %Y "$point_dir")
            if [[ $point_date -lt $cutoff_date ]]; then
                rm -rf "$point_dir"
                removed_count=$((removed_count + 1))
                log_info "Punto de restauración eliminado: $(basename "$point_dir")"
            fi
        fi
    done
    
    log_info "Limpieza completada: $removed_count elementos eliminados"
}

# Función para verificar integridad de backups
verify_backup_integrity() {
    local backup_name="$1"
    local backup_dir="$BACKUP_ROOT/configs/$backup_name"
    
    log_info "Verificando integridad del backup: $backup_name"
    
    if [[ ! -d "$backup_dir" ]]; then
        log_error "Backup no encontrado: $backup_name"
        return 1
    fi
    
    local integrity_ok=true
    local metadata_file="$backup_dir/backup_metadata.txt"
    
    # Verificar metadatos
    if [[ ! -f "$metadata_file" ]]; then
        log_warn "Archivo de metadatos no encontrado"
        integrity_ok=false
    fi
    
    # Verificar checksums si están disponibles
    if [[ -f "$metadata_file" ]]; then
        local checksum_section=false
        while IFS= read -r line; do
            if [[ "$line" == "--- Checksums ---" ]]; then
                checksum_section=true
                continue
            fi
            
            if [[ "$checksum_section" == "true" ]] && [[ -n "$line" ]]; then
                local expected_checksum=$(echo "$line" | cut -d' ' -f1)
                local file_path=$(echo "$line" | cut -d' ' -f3)
                local full_path="$backup_dir/$file_path"
                
                if [[ -f "$full_path" ]]; then
                    local actual_checksum=$(sha256sum "$full_path" | cut -d' ' -f1)
                    if [[ "$expected_checksum" != "$actual_checksum" ]]; then
                        log_warn "Checksum incorrecto: $file_path"
                        integrity_ok=false
                    fi
                else
                    log_warn "Archivo no encontrado: $file_path"
                    integrity_ok=false
                fi
            fi
        done < "$metadata_file"
    fi
    
    if [[ "$integrity_ok" == "true" ]]; then
        log_info "Integridad del backup verificada: OK"
        return 0
    else
        log_warn "Integridad del backup verificada: ERROR"
        return 1
    fi
}

# Función para generar reporte de backup
generate_backup_report() {
    local report_file="${1:-/tmp/hyprdream_backup_report.txt}"
    
    log_info "Generando reporte de backup..."
    
    {
        echo "=== Reporte de Sistema de Backup ==="
        echo "Fecha: $(date)"
        echo "Directorio raíz: $BACKUP_ROOT"
        echo "Retención: $BACKUP_RETENTION_DAYS días"
        echo "Compresión: $BACKUP_COMPRESSION"
        echo "Encriptación: $BACKUP_ENCRYPTION"
        echo ""
        
        echo "--- Estadísticas de Backup ---"
        local total_backups=$(find "$BACKUP_ROOT/configs" -maxdepth 1 -type d | wc -l)
        total_backups=$((total_backups - 1))  # Excluir directorio configs
        echo "Backups incrementales: $total_backups"
        
        local total_full_backups=$(find "$BACKUP_ROOT/data" -name "*.tar.*" | wc -l)
        echo "Backups completos: $total_full_backups"
        
        local total_restore_points=$(find "$BACKUP_ROOT/data/restore_points" -maxdepth 1 -type d 2>/dev/null | wc -l)
        total_restore_points=$((total_restore_points - 1))  # Excluir directorio restore_points
        echo "Puntos de restauración: $total_restore_points"
        echo ""
        
        echo "--- Espacio Utilizado ---"
        local total_size=$(du -sh "$BACKUP_ROOT" | cut -f1)
        echo "Tamaño total: $total_size"
        echo ""
        
        echo "--- Backups Recientes ---"
        for backup_dir in $(find "$BACKUP_ROOT/configs" -maxdepth 1 -type d -printf '%T@ %p\n' | sort -n | tail -5 | cut -d' ' -f2-); do
            if [[ "$backup_dir" != "$BACKUP_ROOT/configs" ]]; then
                local backup_name=$(basename "$backup_dir")
                local backup_date=$(stat -c %y "$backup_dir" | cut -d' ' -f1)
                local backup_size=$(du -sh "$backup_dir" | cut -f1)
                echo "  • $backup_name - $backup_date - $backup_size"
            fi
        done
        
    } > "$report_file"
    
    log_info "Reporte generado: $report_file"
}

# Función para programar backup automático
schedule_automatic_backup() {
    if [[ "$AUTO_BACKUP" != "true" ]]; then
        log_info "Backup automático deshabilitado"
        return 0
    fi
    
    log_info "Programando backup automático cada $BACKUP_INTERVAL_HOURS horas..."
    
    # Crear script de backup automático
    local auto_backup_script="$BACKUP_ROOT/auto_backup.sh"
    
    cat << 'EOF' > "$auto_backup_script"
#!/usr/bin/env bash
# Script de backup automático para hyprland-dream

source "$(dirname "$0")/../core/colors.sh"
source "$(dirname "$0")/../core/logger.sh"

# Crear backup incremental
create_incremental_backup "critical" "auto_$(date +%Y%m%d_%H%M%S)"

# Crear backup completo semanal
if [[ $(date +%u) -eq 1 ]]; then  # Lunes
    create_full_backup "weekly_$(date +%Y%m%d_%H%M%S)"
fi

# Limpiar backups antiguos
cleanup_old_backups
EOF
    
    chmod +x "$auto_backup_script"
    
    # Agregar a crontab si no existe
    if ! crontab -l 2>/dev/null | grep -q "$auto_backup_script"; then
        (crontab -l 2>/dev/null; echo "0 */$BACKUP_INTERVAL_HOURS * * * $auto_backup_script") | crontab -
        log_info "Backup automático programado en crontab"
    fi
}

# Ejecutar si se llama directamente
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    init_logger
    
    case "${1:-help}" in
        "init")
            init_intelligent_backup
            ;;
        "backup")
            shift
            case "${1:-critical}" in
                "critical"|"important"|"user_data"|"system")
                    create_incremental_backup "$1"
                    ;;
                "full")
                    create_full_backup
                    ;;
                *)
                    create_incremental_backup "$1"
                    ;;
            esac
            ;;
        "restore")
            shift
            restore_from_backup "$1" "${2:-critical}"
            ;;
        "list")
            list_available_backups
            ;;
        "verify")
            shift
            verify_backup_integrity "$1"
            ;;
        "cleanup")
            cleanup_old_backups
            ;;
        "report")
            generate_backup_report
            ;;
        "schedule")
            schedule_automatic_backup
            ;;
        *)
            echo "Uso: $0 [init|backup|restore|list|verify|cleanup|report|schedule]"
            echo "  backup [critical|important|user_data|system|full] - Crear backup"
            echo "  restore <backup_name> [type] - Restaurar desde backup"
            echo "  list - Listar backups disponibles"
            echo "  verify <backup_name> - Verificar integridad"
            echo "  cleanup - Limpiar backups antiguos"
            echo "  report - Generar reporte de backup"
            echo "  schedule - Programar backup automático"
            ;;
    esac
fi 