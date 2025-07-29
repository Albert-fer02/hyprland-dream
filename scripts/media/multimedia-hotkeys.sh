#!/usr/bin/env bash
# Sistema de hotkeys multimedia para Hyprland Dream
# Integración con playerctl, pamixer y dispositivos de audio

set -euo pipefail

# --- CONFIGURACIÓN ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CACHE_DIR="$HOME/.cache/hyprland-dream/hotkeys"
CONFIG_DIR="$HOME/.config/hyprland-dream/hotkeys"
LOG_FILE="$CACHE_DIR/multimedia-hotkeys.log"

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
  play-pause      Alterna reproducción/pausa
  next            Siguiente pista
  previous        Pista anterior
  stop            Detener reproducción
  volume-up       Subir volumen
  volume-down     Bajar volumen
  volume-mute     Silenciar/activar volumen
  device-switch   Cambiar dispositivo de audio
  player-switch   Cambiar reproductor
  info            Mostrar información actual
  help            Mostrar esta ayuda

Opciones:
  --player=NAME   Especifica reproductor específico
  --device=NAME   Especifica dispositivo específico
  --step=N        Establece paso de volumen (default: 5)
  --quiet         Sin notificaciones
  --debug         Modo debug

Ejemplos:
  $0 play-pause
  $0 volume-up --step=10
  $0 device-switch
  $0 player-switch
EOF
    exit 1
}

# Obtener reproductor activo
get_active_player() {
    local player="${1:-}"
    
    if [[ -n "$player" ]]; then
        if playerctl -l | grep -q "^$player$"; then
            echo "$player"
        else
            die "Reproductor '$player' no encontrado"
        fi
    else
        # Obtener el primer reproductor activo
        local active_player
        active_player=$(playerctl -l 2>/dev/null | head -1)
        if [[ -z "$active_player" ]]; then
            die "No hay reproductores multimedia activos"
        fi
        echo "$active_player"
    fi
}

# Control de reproducción
control_playback() {
    local action="$1"
    local player="$2"
    
    case "$action" in
        play-pause)
            playerctl -p "$player" play-pause
            ;;
        next)
            playerctl -p "$player" next
            ;;
        previous)
            playerctl -p "$player" previous
            ;;
        stop)
            playerctl -p "$player" stop
            ;;
    esac
    
    # Obtener información para notificación
    local status=$(playerctl -p "$player" status 2>/dev/null || echo "Stopped")
    if [[ "$status" != "Stopped" ]]; then
        local title=$(playerctl -p "$player" metadata title 2>/dev/null || echo "Desconocido")
        local artist=$(playerctl -p "$player" metadata artist 2>/dev/null || echo "Desconocido")
        
        local icon="media-playback-start-symbolic"
        local message="$artist"
        
        case "$action" in
            play-pause)
                if [[ "$status" == "Paused" ]]; then
                    icon="media-playback-pause-symbolic"
                    message="Pausado - $message"
                else
                    message="Reproduciendo - $message"
                fi
                ;;
            next)
                message="Siguiente - $message"
                ;;
            previous)
                message="Anterior - $message"
                ;;
            stop)
                icon="media-playback-stop-symbolic"
                message="Detenido"
                ;;
        esac
        
        if [[ "$QUIET" != "true" ]]; then
            notify-send "$title" "$message" -u low -i "$icon"
        fi
    fi
}

# Control de volumen
control_volume() {
    local action="$1"
    local step="${2:-5}"
    
    case "$action" in
        up)
            pamixer -i "$step"
            ;;
        down)
            pamixer -d "$step"
            ;;
        mute)
            pamixer -t
            ;;
    esac
    
    # Obtener estado actual
    local volume=$(pamixer --get-volume)
    local muted=$(pamixer --get-mute)
    
    local icon="audio-volume-medium-symbolic"
    if [[ "$muted" == "true" ]]; then
        icon="audio-volume-muted-symbolic"
    elif (( volume > 80 )); then
        icon="audio-volume-high-symbolic"
    elif (( volume < 30 )); then
        icon="audio-volume-low-symbolic"
    fi
    
    if [[ "$QUIET" != "true" ]]; then
        local message="Volumen: ${volume}%"
        if [[ "$muted" == "true" ]]; then
            message="Silenciado"
        fi
        notify-send "Control de Volumen" "$message" -u low -i "$icon"
    fi
}

# Cambiar dispositivo de audio
switch_audio_device() {
    local target_device="${1:-}"
    
    if [[ -z "$target_device" ]]; then
        # Mostrar menú interactivo
        local devices=()
        local current_sink=$(pactl info | grep "Default Sink:" | awk '{print $3}')
        
        while read -r index name description; do
            local display_name="$description"
            if [[ "$name" == "$current_sink" ]]; then
                display_name="* $display_name"
            fi
            devices+=("$display_name" "$name")
        done < <(pactl list sinks short | awk '{print $1, $2, $3}')
        
        if [[ ${#devices[@]} -eq 0 ]]; then
            die "No hay dispositivos de audio disponibles"
        fi
        
        # Usar rofi si está disponible
        if command -v rofi >/dev/null 2>&1; then
            local options=""
            for ((i=0; i<${#devices[@]}; i+=2)); do
                options+="${devices[i]}\n"
            done
            
            local selected=$(echo -e "$options" | rofi -dmenu -p "Dispositivo de Audio" -theme ~/.config/rofi/config.rasi)
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
    
    # Cambiar dispositivo
    pactl set-default-sink "$target_device"
    
    # Mover aplicaciones
    while read -r app_index; do
        if [[ -n "$app_index" ]]; then
            pactl move-sink-input "$app_index" "$target_device" 2>/dev/null
        fi
    done < <(pactl list sink-inputs short | awk '{print $1}')
    
    # Obtener descripción del dispositivo
    local description=$(pactl list sinks | awk -v sink="$target_device" '
        $1 == "Name:" && $2 == sink { in_sink=1; next }
        /^Sink / { in_sink=0 }
        in_sink && $1 == "Description:" { print substr($0, index($0, $2)); exit }
    ')
    
    if [[ "$QUIET" != "true" ]]; then
        notify-send "Dispositivo cambiado" "$description" -u low -i "audio-card-symbolic"
    fi
    
    log "Dispositivo cambiado a: $target_device ($description)"
}

# Cambiar reproductor
switch_player() {
    local players=($(playerctl -l 2>/dev/null))
    if [[ ${#players[@]} -eq 0 ]]; then
        die "No hay reproductores disponibles"
    fi
    
    # Si solo hay uno, usarlo
    if [[ ${#players[@]} -eq 1 ]]; then
        echo "${players[0]}"
        return 0
    fi
    
    # Mostrar menú con rofi si está disponible
    if command -v rofi >/dev/null 2>&1; then
        local options=""
        for player in "${players[@]}"; do
            local status=$(playerctl -p "$player" status 2>/dev/null || echo "Stopped")
            local icon="󰐊"
            case "$player" in
                spotify) icon="󰓇" ;;
                vlc) icon="󰕼" ;;
                mpv) icon="󰐊" ;;
                firefox) icon="󰈹" ;;
                chromium) icon="󰈹" ;;
            esac
            options+="$icon $player ($status)\n"
        done
        
        local selected=$(echo -e "$options" | rofi -dmenu -p "Seleccionar reproductor" -theme ~/.config/rofi/config.rasi | awk '{print $2}')
        if [[ -n "$selected" ]]; then
            echo "$selected"
            return 0
        fi
    else
        # Fallback: usar el primer reproductor
        echo "${players[0]}"
        return 0
    fi
    
    return 1
}

# Mostrar información actual
show_info() {
    echo "Información multimedia actual:"
    echo "=============================="
    
    echo ""
    echo "Reproductores activos:"
    local players=($(playerctl -l 2>/dev/null))
    if [[ ${#players[@]} -gt 0 ]]; then
        for player in "${players[@]}"; do
            local status=$(playerctl -p "$player" status 2>/dev/null || echo "Stopped")
            local title=$(playerctl -p "$player" metadata title 2>/dev/null || echo "Desconocido")
            local artist=$(playerctl -p "$player" metadata artist 2>/dev/null || echo "Desconocido")
            echo "  $player: $status"
            echo "    Título: $title"
            echo "    Artista: $artist"
        done
    else
        echo "  No hay reproductores activos"
    fi
    
    echo ""
    echo "Dispositivo de audio actual:"
    local current_sink=$(pactl info | grep "Default Sink:" | awk '{print $3}')
    local description=$(pactl list sinks | awk -v sink="$current_sink" '
        $1 == "Name:" && $2 == sink { in_sink=1; next }
        /^Sink / { in_sink=0 }
        in_sink && $1 == "Description:" { print substr($0, index($0, $2)); exit }
    ')
    echo "  $description"
    
    echo ""
    echo "Volumen:"
    local volume=$(pamixer --get-volume)
    local muted=$(pamixer --get-mute)
    echo "  Nivel: $volume%"
    echo "  Silenciado: $muted"
}

# --- VALIDACIONES ---

command -v playerctl >/dev/null 2>&1 || die "playerctl no está instalado"
command -v pamixer >/dev/null 2>&1 || die "pamixer no está instalado"
command -v pactl >/dev/null 2>&1 || die "pactl no está instalado"
command -v notify-send >/dev/null 2>&1 || die "notify-send no está disponible"

# --- VARIABLES GLOBALES ---
QUIET=false
DEBUG=false
PLAYER=""
DEVICE=""
STEP=5

# --- PARSING DE ARGUMENTOS ---
while [[ $# -gt 0 ]]; do
    case $1 in
        --player=*)
            PLAYER="${1#*=}"
            shift
            ;;
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
    play-pause|next|previous|stop)
        if [[ -z "$PLAYER" ]]; then
            PLAYER=$(get_active_player)
        fi
        control_playback "$COMMAND" "$PLAYER"
        ;;
    volume-up|volume-down)
        local action="${COMMAND#volume-}"
        control_volume "$action" "$STEP"
        ;;
    volume-mute)
        control_volume "mute"
        ;;
    device-switch)
        switch_audio_device "$DEVICE"
        ;;
    player-switch)
        local selected_player=$(switch_player)
        if [[ -n "$selected_player" ]]; then
            echo "Reproductor seleccionado: $selected_player"
            if [[ "$QUIET" != "true" ]]; then
                notify-send "Reproductor cambiado" "$selected_player" -u low -i "media-playback-start-symbolic"
            fi
        fi
        ;;
    info)
        show_info
        ;;
    help)
        usage
        ;;
    *)
        usage
        ;;
esac 