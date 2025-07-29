#!/usr/bin/env bash
# Control universal de reproducción multimedia con playerctl

# Dependencias: playerctl, mako (o cualquier servidor de notificaciones)

set -euo pipefail

# --- FUNCIONES ---

die() {
    echo "ERROR: $1" >&2
    exit 1
}

usage() {
    echo "Uso: $0 [play-pause|next|previous|stop]"
    echo "  play-pause: Alterna entre reproducir y pausar"
    echo "  next:       Pasa a la siguiente pista"
    echo "  previous:   Vuelve a la pista anterior"
    echo "  stop:       Detiene la reproducción"
    exit 1
}

send_notification() {
    local title="$1"
    local message="$2"
    local icon="$3"
    local image="$4"

    if [ -n "$image" ] && [ -f "$image" ]; then
        notify-send -h "string:x-canonical-private-synchronous:media-control" -u low -i "$image" "$title" "$message"
    else
        notify-send -h "string:x-canonical-private-synchronous:media-control" -u low -i "$icon" "$title" "$message"
    fi
}

# --- VALIDACIONES ---

command -v playerctl >/dev/null 2>&1 || die "playerctl no está instalado. Por favor, instálalo."
command -v notify-send >/dev/null 2>&1 || die "notify-send no está disponible. Instala un servidor de notificaciones como mako."

# --- LÓGICA PRINCIPAL ---

ACTION=${1:-}

case "$ACTION" in
    play-pause)
        playerctl play-pause
        ;;
    next)
        playerctl next
        ;;
    previous)
        playerctl previous
        ;;
    stop)
        playerctl stop
        ;;
    *)
        usage
        ;;
esac

# Obtener metadatos para la notificación
PLAYER_STATUS=$(playerctl status 2>/dev/null || echo "Stopped")

if [ "$PLAYER_STATUS" != "Stopped" ]; then
    ARTIST=$(playerctl metadata artist 2>/dev/null || echo "Desconocido")
    TITLE=$(playerctl metadata title 2>/dev/null || echo "Desconocido")
    ALBUM_ART_URL=$(playerctl metadata mpris:artUrl 2>/dev/null || echo "")

    ICON="media-playback-start-symbolic"
    if [ "$PLAYER_STATUS" == "Paused" ]; then
        ICON="media-playback-pause-symbolic"
    fi

    # Descargar la carátula del álbum si está disponible
    ALBUM_ART_PATH=""
    if [[ "$ALBUM_ART_URL" == file://* ]]; then
        ALBUM_ART_PATH="${ALBUM_ART_URL#file://}"
    elif [ -n "$ALBUM_ART_URL" ]; then
        # Descargar a un directorio temporal
        TEMP_DIR="/tmp/media_covers"
        mkdir -p "$TEMP_DIR"
        ALBUM_ART_PATH="$TEMP_DIR/$(basename "$ALBUM_ART_URL")"
        wget -q -O "$ALBUM_ART_PATH" "$ALBUM_ART_URL" || ALBUM_ART_PATH=""
    fi

    send_notification "$TITLE" "$ARTIST" "$ICON" "$ALBUM_ART_PATH"
else
    send_notification "Reproducción detenida" "" "media-playback-stop-symbolic" ""
fi
