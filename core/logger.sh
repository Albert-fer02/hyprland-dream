#!/usr/bin/env bash
# Sistema de logging mejorado para hyprdream
# Niveles: DEBUG, INFO, WARN, ERROR, FATAL

# Configuración del logger
LOG_LEVEL="${LOG_LEVEL:-INFO}"
LOG_FILE="${LOG_FILE:-/tmp/hyprdream.log}"
LOG_MAX_SIZE="${LOG_MAX_SIZE:-10485760}"  # 10MB
LOG_MAX_FILES="${LOG_MAX_FILES:-5}"

# Niveles de log (mayor número = mayor prioridad)
declare -A LOG_LEVELS=(
    ["DEBUG"]=0
    ["INFO"]=1
    ["WARN"]=2
    ["ERROR"]=3
    ["FATAL"]=4
)

# Colores para diferentes niveles
declare -A LOG_COLORS=(
    ["DEBUG"]="$CYAN"
    ["INFO"]="$BLUE"
    ["WARN"]="$YELLOW"
    ["ERROR"]="$RED"
    ["FATAL"]="$MAGENTA"
)

# Función para obtener timestamp
get_timestamp() {
    date '+%Y-%m-%d %H:%M:%S'
}

# Función para verificar si un nivel debe ser logueado
should_log() {
    local level="$1"
    local current_level="${LOG_LEVELS[$LOG_LEVEL]}"
    local message_level="${LOG_LEVELS[$level]}"
    [[ $message_level -ge $current_level ]]
}

# Función para rotar logs si es necesario
rotate_logs() {
    if [[ -f "$LOG_FILE" ]]; then
        local size=$(stat -c%s "$LOG_FILE" 2>/dev/null || echo 0)
        if [[ $size -gt $LOG_MAX_SIZE ]]; then
            for ((i=$LOG_MAX_FILES; i>1; i--)); do
                local old_file="${LOG_FILE}.$((i-1))"
                local new_file="${LOG_FILE}.$i"
                if [[ -f "$old_file" ]]; then
                    mv "$old_file" "$new_file" 2>/dev/null || true
                fi
            done
            mv "$LOG_FILE" "${LOG_FILE}.1" 2>/dev/null || true
        fi
    fi
}

# Función principal de logging
log_message() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(get_timestamp)
    local color="${LOG_COLORS[$level]:-$RESET}"
    
    if should_log "$level"; then
        # Log a consola con colores
        echo -e "${color}[${level}]${RESET} $message" >&2
        
        # Log a archivo sin colores
        echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
    fi
}

# Funciones específicas por nivel
log_debug() { log_message "DEBUG" "$*"; }
log_info()  { log_message "INFO" "$*"; }
log_warn()  { log_message "WARN" "$*"; }
log_error() { log_message "ERROR" "$*"; }
log_fatal() { log_message "FATAL" "$*"; }

# Función para inicializar el logger
init_logger() {
    # Crear directorio de logs si no existe
    local log_dir=$(dirname "$LOG_FILE")
    mkdir -p "$log_dir"
    
    # Rotar logs si es necesario
    rotate_logs
    
    # Log de inicio
    log_info "Logger inicializado - Nivel: $LOG_LEVEL, Archivo: $LOG_FILE"
}

# Función para limpiar logs antiguos
cleanup_logs() {
    if [[ -f "$LOG_FILE" ]]; then
        local log_dir=$(dirname "$LOG_FILE")
        local log_base=$(basename "$LOG_FILE")
        
        # Eliminar logs más antiguos que LOG_MAX_FILES
        find "$log_dir" -name "${log_base}.*" -type f | sort | tail -n +$((LOG_MAX_FILES + 1)) | xargs rm -f 2>/dev/null || true
        log_info "Limpieza de logs completada"
    fi
}

# Función para mostrar estadísticas de logs
show_log_stats() {
    if [[ -f "$LOG_FILE" ]]; then
        echo "=== Estadísticas de Log ==="
        echo "Archivo: $LOG_FILE"
        echo "Tamaño: $(du -h "$LOG_FILE" | cut -f1)"
        echo "Líneas: $(wc -l < "$LOG_FILE")"
        echo "Última modificación: $(stat -c%y "$LOG_FILE")"
        echo ""
        echo "Últimas 10 líneas:"
        tail -n 10 "$LOG_FILE"
    else
        echo "No se encontró archivo de log: $LOG_FILE"
    fi
}

# Inicializar logger automáticamente si se ejecuta directamente
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    source "$(dirname "$0")/colors.sh"
    init_logger
    
    case "${1:-}" in
        "cleanup") cleanup_logs ;;
        "stats") show_log_stats ;;
        *) echo "Uso: $0 [cleanup|stats]" ;;
    esac
fi
