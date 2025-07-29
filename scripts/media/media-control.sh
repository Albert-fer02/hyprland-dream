#!/usr/bin/env bash
# Control universal de reproducción multimedia con playerctl
# Soporte para Spotify, YouTube Music, VLC, mpv con notificaciones ricas

set -euo pipefail

# --- CONFIGURACIÓN ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CACHE_DIR="$HOME/.cache/hyprland-dream/media"
COVER_CACHE="$CACHE_DIR/covers"
LOG_FILE="$CACHE_DIR/media-control.log"

# Crear directorios necesarios
mkdir -p "$CACHE_DIR" "$COVER_CACHE"

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
  play-pause     Alterna entre reproducir y pausar
  next           Pasa a la siguiente pista
  previous       Vuelve a la pista anterior
  stop           Detiene la reproducción
  volume-up      Sube el volumen 5%
  volume-down    Baja el volumen 5%
  volume-set     Establece volumen específico (0-100)
  info           Muestra información de la pista actual
  list-players   Lista reproductores disponibles
  switch-player  Cambia entre reproductores

Opciones:
  --player=NAME  Especifica reproductor específico
  --quiet        Sin notificaciones
  --debug        Modo debug

Ejemplos:
  $0 play-pause
  $0 next --player=spotify
  $0 volume-set 75
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

# Descargar cover del álbum
download_cover() {
    local url="$1"
    local player="$2"
    
    if [[ -z "$url" ]]; then
        return 1
    fi
    
    # Generar nombre único para el archivo
    local filename
    if [[ "$url" == file://* ]]; then
        filename="${url#file://}"
        if [[ -f "$filename" ]]; then
            echo "$filename"
            return 0
        fi
    else
        filename="$COVER_CACHE/$(echo "$url" | md5sum | cut -d' ' -f1).jpg"
        
        # Verificar si ya existe en caché
        if [[ -f "$filename" ]]; then
            echo "$filename"
            return 0
        fi
        
        # Descargar cover
        if wget -q -O "$filename" "$url" 2>/dev/null; then
            echo "$filename"
            return 0
        fi
    fi
    
    return 1
}

# Obtener icono del reproductor
get_player_icon() {
    local player="$1"
    case "$player" in
        spotify) echo "󰓇" ;;
        youtube-music) echo "󰗃" ;;
        vlc) echo "󰕼" ;;
        mpv) echo "󰐊" ;;
        firefox) echo "󰈹" ;;
        chromium) echo "󰈹" ;;
        *) echo "󰐊" ;;
    esac
}

# Enviar notificación rica
send_rich_notification() {
    local title="$1"
    local message="$2"
    local icon="$3"
    local image="$4"
    local player="$5"
    local action="$6"
    
    # Configurar notificación con progreso si está disponible
    local notification_id="media-control-$(date +%s)"
    local progress=""
    
    if [[ "$action" == "volume" ]]; then
        progress="--hint=int:value:$message"
    fi
    
    # Enviar notificación con imagen si está disponible
    if [[ -n "$image" && -f "$image" ]]; then
        notify-send \
            -h "string:x-canonical-private-synchronous:$notification_id" \
            -h "string:desktop-entry:media-control" \
            -u low \
            -i "$image" \
            $progress \
            "$title" \
            "$message"
    else
        notify-send \
            -h "string:x-canonical-private-synchronous:$notification_id" \
            -h "string:desktop-entry:media-control" \
            -u low \
            -i "$icon" \
            $progress \
            "$title" \
            "$message"
    fi
    
    log "Notificación enviada: $title - $message"
}

# Obtener metadatos completos
get_metadata() {
    local player="$1"
    local metadata=()
    
    # Obtener metadatos básicos
    local title=$(playerctl -p "$player" metadata title 2>/dev/null || echo "Desconocido")
    local artist=$(playerctl -p "$player" metadata artist 2>/dev/null || echo "Desconocido")
    local album=$(playerctl -p "$player" metadata album 2>/dev/null || echo "")
    local art_url=$(playerctl -p "$player" metadata mpris:artUrl 2>/dev/null || echo "")
    
    # Obtener duración y posición si está disponible
    local duration=$(playerctl -p "$player" metadata mpris:length 2>/dev/null || echo "0")
    local position=$(playerctl -p "$player" position 2>/dev/null || echo "0")
    
    # Convertir microsegundos a segundos
    duration=$((duration / 1000000))
    position=$(printf "%.0f" "$position")
    
    # Calcular progreso
    local progress=0
    if [[ $duration -gt 0 ]]; then
        progress=$((position * 100 / duration))
    fi
    
    # Formatear tiempo
    local pos_min=$((position / 60))
    local pos_sec=$((position % 60))
    local dur_min=$((duration / 60))
    local dur_sec=$((duration % 60))
    
    local time_str=""
    if [[ $duration -gt 0 ]]; then
        time_str=" ($pos_min:$pos_sec / $dur_min:$dur_sec)"
    fi
    
    metadata=("$title" "$artist" "$album" "$art_url" "$progress" "$time_str")
    echo "${metadata[@]}"
}

# Control de volumen
control_volume() {
    local action="$1"
    local player="$2"
    local value="${3:-5}"
    
    case "$action" in
        up)
            pamixer -i "$value"
            ;;
        down)
            pamixer -d "$value"
            ;;
        set)
            pamixer --set-volume "$value"
            ;;
        toggle-mute)
            pamixer -t
            ;;
    esac
    
    local volume=$(pamixer --get-volume)
    local muted=$(pamixer --get-mute)
    
    local icon="audio-volume-medium-symbolic"
    if [[ "$muted" == "true" ]]; then
        icon="audio-volume-muted-symbolic"
    elif (( volume > 70 )); then
        icon="audio-volume-high-symbolic"
    elif (( volume < 30 )); then
        icon="audio-volume-low-symbolic"
    fi
    
    if [[ "$QUIET" != "true" ]]; then
        local message="Volumen: ${volume}%"
        if [[ "$muted" == "true" ]]; then
            message="Silenciado"
        fi
        send_rich_notification "Control de Volumen" "$message" "$icon" "" "$player" "volume"
    fi
}

# Control de reproducción
control_playback() {
    local action="$1"
    local player="$2"
    
    # Ejecutar comando
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
    
    # Obtener estado actual
    local status=$(playerctl -p "$player" status 2>/dev/null || echo "Stopped")
    
    if [[ "$status" != "Stopped" && "$QUIET" != "true" ]]; then
        # Obtener metadatos
        local metadata
        read -ra metadata <<< "$(get_metadata "$player")"
        local title="${metadata[0]}"
        local artist="${metadata[1]}"
        local album="${metadata[2]}"
        local art_url="${metadata[3]}"
        local progress="${metadata[4]}"
        local time_str="${metadata[5]}"
        
        # Descargar cover
        local cover_path=""
        if [[ -n "$art_url" ]]; then
            cover_path=$(download_cover "$art_url" "$player")
        fi
        
        # Determinar icono y mensaje
        local player_icon=$(get_player_icon "$player")
        local icon="media-playback-start-symbolic"
        local message="$artist$time_str"
        
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
        es
        
        send_rich_notification "$title" "$message" "$icon" "$cover_path" "$player" "playback"
    elif [[ "$status" == "Stopped" && "$QUIET" != "true" ]]; then
        send_rich_notification "Reproducción detenida" "" "media-playback-stop-symbolic" "" "$player" "playback"
    fi
}

# Listar reproductores
list_players() {
    echo "Reproductores disponibles:"
    playerctl -l 2>/dev/null | while read -r player; do
        local status=$(playerctl -p "$player" status 2>/dev/null || echo "Stopped")
        local icon=$(get_player_icon "$player")
        echo "  $icon $player ($status)"
    done
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
            local icon=$(get_player_icon "$player")
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

# --- VALIDACIONES ---

command -v playerctl >/dev/null 2>&1 || die "playerctl no está instalado"
command -v pamixer >/dev/null 2>&1 || die "pamixer no está instalado"
command -v notify-send >/dev/null 2>&1 || die "notify-send no está disponible"

# --- VARIABLES GLOBALES ---
QUIET=false
DEBUG=false
PLAYER=""

# --- PARSING DE ARGUMENTOS ---
while [[ $# -gt 0 ]]; do
    case $1 in
        --player=*)
            PLAYER="${1#*=}"
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

ACTION="${1:-}"
if [[ -z "$ACTION" ]]; then
    usage
fi

# --- LÓGICA PRINCIPAL ---

if [[ "$DEBUG" == "true" ]]; then
    log "Comando ejecutado: $0 $*"
fi

case "$ACTION" in
    play-pause|next|previous|stop)
        if [[ -z "$PLAYER" ]]; then
            PLAYER=$(get_active_player)
        fi
        control_playback "$ACTION" "$PLAYER"
        ;;
    volume-up|volume-down)
        if [[ -z "$PLAYER" ]]; then
            PLAYER=$(get_active_player)
        fi
        local direction="${ACTION#volume-}"
        control_volume "$direction" "$PLAYER"
        ;;
    volume-set)
        if [[ -z "$2" ]]; then
            die "Debe especificar un valor de volumen (0-100)"
        fi
        if [[ -z "$PLAYER" ]]; then
            PLAYER=$(get_active_player)
        fi
        control_volume "set" "$PLAYER" "$2"
        ;;
    info)
        if [[ -z "$PLAYER" ]]; then
            PLAYER=$(get_active_player)
        fi
        local metadata
        read -ra metadata <<< "$(get_metadata "$PLAYER")"
        echo "Título: ${metadata[0]}"
        echo "Artista: ${metadata[1]}"
        echo "Álbum: ${metadata[2]}"
        echo "Progreso: ${metadata[4]}%${metadata[5]}"
        ;;
    list-players)
        list_players
        ;;
    switch-player)
        PLAYER=$(switch_player)
        if [[ -n "$PLAYER" ]]; then
            echo "Reproductor seleccionado: $PLAYER"
        fi
        ;;
    *)
        usage
        ;;
esac
