#!/usr/bin/env bash
# Sistema de monitoreo avanzado para hyprland-dream
# Supervisa rendimiento, salud del sistema y optimizaciones automáticas

source "$(dirname "$0")/colors.sh"
source "$(dirname "$0")/logger.sh"

# Configuración
MONITORING_INTERVAL="${MONITORING_INTERVAL:-30}"  # segundos
LOG_FILE="${LOG_FILE:-/tmp/hyprdream_monitoring.log}"
ALERT_THRESHOLD_CPU="${ALERT_THRESHOLD_CPU:-80}"
ALERT_THRESHOLD_MEMORY="${ALERT_THRESHOLD_MEMORY:-85}"
ALERT_THRESHOLD_DISK="${ALERT_THRESHOLD_DISK:-90}"
ALERT_THRESHOLD_TEMP="${ALERT_THRESHOLD_TEMP:-80}"

# Variables globales
declare -A SYSTEM_METRICS=()
declare -A PERFORMANCE_HISTORY=()
declare -A ALERT_HISTORY=()
MONITORING_ACTIVE=false

# Función para inicializar el sistema de monitoreo
init_advanced_monitoring() {
    log_info "Inicializando sistema de monitoreo avanzado..."
    
    # Verificar herramientas de monitoreo
    check_monitoring_tools
    
    # Crear directorio de logs
    mkdir -p "$(dirname "$LOG_FILE")"
    
    # Inicializar métricas del sistema
    initialize_system_metrics
    
    # Configurar señales de interrupción
    trap cleanup_monitoring EXIT INT TERM
    
    log_info "Sistema de monitoreo avanzado inicializado"
}

# Función para verificar herramientas de monitoreo
check_monitoring_tools() {
    local required_tools=("top" "free" "df" "uptime")
    local optional_tools=("htop" "iotop" "nethogs" "sensors")
    
    log_info "Verificando herramientas de monitoreo..."
    
    for tool in "${required_tools[@]}"; do
        if ! command -v "$tool" &>/dev/null; then
            log_warn "Herramienta de monitoreo faltante: $tool"
        fi
    done
    
    for tool in "${optional_tools[@]}"; do
        if command -v "$tool" &>/dev/null; then
            log_info "Herramienta opcional disponible: $tool"
        fi
    done
}

# Función para inicializar métricas del sistema
initialize_system_metrics() {
    log_info "Inicializando métricas del sistema..."
    
    # Métricas básicas
    SYSTEM_METRICS["cpu_cores"]=$(nproc)
    SYSTEM_METRICS["total_memory"]=$(free -m | awk 'NR==2{print $2}')
    SYSTEM_METRICS["total_disk"]=$(df / | awk 'NR==2{print $2}')
    
    # Detectar tipo de sistema
    if [[ -f /sys/class/dmi/id/chassis_type ]]; then
        local chassis_type=$(cat /sys/class/dmi/id/chassis_type)
        if [[ "$chassis_type" == "10" || "$chassis_type" == "8" ]]; then
            SYSTEM_METRICS["system_type"]="laptop"
        else
            SYSTEM_METRICS["system_type"]="desktop"
        fi
    else
        SYSTEM_METRICS["system_type"]="unknown"
    fi
    
    # Detectar GPU
    if lspci | grep -i nvidia &>/dev/null; then
        SYSTEM_METRICS["gpu_type"]="nvidia"
    elif lspci | grep -i amd &>/dev/null; then
        SYSTEM_METRICS["gpu_type"]="amd"
    elif lspci | grep -i intel &>/dev/null; then
        SYSTEM_METRICS["gpu_type"]="intel"
    else
        SYSTEM_METRICS["gpu_type"]="unknown"
    fi
    
    log_info "Métricas del sistema inicializadas"
}

# Función para recolectar métricas del sistema
collect_system_metrics() {
    local timestamp=$(date +%s)
    
    # CPU
    SYSTEM_METRICS["cpu_usage"]=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
    
    # Memoria
    local memory_info=$(free -m | awk 'NR==2{print $3 " " $2}')
    SYSTEM_METRICS["memory_used"]=$(echo "$memory_info" | awk '{print $1}')
    SYSTEM_METRICS["memory_total"]=$(echo "$memory_info" | awk '{print $2}')
    SYSTEM_METRICS["memory_usage"]=$(echo "scale=1; ${SYSTEM_METRICS[memory_used]} * 100 / ${SYSTEM_METRICS[memory_total]}" | bc -l 2>/dev/null || echo "0")
    
    # Disco
    local disk_info=$(df / | awk 'NR==2{print $3 " " $2}')
    SYSTEM_METRICS["disk_used"]=$(echo "$disk_info" | awk '{print $1}')
    SYSTEM_METRICS["disk_total"]=$(echo "$disk_info" | awk '{print $2}')
    SYSTEM_METRICS["disk_usage"]=$(echo "scale=1; ${SYSTEM_METRICS[disk_used]} * 100 / ${SYSTEM_METRICS[disk_total]}" | bc -l 2>/dev/null || echo "0")
    
    # Temperatura (si está disponible)
    if command -v sensors &>/dev/null; then
        local temp=$(sensors | grep "Core 0" | awk '{print $3}' | sed 's/+//' | sed 's/°C//' 2>/dev/null || echo "0")
        SYSTEM_METRICS["temperature"]="$temp"
    else
        SYSTEM_METRICS["temperature"]="0"
    fi
    
    # Uptime
    SYSTEM_METRICS["uptime"]=$(uptime -p | sed 's/up //')
    
    # Procesos
    SYSTEM_METRICS["processes"]=$(ps aux | wc -l)
    
    # Almacenar en historial
    PERFORMANCE_HISTORY["$timestamp"]="${SYSTEM_METRICS[cpu_usage]}:${SYSTEM_METRICS[memory_usage]}:${SYSTEM_METRICS[disk_usage]}:${SYSTEM_METRICS[temperature]}"
    
    # Limpiar historial antiguo (mantener solo últimas 100 entradas)
    cleanup_old_history
}

# Función para limpiar historial antiguo
cleanup_old_history() {
    local max_entries=100
    local current_entries=${#PERFORMANCE_HISTORY[@]}
    
    if [[ $current_entries -gt $max_entries ]]; then
        local entries_to_remove=$((current_entries - max_entries))
        local sorted_keys=($(printf '%s\n' "${!PERFORMANCE_HISTORY[@]}" | sort -n))
        
        for ((i=0; i<entries_to_remove; i++)); do
            unset PERFORMANCE_HISTORY["${sorted_keys[$i]}"]
        done
    fi
}

# Función para analizar métricas y generar alertas
analyze_metrics_and_alerts() {
    local alerts=()
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Verificar CPU
    if [[ "${SYSTEM_METRICS[cpu_usage]}" -gt $ALERT_THRESHOLD_CPU ]]; then
        alerts+=("CPU usage: ${SYSTEM_METRICS[cpu_usage]}% (threshold: ${ALERT_THRESHOLD_CPU}%)")
    fi
    
    # Verificar memoria
    if [[ "${SYSTEM_METRICS[memory_usage]%.*}" -gt $ALERT_THRESHOLD_MEMORY ]]; then
        alerts+=("Memory usage: ${SYSTEM_METRICS[memory_usage]}% (threshold: ${ALERT_THRESHOLD_MEMORY}%)")
    fi
    
    # Verificar disco
    if [[ "${SYSTEM_METRICS[disk_usage]%.*}" -gt $ALERT_THRESHOLD_DISK ]]; then
        alerts+=("Disk usage: ${SYSTEM_METRICS[disk_usage]}% (threshold: ${ALERT_THRESHOLD_DISK}%)")
    fi
    
    # Verificar temperatura
    if [[ "${SYSTEM_METRICS[temperature]%.*}" -gt $ALERT_THRESHOLD_TEMP ]]; then
        alerts+=("Temperature: ${SYSTEM_METRICS[temperature]}°C (threshold: ${ALERT_THRESHOLD_TEMP}°C)")
    fi
    
    # Registrar alertas
    if [[ ${#alerts[@]} -gt 0 ]]; then
        for alert in "${alerts[@]}"; do
            log_warn "ALERTA: $alert"
            ALERT_HISTORY["$timestamp"]="$alert"
        done
        
        # Ejecutar acciones automáticas
        execute_automatic_actions "${alerts[@]}"
    fi
}

# Función para ejecutar acciones automáticas
execute_automatic_actions() {
    local alerts=("$@")
    
    log_info "Ejecutando acciones automáticas..."
    
    for alert in "${alerts[@]}"; do
        case "$alert" in
            *"Memory usage"*)
                handle_memory_alert
                ;;
            *"Disk usage"*)
                handle_disk_alert
                ;;
            *"Temperature"*)
                handle_temperature_alert
                ;;
            *"CPU usage"*)
                handle_cpu_alert
                ;;
        esac
    done
}

# Función para manejar alertas de memoria
handle_memory_alert() {
    log_info "Manejando alerta de memoria..."
    
    # Verificar si hay procesos consumiendo mucha memoria
    local high_memory_processes=$(ps aux --sort=-%mem | head -6 | tail -5)
    
    if [[ -n "$high_memory_processes" ]]; then
        log_warn "Procesos consumiendo mucha memoria:"
        echo "$high_memory_processes" | while read line; do
            log_warn "  $line"
        done
    fi
    
    # Sugerir limpieza de memoria
    log_info "Sugerencia: Ejecutar limpieza de memoria"
    echo "echo 1 > /proc/sys/vm/drop_caches" | sudo bash 2>/dev/null || true
}

# Función para manejar alertas de disco
handle_disk_alert() {
    log_info "Manejando alerta de disco..."
    
    # Encontrar archivos grandes
    local large_files=$(find /home -type f -size +100M 2>/dev/null | head -5)
    
    if [[ -n "$large_files" ]]; then
        log_warn "Archivos grandes encontrados:"
        echo "$large_files" | while read file; do
            local size=$(du -h "$file" 2>/dev/null | cut -f1)
            log_warn "  $file ($size)"
        done
    fi
    
    # Sugerir limpieza
    log_info "Sugerencia: Ejecutar limpieza de disco"
    sudo pacman -Sc --noconfirm 2>/dev/null || true
}

# Función para manejar alertas de temperatura
handle_temperature_alert() {
    log_info "Manejando alerta de temperatura..."
    
    # Verificar si es laptop
    if [[ "${SYSTEM_METRICS[system_type]}" == "laptop" ]]; then
        log_info "Laptop detectado - aplicando optimizaciones de temperatura"
        
        # Reducir brillo si es posible
        if command -v brightnessctl &>/dev/null; then
            local current_brightness=$(brightnessctl get)
            local new_brightness=$((current_brightness * 80 / 100))
            brightnessctl set "$new_brightness" 2>/dev/null || true
            log_info "Brillo reducido para bajar temperatura"
        fi
        
        # Sugerir ventilación
        log_warn "Sugerencia: Verificar ventilación del laptop"
    fi
    
    # Verificar procesos intensivos
    local intensive_processes=$(ps aux --sort=-%cpu | head -6 | tail -5)
    if [[ -n "$intensive_processes" ]]; then
        log_warn "Procesos intensivos detectados:"
        echo "$intensive_processes" | while read line; do
            log_warn "  $line"
        done
    fi
}

# Función para manejar alertas de CPU
handle_cpu_alert() {
    log_info "Manejando alerta de CPU..."
    
    # Verificar procesos consumiendo CPU
    local high_cpu_processes=$(ps aux --sort=-%cpu | head -6 | tail -5)
    
    if [[ -n "$high_cpu_processes" ]]; then
        log_warn "Procesos consumiendo mucha CPU:"
        echo "$high_cpu_processes" | while read line; do
            log_warn "  $line"
        done
    fi
    
    # Sugerir optimizaciones
    log_info "Sugerencia: Considerar cerrar aplicaciones innecesarias"
}

# Función para generar reporte de rendimiento
generate_performance_report() {
    local report_file="${1:-/tmp/hyprdream_performance_report.txt}"
    
    log_info "Generando reporte de rendimiento..."
    
    {
        echo "=== Reporte de Rendimiento del Sistema ==="
        echo "Fecha: $(date)"
        echo "Sistema: $(uname -a)"
        echo ""
        
        echo "--- Información del Sistema ---"
        echo "Tipo: ${SYSTEM_METRICS[system_type]}"
        echo "CPU: ${SYSTEM_METRICS[cpu_cores]} cores"
        echo "GPU: ${SYSTEM_METRICS[gpu_type]}"
        echo "Memoria total: ${SYSTEM_METRICS[total_memory]}MB"
        echo "Disco total: ${SYSTEM_METRICS[disk_total]}KB"
        echo "Uptime: ${SYSTEM_METRICS[uptime]}"
        echo ""
        
        echo "--- Métricas Actuales ---"
        echo "CPU: ${SYSTEM_METRICS[cpu_usage]}%"
        echo "Memoria: ${SYSTEM_METRICS[memory_usage]}% (${SYSTEM_METRICS[memory_used]}MB/${SYSTEM_METRICS[memory_total]}MB)"
        echo "Disco: ${SYSTEM_METRICS[disk_usage]}% (${SYSTEM_METRICS[disk_used]}KB/${SYSTEM_METRICS[disk_total]}KB)"
        echo "Temperatura: ${SYSTEM_METRICS[temperature]}°C"
        echo "Procesos: ${SYSTEM_METRICS[processes]}"
        echo ""
        
        echo "--- Historial de Rendimiento (últimas 10 entradas) ---"
        local count=0
        for timestamp in $(printf '%s\n' "${!PERFORMANCE_HISTORY[@]}" | sort -n | tail -10); do
            local data="${PERFORMANCE_HISTORY[$timestamp]}"
            local date_str=$(date -d "@$timestamp" '+%H:%M:%S')
            echo "$date_str: $data"
            count=$((count + 1))
        done
        echo ""
        
        echo "--- Alertas Recientes ---"
        local alert_count=0
        for timestamp in $(printf '%s\n' "${!ALERT_HISTORY[@]}" | sort -r | head -5); do
            echo "$timestamp: ${ALERT_HISTORY[$timestamp]}"
            alert_count=$((alert_count + 1))
        done
        if [[ $alert_count -eq 0 ]]; then
            echo "No hay alertas recientes"
        fi
        echo ""
        
        echo "--- Recomendaciones ---"
        generate_performance_recommendations
        
    } > "$report_file"
    
    log_info "Reporte generado: $report_file"
}

# Función para generar recomendaciones de rendimiento
generate_performance_recommendations() {
    local cpu_usage="${SYSTEM_METRICS[cpu_usage]%.*}"
    local memory_usage="${SYSTEM_METRICS[memory_usage]%.*}"
    local disk_usage="${SYSTEM_METRICS[disk_usage]%.*}"
    local temperature="${SYSTEM_METRICS[temperature]%.*}"
    
    echo "Basado en las métricas actuales:"
    echo ""
    
    if [[ $cpu_usage -gt 70 ]]; then
        echo "• CPU alta ($cpu_usage%): Considerar cerrar aplicaciones innecesarias"
    fi
    
    if [[ $memory_usage -gt 80 ]]; then
        echo "• Memoria alta ($memory_usage%): Ejecutar limpieza de memoria"
    fi
    
    if [[ $disk_usage -gt 85 ]]; then
        echo "• Disco alto ($disk_usage%): Ejecutar limpieza de disco"
    fi
    
    if [[ $temperature -gt 70 ]]; then
        echo "• Temperatura alta ($temperature°C): Verificar ventilación"
    fi
    
    if [[ $cpu_usage -lt 30 && $memory_usage -lt 50 && $disk_usage -lt 70 ]]; then
        echo "• Sistema funcionando bien - no se requieren acciones"
    fi
}

# Función para iniciar monitoreo continuo
start_continuous_monitoring() {
    log_info "Iniciando monitoreo continuo..."
    
    MONITORING_ACTIVE=true
    
    while [[ "$MONITORING_ACTIVE" == "true" ]]; do
        # Recolectar métricas
        collect_system_metrics
        
        # Analizar y generar alertas
        analyze_metrics_and_alerts
        
        # Esperar antes de la siguiente verificación
        sleep "$MONITORING_INTERVAL"
    done
}

# Función para detener monitoreo
stop_monitoring() {
    log_info "Deteniendo monitoreo..."
    MONITORING_ACTIVE=false
}

# Función para limpiar al salir
cleanup_monitoring() {
    log_info "Limpiando sistema de monitoreo..."
    stop_monitoring
    
    # Generar reporte final
    generate_performance_report "/tmp/hyprdream_monitoring_final_report.txt"
    
    log_info "Sistema de monitoreo detenido"
}

# Función para mostrar métricas en tiempo real
show_realtime_metrics() {
    log_info "Mostrando métricas en tiempo real (Ctrl+C para salir)..."
    
    while true; do
        clear
        collect_system_metrics
        
        echo -e "${CYAN}=== Métricas del Sistema en Tiempo Real ===${RESET}"
        echo ""
        echo -e "${BLUE}CPU:${RESET} ${SYSTEM_METRICS[cpu_usage]}%"
        echo -e "${BLUE}Memoria:${RESET} ${SYSTEM_METRICS[memory_usage]}% (${SYSTEM_METRICS[memory_used]}MB/${SYSTEM_METRICS[memory_total]}MB)"
        echo -e "${BLUE}Disco:${RESET} ${SYSTEM_METRICS[disk_usage]}% (${SYSTEM_METRICS[disk_used]}KB/${SYSTEM_METRICS[disk_total]}KB)"
        echo -e "${BLUE}Temperatura:${RESET} ${SYSTEM_METRICS[temperature]}°C"
        echo -e "${BLUE}Procesos:${RESET} ${SYSTEM_METRICS[processes]}"
        echo -e "${BLUE}Uptime:${RESET} ${SYSTEM_METRICS[uptime]}"
        echo ""
        echo -e "${YELLOW}Actualizando cada $MONITORING_INTERVAL segundos...${RESET}"
        
        sleep "$MONITORING_INTERVAL"
    done
}

# Ejecutar si se llama directamente
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    init_logger
    
    case "${1:-help}" in
        "init")
            init_advanced_monitoring
            ;;
        "start")
            init_advanced_monitoring
            start_continuous_monitoring
            ;;
        "stop")
            stop_monitoring
            ;;
        "realtime")
            init_advanced_monitoring
            show_realtime_metrics
            ;;
        "report")
            init_advanced_monitoring
            collect_system_metrics
            generate_performance_report
            ;;
        "metrics")
            init_advanced_monitoring
            collect_system_metrics
            echo "CPU: ${SYSTEM_METRICS[cpu_usage]}%"
            echo "Memory: ${SYSTEM_METRICS[memory_usage]}%"
            echo "Disk: ${SYSTEM_METRICS[disk_usage]}%"
            echo "Temperature: ${SYSTEM_METRICS[temperature]}°C"
            ;;
        *)
            echo "Uso: $0 [init|start|stop|realtime|report|metrics]"
            echo "  start - Iniciar monitoreo continuo"
            echo "  stop - Detener monitoreo"
            echo "  realtime - Mostrar métricas en tiempo real"
            echo "  report - Generar reporte de rendimiento"
            echo "  metrics - Mostrar métricas actuales"
            ;;
    esac
fi 