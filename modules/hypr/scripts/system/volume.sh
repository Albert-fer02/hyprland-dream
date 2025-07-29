#!/usr/bin/env bash
# Control de volumen con notificaciones para Hyprland
#
# Dependencias: pamixer, mako (o cualquier servidor de notificaciones)

set -euo pipefail

# --- CONFIGURACIÓN ---
STEP=5 # Porcentaje de cambio de volumen

# --- FUNCIONES ---

die() {
    echo "ERROR: $1" >&2
    exit 1
}

usage() {
    echo "Uso: $0 [up|down|mute|mic_mute]"
    echo "  up:        Sube el volumen del altavoz"
    echo "  down:      Baja el volumen del altavoz"
    echo "  mute:      Silencia el altavoz"
    echo "  mic_mute:  Silencia el micrófono"
    exit 1
}

send_notification() {
    local id="string:x-canonical-private-synchronous:volume"
    local value="int:value:$2"
    local icon="$3"
    notify-send -h "$id" -h "$value" -u low -i "$icon" "$1"
}

get_volume() {
    pamixer --get-volume
}

is_muted() {
    pamixer --get-mute
}

get_mic_volume() {
    pamixer --default-source --get-volume
}

is_mic_muted() {
    pamixer --default-source --get-mute
}

# --- VALIDACIONES ---

command -v pamixer >/dev/null 2>&1 || die "pamixer no está instalado. Por favor, instálalo."
command -v notify-send >/dev/null 2>&1 || die "notify-send no está disponible. Instala un servidor de notificaciones como mako."

# --- LÓGICA PRINCIPAL ---

ACTION=${1:-}

case "$ACTION" in
    up)
        pamixer --unmute
        pamixer -i "$STEP"
        ;;
    down)
        pamixer --unmute
        pamixer -d "$STEP"
        ;;
    mute)
        pamixer -t
        ;;
    mic_mute)
        pamixer --default-source -t
        if is_mic_muted; then
            send_notification "Micrófono silenciado" 0 "microphone-sensitivity-muted-symbolic"
        else
            local vol=$(get_mic_volume)
            send_notification "Micrófono activado" "$vol" "microphone-sensitivity-high-symbolic"
        fi
        exit 0
        ;;
    *)
        usage
        ;;
esac

# Notificación para el volumen del altavoz
VOLUME=$(get_volume)
if is_muted; then
    send_notification "Volumen silenciado" "$VOLUME" "audio-volume-muted-symbolic"
else
    ICON="audio-volume-medium-symbolic"
    if (( VOLUME > 70 )); then
        ICON="audio-volume-high-symbolic"
    elif (( VOLUME < 30 )); then
        ICON="audio-volume-low-symbolic"
    fi
    send_notification "Volumen: ${VOLUME}%" "$VOLUME" "$ICON"
fi
