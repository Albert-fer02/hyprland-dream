#!/usr/bin/env bash
# Gestión avanzada de dispositivos de audio con soporte Bluetooth
# Soporte para múltiples sinks, perfiles de audio y normalización

set -euo pipefail

# --- CONFIGURACIÓN ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CACHE_DIR="$HOME/.cache/hyprland-dream/audio"
CONFIG_DIR="$HOME/.config/hyprland-dream/audio"
LOG_FILE="$CACHE_DIR/audio-switcher.log"

# Crear directorios necesarios
mkdir -p "$CACHE_DIR" "$CONFIG_DIR"

# --- FUNCIONES ---

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

die() {
    log "ERROR: $1"
    echo "ERROR: $1" >&2
    exit 1
}

usage() {
    cat << EOF
Uso: $0 [COMANDO] [OPCIONES]

Comandos:
  list           Lista todos los dispositivos de audio
  switch         Cambia entre dispositivos (interactivo)
  set-default    Establece dispositivo por defecto
  move-apps      Mueve aplicaciones al dispositivo actual
  bluetooth      Gestiona dispositivos Bluetooth
  profiles       Gestiona perfiles de audio
  normalize      Normaliza volumen entre dispositivos
  info           Muestra información del dispositivo actual
  monitor        Monitorea cambios de dispositivos

Opciones:
  --device=NAME  Especifica dispositivo específico
  --profile=NAME Especifica perfil de audio
  --quiet        Sin notificaciones
  --debug        Modo debug

Ejemplos:
  $0 list
  $0 switch
  $0 set-default --device=alsa_output.pci-0000_00_1f.3.analog-stereo
  $0 bluetooth --connect=00:11:22:33:44:55
EOF
    exit 1
}

# Obtener información del sink actual
get_current_sink() {
    pactl info | grep "Default Sink:" | awk '{print $3}'
}

# Obtener información del sink por índice
get_sink_info() {
    local sink_index="$1"
    pactl list sinks | awk -v sink="$sink_index" '
        /^Sink #'$sink_index'$/ { in_sink=1; next }
        /^Sink #/ { in_sink=0 }
        in_sink {
            if ($1 == "Name:") name=$2
            if ($1 == "Description:") desc=substr($0, index($0, $2))
            if ($1 == "State:") state=$2
            if ($1 == "Volume:") volume=$2
            if ($1 == "Mute:") mute=$2
        }
        END {
            print name "\t" desc "\t" state "\t" volume "\t" mute
        }
    '
}

# Listar todos los sinks con información detallada
list_sinks() {
    echo "Dispositivos de audio disponibles:"
    echo "=================================="
    
    local current_sink=$(get_current_sink)
    local sink_count=0
    
    while IFS=$'\t' read -r index name description state volume mute; do
        ((sink_count++))
        local status=""
        local icon=""
        
        # Determinar icono según el tipo de dispositivo
        if [[ "$description" == *"Bluetooth"* ]] || [[ "$name" == *"bluez"* ]]; then
            icon="󰂯"
        elif [[ "$description" == *"HDMI"* ]]; then
            icon="󰈹"
        elif [[ "$description" == *"USB"* ]]; then
            icon="󰈹"
        else
            icon="󰓃"
        fi
        
        # Marcar dispositivo actual
        if [[ "$name" == "$current_sink" ]]; then
            status=" (ACTUAL)"
        fi
        
        # Mostrar información del dispositivo
        echo "  $icon $description$status"
        echo "    Nombre: $name"
        echo "    Estado: $state"
        echo "    Volumen: $volume"
        echo "    Silenciado: $mute"
        echo ""
    done < <(pactl list sinks short | while read -r index name description; do
        get_sink_info "$index"
    done)
    
    if [[ $sink_count -eq 0 ]]; then
        echo "No se encontraron dispositivos de audio"
    fi
}

# Cambiar dispositivo de audio
switch_device() {
    local target_device="${1:-}"
    
    if [[ -z "$target_device" ]]; then
        # Mostrar menú interactivo
        local devices=()
        local current_sink=$(get_current_sink)
        
        while IFS=$'\t' read -r index name description state volume mute; do
            local display_name="$description"
            if [[ "$name" == "$current_sink" ]]; then
                display_name="* $display_name"
            fi
            devices+=("$display_name" "$name")
        done < <(pactl list sinks short | while read -r index name description; do
            get_sink_info "$index"
        done)
        
        if [[ ${#devices[@]} -eq 0 ]]; then
            die "No hay dispositivos de audio disponibles"
        fi
        
        # Usar rofi si está disponible
        if command -v rofi >/dev/null 2>&1; then
            local options=""
            for ((i=0; i<${#devices[@]}; i+=2)); do
                options+="${devices[i]}\n"
            done
            
            local selected=$(echo -e "$options" | rofi -dmenu -p "Seleccionar dispositivo" -theme ~/.config/rofi/config.rasi)
            if [[ -z "$selected" ]]; then
                return 1
            fi
            
            # Encontrar el nombre del sink correspondiente
            for ((i=0; i<${#devices[@]}; i+=2)); do
                if [[ "${devices[i]}" == "$selected" ]]; then
                    target_device="${devices[i+1]}"
                    break
                fi
            done
        else
            # Fallback: usar el primer dispositivo
            target_device="${devices[1]}"
        fi
    fi
    
    if [[ -z "$target_device" ]]; then
        die "No se seleccionó ningún dispositivo"
    fi
    
    # Verificar que el dispositivo existe
    if ! pactl list sinks short | grep -q "^[0-9].*$target_device"; then
        die "Dispositivo '$target_device' no encontrado"
    fi
    
    # Cambiar dispositivo por defecto
    pactl set-default-sink "$target_device"
    
    # Mover todas las aplicaciones al nuevo sink
    move_applications_to_sink "$target_device"
    
    # Obtener descripción del dispositivo
    local description=$(pactl list sinks | awk -v sink="$target_device" '
        $1 == "Name:" && $2 == sink { in_sink=1; next }
        /^Sink / { in_sink=0 }
        in_sink && $1 == "Description:" { print substr($0, index($0, $2)); exit }
    ')
    
    # Enviar notificación
    if [[ "$QUIET" != "true" ]]; then
        notify-send "Dispositivo de audio cambiado" "$description" -u low -i "audio-card-symbolic"
    fi
    
    log "Dispositivo cambiado a: $target_device ($description)"
    echo "Dispositivo cambiado a: $description"
}

# Mover aplicaciones a un sink específico
move_applications_to_sink() {
    local target_sink="$1"
    
    # Obtener todas las aplicaciones de audio activas
    local moved_count=0
    while read -r app_index; do
        if [[ -n "$app_index" ]]; then
            pactl move-sink-input "$app_index" "$target_sink" 2>/dev/null && ((moved_count++))
        fi
    done < <(pactl list sink-inputs short | awk '{print $1}')
    
    log "Movidas $moved_count aplicaciones al sink $target_sink"
}

# Gestionar dispositivos Bluetooth
manage_bluetooth() {
    local action="${1:-}"
    
    case "$action" in
        list)
            echo "Dispositivos Bluetooth disponibles:"
            bluetoothctl devices | while read -r device; do
                echo "  $device"
            done
            ;;
        connect)
            local device_mac="${2:-}"
            if [[ -z "$device_mac" ]]; then
                die "Debe especificar la MAC del dispositivo Bluetooth"
            fi
            bluetoothctl connect "$device_mac"
            ;;
        disconnect)
            local device_mac="${2:-}"
            if [[ -z "$device_mac" ]]; then
                die "Debe especificar la MAC del dispositivo Bluetooth"
            fi
            bluetoothctl disconnect "$device_mac"
            ;;
        scan)
            echo "Escaneando dispositivos Bluetooth..."
            bluetoothctl scan on
            sleep 10
            bluetoothctl scan off
            ;;
        *)
            echo "Acciones Bluetooth disponibles:"
            echo "  list       - Lista dispositivos"
            echo "  connect    - Conecta dispositivo"
            echo "  disconnect - Desconecta dispositivo"
            echo "  scan       - Escanea nuevos dispositivos"
            ;;
    esac
}

# Gestionar perfiles de audio
manage_audio_profiles() {
    local action="${1:-}"
    local profile_name="${2:-}"
    
    case "$action" in
        list)
            echo "Perfiles de audio disponibles:"
            local current_sink=$(get_current_sink)
            pactl list sinks | awk -v sink="$current_sink" '
                $1 == "Name:" && $2 == sink { in_sink=1; next }
                /^Sink / { in_sink=0 }
                in_sink && $1 == "Active" { print "  " $0 }
            '
            ;;
        set)
            if [[ -z "$profile_name" ]]; then
                die "Debe especificar el nombre del perfil"
            fi
            local current_sink=$(get_current_sink)
            pactl set-sink-port "$current_sink" "$profile_name"
            ;;
        *)
            echo "Acciones de perfiles disponibles:"
            echo "  list - Lista perfiles disponibles"
            echo "  set  - Establece perfil específico"
            ;;
    esac
}

# Normalizar volumen entre dispositivos
normalize_volume() {
    local target_volume="${1:-50}"
    
    echo "Normalizando volumen a $target_volume% en todos los dispositivos..."
    
    local normalized_count=0
    while read -r sink_index sink_name; do
        if pactl set-sink-volume "$sink_name" "$target_volume%" 2>/dev/null; then
            ((normalized_count++))
            log "Volumen normalizado en $sink_name"
        fi
    done < <(pactl list sinks short | awk '{print $1, $2}')
    
    if [[ "$QUIET" != "true" ]]; then
        notify-send "Volumen normalizado" "Establecido en $target_volume% en $normalized_count dispositivos" -u low -i "audio-volume-medium-symbolic"
    fi
    
    echo "Volumen normalizado en $normalized_count dispositivos"
}

# Mostrar información del dispositivo actual
show_device_info() {
    local current_sink=$(get_current_sink)
    
    if [[ -z "$current_sink" ]]; then
        die "No hay dispositivo de audio activo"
    fi
    
    echo "Información del dispositivo actual:"
    echo "==================================="
    
    pactl list sinks | awk -v sink="$current_sink" '
        $1 == "Name:" && $2 == sink { in_sink=1; next }
        /^Sink / { in_sink=0 }
        in_sink {
            if ($1 == "Description:") print "Descripción: " substr($0, index($0, $2))
            if ($1 == "State:") print "Estado: " $2
            if ($1 == "Volume:") print "Volumen: " $2
            if ($1 == "Mute:") print "Silenciado: " $2
            if ($1 == "Active") print "Perfil activo: " $0
        }
    '
    
    echo ""
    echo "Aplicaciones usando este dispositivo:"
    echo "====================================="
    
    local app_count=0
    while read -r app_index app_name; do
        if [[ -n "$app_index" ]]; then
            echo "  $app_name (ID: $app_index)"
            ((app_count++))
        fi
    done < <(pactl list sink-inputs | awk -v sink="$current_sink" '
        $1 == "Sink Input" { sink_input=$3 }
        $1 == "application.name" { app_name=$3 }
        $1 == "Sink:" && $2 == sink && app_name { print sink_input "\t" app_name }
    ')
    
    if [[ $app_count -eq 0 ]]; then
        echo "  Ninguna aplicación activa"
    fi
}

# Monitorear cambios de dispositivos
monitor_devices() {
    echo "Monitoreando cambios de dispositivos de audio..."
    echo "Presiona Ctrl+C para detener"
    
    pactl subscribe | while read -r event; do
        if echo "$event" | grep -q "sink"; then
            local current_sink=$(get_current_sink)
            local description=$(pactl list sinks | awk -v sink="$current_sink" '
                $1 == "Name:" && $2 == sink { in_sink=1; next }
                /^Sink / { in_sink=0 }
                in_sink && $1 == "Description:" { print substr($0, index($0, $2)); exit }
            ')
            
            echo "[$(date '+%H:%M:%S')] Dispositivo actual: $description"
            
            if [[ "$QUIET" != "true" ]]; then
                notify-send "Cambio de dispositivo" "$description" -u low -i "audio-card-symbolic"
            fi
        fi
    done
}

# --- VALIDACIONES ---

command -v pactl >/dev/null 2>&1 || die "pactl no está instalado"
command -v notify-send >/dev/null 2>&1 || die "notify-send no está disponible"

# --- VARIABLES GLOBALES ---
QUIET=false
DEBUG=false

# --- PARSING DE ARGUMENTOS ---
while [[ $# -gt 0 ]]; do
    case $1 in
        --quiet)
            QUIET=true
            shift
            ;;
        --debug)
            DEBUG=true
            shift
            ;;
        -h|--help)
            usage
            ;;
        *)
            break
            ;;
    esac
done

COMMAND="${1:-}"
if [[ -z "$COMMAND" ]]; then
    usage
fi

# --- LÓGICA PRINCIPAL ---

if [[ "$DEBUG" == "true" ]]; then
    log "Comando ejecutado: $0 $*"
fi

case "$COMMAND" in
    list)
        list_sinks
        ;;
    switch)
        switch_device "$2"
        ;;
    set-default)
        if [[ -z "$2" ]]; then
            die "Debe especificar el dispositivo"
        fi
        switch_device "$2"
        ;;
    move-apps)
        local current_sink=$(get_current_sink)
        move_applications_to_sink "$current_sink"
        ;;
    bluetooth)
        manage_bluetooth "$2" "$3"
        ;;
    profiles)
        manage_audio_profiles "$2" "$3"
        ;;
    normalize)
        normalize_volume "$2"
        ;;
    info)
        show_device_info
        ;;
    monitor)
        monitor_devices
        ;;
    *)
        usage
        ;;
esac
