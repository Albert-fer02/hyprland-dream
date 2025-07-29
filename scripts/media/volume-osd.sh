#!/usr/bin/env bash
# Sistema avanzado de control de volumen con indicador visual (OSD)
# Soporte para múltiples dispositivos, normalización y perfiles

set -euo pipefail

# --- CONFIGURACIÓN ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CACHE_DIR="$HOME/.cache/hyprland-dream/volume"
CONFIG_DIR="$HOME/.config/hyprland-dream/volume"
LOG_FILE="$CACHE_DIR/volume-osd.log"

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
  up              Sube el volumen 5%
  down            Baja el volumen 5%
  set             Establece volumen específico (0-100)
  toggle-mute     Alterna silencio
  get             Obtiene volumen actual
  device-info     Muestra información del dispositivo
  normalize       Normaliza volumen entre dispositivos
  profile         Gestiona perfiles de volumen

Opciones:
  --device=NAME   Especifica dispositivo específico
  --step=N        Establece paso de volumen (default: 5)
  --quiet         Sin notificaciones
  --debug         Modo debug
  --visual        Modo visual con barra de progreso

Ejemplos:
  $0 up
  $0 set 75
  $0 toggle-mute
  $0 up --step=10
  $0 set 50 --device=alsa_output.pci-0000_00_1f.3.analog-stereo
EOF
    exit 1
}

# Obtener información del sink actual
get_current_sink() {
    pactl info | grep "Default Sink:" | awk '{print $3}'
}

# Obtener volumen actual
get_volume() {
    local device="${1:-}"
    if [[ -n "$device" ]]; then
        pamixer --sink "$device" --get-volume
    else
        pamixer --get-volume
    fi
}

# Verificar si está silenciado
is_muted() {
    local device="${1:-}"
    if [[ -n "$device" ]]; then
        pamixer --sink "$device" --get-mute
    else
        pamixer --get-mute
    fi
}

# Obtener icono según el volumen
get_volume_icon() {
    local volume="$1"
    local muted="$2"
    
    if [[ "$muted" == "true" ]]; then
        echo "audio-volume-muted-symbolic"
    elif (( volume > 80 )); then
        echo "audio-volume-high-symbolic"
    elif (( volume > 50 )); then
        echo "audio-volume-medium-symbolic"
    elif (( volume > 20 )); then
        echo "audio-volume-low-symbolic"
    else
        echo "audio-volume-off-symbolic"
    fi
}

# Crear barra de progreso visual
create_progress_bar() {
    local value="$1"
    local max="$2"
    local width="${3:-20}"
    
    local filled=$((value * width / max))
    local empty=$((width - filled))
    
    local bar=""
    for ((i=0; i<filled; i++)); do
        bar+="█"
    done
    for ((i=0; i<empty; i++)); do
        bar+="░"
    done
    
    echo "$bar"
}

# Enviar notificación con barra visual
send_visual_notification() {
    local title="$1"
    local volume="$2"
    local muted="$3"
    local device="$4"
    
    local icon=$(get_volume_icon "$volume" "$muted")
    local progress_bar=$(create_progress_bar "$volume" 100)
    
    local message=""
    if [[ "$muted" == "true" ]]; then
        message="Silenciado"
    else
        message="$progress_bar $volume%"
    fi
    
    # Agregar información del dispositivo si se especifica
    if [[ -n "$device" ]]; then
        local device_desc=$(pactl list sinks | awk -v sink="$device" '
            $1 == "Name:" && $2 == sink { in_sink=1; next }
            /^Sink / { in_sink=0 }
            in_sink && $1 == "Description:" { print substr($0, index($0, $2)); exit }
        ')
        message+="\n$device_desc"
    fi
    
    notify-send \
        -h "string:x-canonical-private-synchronous:volume-osd" \
        -h "int:value:$volume" \
        -u low \
        -i "$icon" \
        "$title" \
        "$message"
    
    log "Notificación de volumen: $title - $volume%"
}

# Control de volumen
control_volume() {
    local action="$1"
    local device="${2:-}"
    local value="${3:-5}"
    
    local pamixer_args=""
    if [[ -n "$device" ]]; then
        pamixer_args="--sink $device"
    fi
    
    case "$action" in
        up)
            pamixer $pamixer_args -i "$value"
            ;;
        down)
            pamixer $pamixer_args -d "$value"
            ;;
        set)
            pamixer $pamixer_args --set-volume "$value"
            ;;
        toggle-mute)
            pamixer $pamixer_args -t
            ;;
    esac
    
    # Obtener estado actual
    local volume=$(get_volume "$device")
    local muted=$(is_muted "$device")
    
    # Enviar notificación
    if [[ "$QUIET" != "true" ]]; then
        local title="Control de Volumen"
        if [[ "$action" == "toggle-mute" ]]; then
            if [[ "$muted" == "true" ]]; then
                title="Volumen Silenciado"
            else
                title="Volumen Activado"
            fi
        fi
        
        if [[ "$VISUAL" == "true" ]]; then
            send_visual_notification "$title" "$volume" "$muted" "$device"
        else
            local icon=$(get_volume_icon "$volume" "$muted")
            local message="Volumen: ${volume}%"
            if [[ "$muted" == "true" ]]; then
                message="Silenciado"
            fi
            notify-send \
                -h "string:x-canonical-private-synchronous:volume-osd" \
                -h "int:value:$volume" \
                -u low \
                -i "$icon" \
                "$title" \
                "$message"
        fi
    fi
    
    # Mostrar en consola si está en modo debug
    if [[ "$DEBUG" == "true" ]]; then
        echo "Volumen: $volume% (Silenciado: $muted)"
    fi
}

# Mostrar información del dispositivo
show_device_info() {
    local device="${1:-}"
    
    if [[ -z "$device" ]]; then
        device=$(get_current_sink)
    fi
    
    echo "Información del dispositivo de audio:"
    echo "===================================="
    
    local volume=$(get_volume "$device")
    local muted=$(is_muted "$device")
    local device_desc=$(pactl list sinks | awk -v sink="$device" '
        $1 == "Name:" && $2 == sink { in_sink=1; next }
        /^Sink / { in_sink=0 }
        in_sink && $1 == "Description:" { print substr($0, index($0, $2)); exit }
    ')
    
    echo "Dispositivo: $device"
    echo "Descripción: $device_desc"
    echo "Volumen: $volume%"
    echo "Silenciado: $muted"
    
    # Mostrar barra visual
    if [[ "$VISUAL" == "true" ]]; then
        local progress_bar=$(create_progress_bar "$volume" 100)
        echo "Progreso: $progress_bar"
    fi
}

# Normalizar volumen entre dispositivos
normalize_volume() {
    local target_volume="${1:-50}"
    
    echo "Normalizando volumen a $target_volume% en todos los dispositivos..."
    
    local normalized_count=0
    while read -r sink_index sink_name; do
        if pamixer --sink "$sink_name" --set-volume "$target_volume" 2>/dev/null; then
            ((normalized_count++))
            log "Volumen normalizado en $sink_name"
        fi
    done < <(pactl list sinks short | awk '{print $1, $2}')
    
    if [[ "$QUIET" != "true" ]]; then
        local progress_bar=$(create_progress_bar "$target_volume" 100)
        notify-send \
            -h "string:x-canonical-private-synchronous:volume-osd" \
            -h "int:value:$target_volume" \
            -u low \
            -i "audio-volume-medium-symbolic" \
            "Volumen Normalizado" \
            "$progress_bar $target_volume%\nEn $normalized_count dispositivos"
    fi
    
    echo "Volumen normalizado en $normalized_count dispositivos"
}

# Gestionar perfiles de volumen
manage_volume_profiles() {
    local action="${1:-}"
    local profile_name="${2:-}"
    
    case "$action" in
        list)
            echo "Perfiles de volumen disponibles:"
            if [[ -d "$CONFIG_DIR/profiles" ]]; then
                for profile in "$CONFIG_DIR/profiles"/*.conf; do
                    if [[ -f "$profile" ]]; then
                        echo "  $(basename "$profile" .conf)"
                    fi
                done
            else
                echo "  No hay perfiles configurados"
            fi
            ;;
        save)
            if [[ -z "$profile_name" ]]; then
                die "Debe especificar el nombre del perfil"
            fi
            mkdir -p "$CONFIG_DIR/profiles"
            local volume=$(get_volume)
            local muted=$(is_muted)
            echo "volume=$volume" > "$CONFIG_DIR/profiles/$profile_name.conf"
            echo "muted=$muted" >> "$CONFIG_DIR/profiles/$profile_name.conf"
            echo "Perfil '$profile_name' guardado"
            ;;
        load)
            if [[ -z "$profile_name" ]]; then
                die "Debe especificar el nombre del perfil"
            fi
            local profile_file="$CONFIG_DIR/profiles/$profile_name.conf"
            if [[ ! -f "$profile_file" ]]; then
                die "Perfil '$profile_name' no encontrado"
            fi
            source "$profile_file"
            control_volume "set" "" "$volume"
            if [[ "$muted" == "true" ]]; then
                control_volume "toggle-mute"
            fi
            echo "Perfil '$profile_name' cargado"
            ;;
        *)
            echo "Acciones de perfiles disponibles:"
            echo "  list - Lista perfiles disponibles"
            echo "  save - Guarda perfil actual"
            echo "  load - Carga perfil específico"
            ;;
    esac
}

# --- VALIDACIONES ---

command -v pamixer >/dev/null 2>&1 || die "pamixer no está instalado"
command -v pactl >/dev/null 2>&1 || die "pactl no está instalado"
command -v notify-send >/dev/null 2>&1 || die "notify-send no está disponible"

# --- VARIABLES GLOBALES ---
QUIET=false
DEBUG=false
VISUAL=false
DEVICE=""
STEP=5

# --- PARSING DE ARGUMENTOS ---
while [[ $# -gt 0 ]]; do
    case $1 in
        --device=*)
            DEVICE="${1#*=}"
            shift
            ;;
        --step=*)
            STEP="${1#*=}"
            shift
            ;;
        --quiet)
            QUIET=true
            shift
            ;;
        --debug)
            DEBUG=true
            shift
            ;;
        --visual)
            VISUAL=true
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
    up)
        control_volume "up" "$DEVICE" "$STEP"
        ;;
    down)
        control_volume "down" "$DEVICE" "$STEP"
        ;;
    set)
        if [[ -z "$2" ]]; then
            die "Debe especificar un valor de volumen (0-100)"
        fi
        control_volume "set" "$DEVICE" "$2"
        ;;
    toggle-mute)
        control_volume "toggle-mute" "$DEVICE"
        ;;
    get)
        local volume=$(get_volume "$DEVICE")
        local muted=$(is_muted "$DEVICE")
        echo "Volumen: $volume%"
        echo "Silenciado: $muted"
        ;;
    device-info)
        show_device_info "$DEVICE"
        ;;
    normalize)
        normalize_volume "$2"
        ;;
    profile)
        manage_volume_profiles "$2" "$3"
        ;;
    *)
        usage
        ;;
esac
