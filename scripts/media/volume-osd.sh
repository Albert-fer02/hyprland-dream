#!/usr/bin/env bash
# Indicador visual de volumen (OSD) para Hyprland

# Dependencias: pamixer, mako (o cualquier servidor de notificaciones)

set -euo pipefail

# --- FUNCIONES ---

die() {
    echo "ERROR: $1" >&2
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

# --- VALIDACIONES ---

command -v pamixer >/dev/null 2>&1 || die "pamixer no está instalado. Por favor, instálalo."
command -v notify-send >/dev/null 2>&1 || die "notify-send no está disponible. Instala un servidor de notificaciones como mako."

# --- LÓGICA PRINCIPAL ---

VOLUME=$(get_volume)
if is_muted; then
    send_notification "Volumen silenciado" "0" "audio-volume-muted-symbolic"
else
    ICON="audio-volume-medium-symbolic"
    if (( VOLUME > 70 )); then
        ICON="audio-volume-high-symbolic"
    elif (( VOLUME < 30 )); then
        ICON="audio-volume-low-symbolic"
    fi
    send_notification "Volumen: ${VOLUME}%" "$VOLUME" "$ICON"
fi
