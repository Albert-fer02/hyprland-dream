#!/usr/bin/env bash
# Detector de hardware para hyprdream
# Detecta automáticamente el hardware del sistema para optimizar la instalación

source "$(dirname "$0")/colors.sh"
source "$(dirname "$0")/logger.sh"

# Variables globales para hardware detectado
declare -A HARDWARE_INFO=()
declare -A GPU_INFO=()
declare -A AUDIO_INFO=()
declare -A NETWORK_INFO=()

# Función para detectar CPU
detect_cpu() {
    log_info "Detectando CPU..."
    
    if [[ -f /proc/cpuinfo ]]; then
        local cpu_model=$(grep "model name" /proc/cpuinfo | head -1 | cut -d: -f2 | sed 's/^[[:space:]]*//')
        local cpu_cores=$(nproc)
        local cpu_arch=$(uname -m)
        
        HARDWARE_INFO["cpu_model"]="$cpu_model"
        HARDWARE_INFO["cpu_cores"]="$cpu_cores"
        HARDWARE_INFO["cpu_arch"]="$cpu_arch"
        
        log_info "CPU detectado: $cpu_model ($cpu_cores cores, $cpu_arch)"
    else
        log_warn "No se pudo detectar información de CPU"
    fi
}

# Función para detectar GPU
detect_gpu() {
    log_info "Detectando GPU..."
    
    # Detectar GPUs NVIDIA
    if lspci | grep -i nvidia &>/dev/null; then
        local nvidia_gpu=$(lspci | grep -i nvidia | head -1 | cut -d: -f3 | sed 's/^[[:space:]]*//')
        GPU_INFO["nvidia"]="$nvidia_gpu"
        log_info "GPU NVIDIA detectada: $nvidia_gpu"
    fi
    
    # Detectar GPUs AMD
    if lspci | grep -i amd &>/dev/null; then
        local amd_gpu=$(lspci | grep -i amd | head -1 | cut -d: -f3 | sed 's/^[[:space:]]*//')
        GPU_INFO["amd"]="$amd_gpu"
        log_info "GPU AMD detectada: $amd_gpu"
    fi
    
    # Detectar GPUs Intel
    if lspci | grep -i intel &>/dev/null; then
        local intel_gpu=$(lspci | grep -i intel | head -1 | cut -d: -f3 | sed 's/^[[:space:]]*//')
        GPU_INFO["intel"]="$intel_gpu"
        log_info "GPU Intel detectada: $intel_gpu"
    fi
    
    # Detectar si es laptop
    if [[ -f /sys/class/dmi/id/chassis_type ]]; then
        local chassis_type=$(cat /sys/class/dmi/id/chassis_type)
        if [[ "$chassis_type" == "10" || "$chassis_type" == "8" ]]; then
            HARDWARE_INFO["is_laptop"]="true"
            log_info "Sistema detectado como laptop"
        else
            HARDWARE_INFO["is_laptop"]="false"
            log_info "Sistema detectado como desktop"
        fi
    fi
}

# Función para detectar audio
detect_audio() {
    log_info "Detectando hardware de audio..."
    
    # Detectar tarjeta de sonido
    if command -v pactl &>/dev/null; then
        local audio_card=$(pactl list cards short | head -1 | awk '{print $2}')
        if [[ -n "$audio_card" ]]; then
            AUDIO_INFO["card"]="$audio_card"
            log_info "Tarjeta de audio detectada: $audio_card"
        fi
    fi
    
    # Detectar si hay Bluetooth
    if command -v bluetoothctl &>/dev/null; then
        if systemctl is-active --quiet bluetooth; then
            AUDIO_INFO["bluetooth"]="true"
            log_info "Bluetooth detectado y activo"
        else
            AUDIO_INFO["bluetooth"]="false"
            log_info "Bluetooth no está activo"
        fi
    fi
    
    # Detectar si hay jack de auriculares
    if [[ -d /sys/class/sound ]]; then
        local headphone_jack=$(find /sys/class/sound -name "*headphone*" -o -name "*jack*" | head -1)
        if [[ -n "$headphone_jack" ]]; then
            AUDIO_INFO["headphone_jack"]="true"
            log_info "Jack de auriculares detectado"
        fi
    fi
}

# Función para detectar red
detect_network() {
    log_info "Detectando hardware de red..."
    
    # Detectar interfaces de red
    local interfaces=($(ip link show | grep -E "^[0-9]+:" | cut -d: -f2 | sed 's/^[[:space:]]*//'))
    
    for interface in "${interfaces[@]}"; do
        if [[ "$interface" != "lo" ]]; then
            if [[ "$interface" =~ ^wlan ]]; then
                NETWORK_INFO["wifi"]="$interface"
                log_info "Interfaz WiFi detectada: $interface"
            elif [[ "$interface" =~ ^en || "$interface" =~ ^eth ]]; then
                NETWORK_INFO["ethernet"]="$interface"
                log_info "Interfaz Ethernet detectada: $interface"
            fi
        fi
    done
    
    # Detectar si hay Bluetooth
    if command -v bluetoothctl &>/dev/null; then
        NETWORK_INFO["bluetooth"]="true"
        log_info "Bluetooth disponible para red"
    fi
}

# Función para detectar memoria
detect_memory() {
    log_info "Detectando memoria..."
    
    if [[ -f /proc/meminfo ]]; then
        local total_mem=$(grep "MemTotal" /proc/meminfo | awk '{print $2}')
        local total_mem_gb=$((total_mem / 1024 / 1024))
        
        HARDWARE_INFO["total_memory_gb"]="$total_mem_gb"
        log_info "Memoria total: ${total_mem_gb}GB"
        
        # Clasificar por cantidad de memoria
        if [[ $total_mem_gb -lt 4 ]]; then
            HARDWARE_INFO["memory_class"]="low"
        elif [[ $total_mem_gb -lt 8 ]]; then
            HARDWARE_INFO["memory_class"]="medium"
        else
            HARDWARE_INFO["memory_class"]="high"
        fi
    fi
}

# Función para detectar almacenamiento
detect_storage() {
    log_info "Detectando almacenamiento..."
    
    # Detectar tipo de disco principal
    local root_device=$(df / | tail -1 | awk '{print $1}')
    if [[ "$root_device" =~ /dev/nvme ]]; then
        HARDWARE_INFO["storage_type"]="nvme"
        log_info "Almacenamiento NVMe detectado"
    elif [[ "$root_device" =~ /dev/sd ]]; then
        HARDWARE_INFO["storage_type"]="ssd"
        log_info "Almacenamiento SSD detectado"
    else
        HARDWARE_INFO["storage_type"]="hdd"
        log_info "Almacenamiento HDD detectado"
    fi
    
    # Detectar espacio disponible
    local available_space=$(df / | tail -1 | awk '{print $4}')
    local available_gb=$((available_space / 1024 / 1024))
    HARDWARE_INFO["available_space_gb"]="$available_gb"
    log_info "Espacio disponible: ${available_gb}GB"
}

# Función para detectar batería (laptops)
detect_battery() {
    if [[ "${HARDWARE_INFO[is_laptop]}" == "true" ]]; then
        log_info "Detectando batería..."
        
        if [[ -d /sys/class/power_supply ]]; then
            local battery_count=$(find /sys/class/power_supply -name "BAT*" | wc -l)
            HARDWARE_INFO["battery_count"]="$battery_count"
            log_info "Baterías detectadas: $battery_count"
        fi
    fi
}

# Función para detectar sensores
detect_sensors() {
    log_info "Detectando sensores..."
    
    # Verificar si hay sensores de temperatura
    if command -v sensors &>/dev/null; then
        if sensors &>/dev/null; then
            HARDWARE_INFO["temperature_sensors"]="true"
            log_info "Sensores de temperatura disponibles"
        else
            HARDWARE_INFO["temperature_sensors"]="false"
            log_info "No hay sensores de temperatura"
        fi
    fi
    
    # Verificar si hay sensores de brillo
    if [[ -d /sys/class/backlight ]]; then
        local backlight_count=$(find /sys/class/backlight -type d | wc -l)
        if [[ $backlight_count -gt 1 ]]; then
            HARDWARE_INFO["brightness_sensors"]="true"
            log_info "Sensores de brillo disponibles"
        fi
    fi
}

# Función para generar recomendaciones basadas en hardware
generate_hardware_recommendations() {
    log_info "Generando recomendaciones basadas en hardware..."
    
    local recommendations=()
    
    # Recomendaciones basadas en GPU
    if [[ -n "${GPU_INFO[nvidia]}" ]]; then
        recommendations+=("nvidia-utils" "nvidia-settings")
    fi
    
    if [[ -n "${GPU_INFO[amd]}" ]]; then
        recommendations+=("mesa" "vulkan-radeon")
    fi
    
    if [[ -n "${GPU_INFO[intel]}" ]]; then
        recommendations+=("mesa" "vulkan-intel")
    fi
    
    # Recomendaciones basadas en memoria
    case "${HARDWARE_INFO[memory_class]}" in
        "low")
            recommendations+=("lightweight" "minimal")
            ;;
        "medium")
            recommendations+=("balanced")
            ;;
        "high")
            recommendations+=("full-featured" "performance")
            ;;
    esac
    
    # Recomendaciones para laptops
    if [[ "${HARDWARE_INFO[is_laptop]}" == "true" ]]; then
        recommendations+=("power-management" "battery-optimization")
        
        if [[ "${HARDWARE_INFO[battery_count]}" -gt 0 ]]; then
            recommendations+=("battery-monitoring")
        fi
    fi
    
    # Recomendaciones de audio
    if [[ "${AUDIO_INFO[bluetooth]}" == "true" ]]; then
        recommendations+=("bluetooth-audio")
    fi
    
    if [[ "${AUDIO_INFO[headphone_jack]}" == "true" ]]; then
        recommendations+=("headphone-control")
    fi
    
    # Recomendaciones de red
    if [[ -n "${NETWORK_INFO[wifi]}" ]]; then
        recommendations+=("wifi-management")
    fi
    
    if [[ -n "${NETWORK_INFO[bluetooth]}" ]]; then
        recommendations+=("bluetooth-management")
    fi
    
    # Recomendaciones de sensores
    if [[ "${HARDWARE_INFO[temperature_sensors]}" == "true" ]]; then
        recommendations+=("temperature-monitoring")
    fi
    
    if [[ "${HARDWARE_INFO[brightness_sensors]}" == "true" ]]; then
        recommendations+=("brightness-control")
    fi
    
    HARDWARE_INFO["recommendations"]="${recommendations[*]}"
    log_info "Recomendaciones generadas: ${recommendations[*]}"
}

# Función para mostrar resumen de hardware
show_hardware_summary() {
    echo -e "\n${CYAN}=== Resumen de Hardware Detectado ===${RESET}"
    
    echo -e "\n${BLUE}CPU:${RESET}"
    echo "  Modelo: ${HARDWARE_INFO[cpu_model]}"
    echo "  Cores: ${HARDWARE_INFO[cpu_cores]}"
    echo "  Arquitectura: ${HARDWARE_INFO[cpu_arch]}"
    
    echo -e "\n${BLUE}Memoria:${RESET}"
    echo "  Total: ${HARDWARE_INFO[total_memory_gb]}GB (${HARDWARE_INFO[memory_class]})"
    
    echo -e "\n${BLUE}Almacenamiento:${RESET}"
    echo "  Tipo: ${HARDWARE_INFO[storage_type]}"
    echo "  Espacio disponible: ${HARDWARE_INFO[available_space_gb]}GB"
    
    echo -e "\n${BLUE}Tipo de sistema:${RESET}"
    if [[ "${HARDWARE_INFO[is_laptop]}" == "true" ]]; then
        echo "  Laptop (${HARDWARE_INFO[battery_count]} baterías)"
    else
        echo "  Desktop"
    fi
    
    if [[ ${#GPU_INFO[@]} -gt 0 ]]; then
        echo -e "\n${BLUE}GPU:${RESET}"
        for gpu_type in "${!GPU_INFO[@]}"; do
            echo "  ${gpu_type^}: ${GPU_INFO[$gpu_type]}"
        done
    fi
    
    if [[ ${#AUDIO_INFO[@]} -gt 0 ]]; then
        echo -e "\n${BLUE}Audio:${RESET}"
        for audio_feature in "${!AUDIO_INFO[@]}"; do
            echo "  ${audio_feature}: ${AUDIO_INFO[$audio_feature]}"
        done
    fi
    
    if [[ ${#NETWORK_INFO[@]} -gt 0 ]]; then
        echo -e "\n${BLUE}Red:${RESET}"
        for net_feature in "${!NETWORK_INFO[@]}"; do
            echo "  ${net_feature}: ${NETWORK_INFO[$net_feature]}"
        done
    fi
    
    if [[ -n "${HARDWARE_INFO[recommendations]}" ]]; then
        echo -e "\n${BLUE}Recomendaciones:${RESET}"
        for rec in ${HARDWARE_INFO[recommendations]}; do
            echo "  • $rec"
        done
    fi
    
    echo ""
}

# Función principal de detección
detect_hardware() {
    log_info "Iniciando detección de hardware..."
    
    detect_cpu
    detect_gpu
    detect_audio
    detect_network
    detect_memory
    detect_storage
    detect_battery
    detect_sensors
    
    generate_hardware_recommendations
    
    log_info "Detección de hardware completada"
}

# Función para obtener información específica
get_hardware_info() {
    local key="$1"
    echo "${HARDWARE_INFO[$key]}"
}

# Función para obtener recomendaciones
get_hardware_recommendations() {
    echo "${HARDWARE_INFO[recommendations]}"
}

# Función para exportar información a archivo
export_hardware_info() {
    local output_file="${1:-/tmp/hyprdream_hardware.json}"
    
    {
        echo "{"
        echo "  \"hardware_info\": {"
        for key in "${!HARDWARE_INFO[@]}"; do
            echo "    \"$key\": \"${HARDWARE_INFO[$key]}\","
        done
        echo "  },"
        echo "  \"gpu_info\": {"
        for key in "${!GPU_INFO[@]}"; do
            echo "    \"$key\": \"${GPU_INFO[$key]}\","
        done
        echo "  },"
        echo "  \"audio_info\": {"
        for key in "${!AUDIO_INFO[@]}"; do
            echo "    \"$key\": \"${AUDIO_INFO[$key]}\","
        done
        echo "  },"
        echo "  \"network_info\": {"
        for key in "${!NETWORK_INFO[@]}"; do
            echo "    \"$key\": \"${NETWORK_INFO[$key]}\","
        done
        echo "  }"
        echo "}"
    } > "$output_file"
    
    log_info "Información de hardware exportada a: $output_file"
}

# Ejecutar si se llama directamente
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    init_logger
    
    case "${1:-detect}" in
        "detect")
            detect_hardware
            show_hardware_summary
            ;;
        "export")
            detect_hardware
            export_hardware_info "${2:-}"
            ;;
        "recommendations")
            detect_hardware
            get_hardware_recommendations
            ;;
        *)
            echo "Uso: $0 [detect|export|recommendations]"
            ;;
    esac
fi 