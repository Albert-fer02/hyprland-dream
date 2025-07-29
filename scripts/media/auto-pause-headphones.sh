#!/usr/bin/env bash
# Sistema avanzado de detección y auto-pausa de auriculares
# Soporte para múltiples tipos de dispositivos y configuraciones

set -euo pipefail

# --- CONFIGURACIÓN ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CACHE_DIR="$HOME/.cache/hyprland-dream/headphones"
CONFIG_DIR="$HOME/.config/hyprland-dream/headphones"
LOG_FILE="$CACHE_DIR/auto-pause.log"
STATE_FILE="$CACHE_DIR/headphones-state"

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
  monitor        Monitorea cambios de dispositivos (modo daemon)
  check          Verifica estado actual de auriculares
  pause          Pausa reproducción manualmente
  resume         Reanuda reproducción manualmente
  test           Prueba detección de dispositivos
  config         Gestiona configuración

Opciones:
  --quiet        Sin notificaciones
  --debug        Modo debug
  --config=FILE  Archivo de configuración personalizado

Ejemplos:
  $0 monitor
  $0 check
  $0 test
  $0 config --list-devices
EOF
    exit 1
}

# Detectar dispositivos de auriculares
detect_headphone_devices() {
    local devices=()
    
    # Detectar dispositivos Bluetooth
    while read -r device; do
        if [[ "$device" == *"headphones"* ]] || [[ "$device" == *"headset"* ]] || [[ "$device" == *"earbuds"* ]]; then
            devices+=("bluetooth:$device")
        fi
    done < <(pactl list sinks | awk '
        $1 == "Description:" && ($0 ~ /headphone/ || $0 ~ /headset/ || $0 ~ /earbuds/) {
            print substr($0, index($0, $2))
        }
    ')
    
    # Detectar dispositivos USB
    while read -r device; do
        if [[ "$device" == *"USB"* ]] && ([[ "$device" == *"headphone"* ]] || [[ "$device" == *"headset"* ]]); then
            devices+=("usb:$device")
        fi
    done < <(pactl list sinks | awk '
        $1 == "Description:" && $0 ~ /USB/ && ($0 ~ /headphone/ || $0 ~ /headset/) {
            print substr($0, index($0, $2))
        }
    ')
    
    # Detectar jack de auriculares (3.5mm)
    if [[ -f "/proc/asound/card*/pcm*/sub*/status" ]]; then
        if grep -q "RUNNING" /proc/asound/card*/pcm*/sub*/status 2>/dev/null; then
            devices+=("jack:3.5mm Headphone Jack")
        fi
    fi
    
    echo "${devices[@]}"
}

# Verificar si hay auriculares conectados
is_headphones_connected() {
    local devices=($(detect_headphone_devices))
    [[ ${#devices[@]} -gt 0 ]]
}

# Obtener estado guardado
get_saved_state() {
    if [[ -f "$STATE_FILE" ]]; then
        cat "$STATE_FILE"
    else
        echo "unknown"
    fi
}

# Guardar estado
save_state() {
    local state="$1"
    echo "$state" > "$STATE_FILE"
    log "Estado guardado: $state"
}

# Verificar si hay reproducción activa
is_media_playing() {
    local players=($(playerctl -l 2>/dev/null))
    for player in "${players[@]}"; do
        local status=$(playerctl -p "$player" status 2>/dev/null || echo "Stopped")
        if [[ "$status" == "Playing" ]]; then
            return 0
        fi
    done
    return 1
}

# Pausar reproducción
pause_media() {
    local paused_players=()
    
    local players=($(playerctl -l 2>/dev/null))
    for player in "${players[@]}"; do
        local status=$(playerctl -p "$player" status 2>/dev/null || echo "Stopped")
        if [[ "$status" == "Playing" ]]; then
            if playerctl -p "$player" pause 2>/dev/null; then
                paused_players+=("$player")
                log "Reproducción pausada en $player"
            fi
        fi
    done
    
    if [[ ${#paused_players[@]} -gt 0 ]]; then
        local player_list=$(IFS=", "; echo "${paused_players[*]}")
        if [[ "$QUIET" != "true" ]]; then
            notify-send "Reproducción pausada" "Auriculares desconectados\nReproductores: $player_list" -u low -i "audio-headphones-symbolic"
        fi
        echo "Reproducción pausada en: $player_list"
    fi
}

# Reanudar reproducción
resume_media() {
    local resumed_players=()
    
    local players=($(playerctl -l 2>/dev/null))
    for player in "${players[@]}"; do
        local status=$(playerctl -p "$player" status 2>/dev/null || echo "Stopped")
        if [[ "$status" == "Paused" ]]; then
            if playerctl -p "$player" play 2>/dev/null; then
                resumed_players+=("$player")
                log "Reproducción reanudada en $player"
            fi
        fi
    done
    
    if [[ ${#resumed_players[@]} -gt 0 ]]; then
        local player_list=$(IFS=", "; echo "${resumed_players[*]}")
        if [[ "$QUIET" != "true" ]]; then
            notify-send "Reproducción reanudada" "Auriculares conectados\nReproductores: $player_list" -u low -i "audio-headphones-symbolic"
        fi
        echo "Reproducción reanudada en: $player_list"
    fi
}

# Verificar estado actual
check_headphones_state() {
    local current_state="disconnected"
    local devices=($(detect_headphone_devices))
    
    if [[ ${#devices[@]} -gt 0 ]]; then
        current_state="connected"
        echo "Auriculares conectados:"
        for device in "${devices[@]}"; do
            echo "  - $device"
        done
    else
        echo "Auriculares desconectados"
    fi
    
    local saved_state=$(get_saved_state)
    echo "Estado anterior: $saved_state"
    
    if [[ "$current_state" != "$saved_state" ]]; then
        echo "Cambio de estado detectado: $saved_state -> $current_state"
        return 0
    else
        echo "Sin cambios de estado"
        return 1
    fi
}

# Monitorear cambios de dispositivos
monitor_devices() {
    echo "Iniciando monitoreo de auriculares..."
    echo "Presiona Ctrl+C para detener"
    
    local last_state=$(get_saved_state)
    
    # Monitorear eventos de PulseAudio
    pactl subscribe | while read -r event; do
        if echo "$event" | grep -q "sink"; then
            local current_state="disconnected"
            
            if is_headphones_connected; then
                current_state="connected"
            fi
            
            if [[ "$current_state" != "$last_state" ]]; then
                log "Cambio de estado: $last_state -> $current_state"
                
                case "$current_state" in
                    "connected")
                        if [[ "$last_state" == "disconnected" ]]; then
                            log "Auriculares conectados"
                            if [[ "$QUIET" != "true" ]]; then
                                notify-send "Auriculares conectados" "Reproducción disponible" -u low -i "audio-headphones-symbolic"
                            fi
                        fi
                        ;;
                    "disconnected")
                        if [[ "$last_state" == "connected" ]]; then
                            log "Auriculares desconectados"
                            if is_media_playing; then
                                pause_media
                            fi
                        fi
                        ;;
                esac
                
                save_state "$current_state"
                last_state="$current_state"
            fi
        fi
    done
}

# Probar detección de dispositivos
test_detection() {
    echo "Probando detección de auriculares..."
    echo "===================================="
    
    echo "1. Dispositivos detectados:"
    local devices=($(detect_headphone_devices))
    if [[ ${#devices[@]} -gt 0 ]]; then
        for device in "${devices[@]}"; do
            echo "   ✓ $device"
        done
    else
        echo "   ✗ No se detectaron auriculares"
    fi
    
    echo ""
    echo "2. Estado de conexión:"
    if is_headphones_connected; then
        echo "   ✓ Auriculares conectados"
    else
        echo "   ✗ Auriculares desconectados"
    fi
    
    echo ""
    echo "3. Reproducción activa:"
    if is_media_playing; then
        echo "   ✓ Hay reproducción activa"
        echo "   Reproductores:"
        local players=($(playerctl -l 2>/dev/null))
        for player in "${players[@]}"; do
            local status=$(playerctl -p "$player" status 2>/dev/null || echo "Stopped")
            echo "     - $player ($status)"
        done
    else
        echo "   ✗ No hay reproducción activa"
    fi
    
    echo ""
    echo "4. Estado guardado:"
    local saved_state=$(get_saved_state)
    echo "   Estado actual: $saved_state"
}

# Gestionar configuración
manage_config() {
    local action="${1:-}"
    
    case "$action" in
        list-devices)
            echo "Dispositivos de audio disponibles:"
            pactl list sinks | awk '
                $1 == "Description:" { print "  " substr($0, index($0, $2)) }
            '
            ;;
        save-config)
            local config_file="$CONFIG_DIR/auto-pause.conf"
            cat > "$config_file" << EOF
# Configuración de auto-pausa de auriculares
# Generado automáticamente el $(date)

# Dispositivos de auriculares detectados
HEADPHONE_DEVICES=($(detect_headphone_devices))

# Configuración de notificaciones
ENABLE_NOTIFICATIONS=true

# Configuración de logging
ENABLE_LOGGING=true
LOG_FILE="$LOG_FILE"

# Configuración de reproductores
AUTO_PAUSE_PLAYERS=("spotify" "vlc" "mpv" "firefox" "chromium")
EOF
            echo "Configuración guardada en: $config_file"
            ;;
        load-config)
            local config_file="$CONFIG_DIR/auto-pause.conf"
            if [[ -f "$config_file" ]]; then
                source "$config_file"
                echo "Configuración cargada desde: $config_file"
            else
                echo "Archivo de configuración no encontrado"
            fi
            ;;
        *)
            echo "Acciones de configuración disponibles:"
            echo "  list-devices  - Lista dispositivos disponibles"
            echo "  save-config   - Guarda configuración actual"
            echo "  load-config   - Carga configuración guardada"
            ;;
    esac
}

# --- VALIDACIONES ---

command -v pactl >/dev/null 2>&1 || die "pactl no está instalado"
command -v playerctl >/dev/null 2>&1 || die "playerctl no está instalado"
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
        --config=*)
            CONFIG_FILE="${1#*=}"
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
    monitor)
        monitor_devices
        ;;
    check)
        check_headphones_state
        ;;
    pause)
        pause_media
        ;;
    resume)
        resume_media
        ;;
    test)
        test_detection
        ;;
    config)
        manage_config "$2"
        ;;
    *)
        usage
        ;;
esac
