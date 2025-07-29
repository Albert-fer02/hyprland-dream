#!/usr/bin/env bash
# Script para cambiar entre dispositivos de audio (sinks) con Rofi

# Dependencias: pactl, rofi

set -euo pipefail

# --- FUNCIONES ---

die() {
    echo "ERROR: $1" >&2
    exit 1
}

# --- VALIDACIONES ---

command -v pactl >/dev/null 2>&1 || die "pactl no está instalado. Por favor, instálalo."
command -v rofi >/dev/null 2>&1 || die "rofi no está instalado. Por favor, instálalo."

# --- LÓGICA PRINCIPAL ---

# Obtener la lista de sinks (dispositivos de salida de audio)
# Formato: <index>: <nombre_del_sink> (<descripción>)
SINKS=$(pactl list sinks short | awk '{print $1 ": " $2 " (" $3 ")"}')

# Obtener el sink por defecto
DEFAULT_SINK_NAME=$(pactl info | grep "Default Sink:" | awk '{print $3}')

# Preparar las opciones para Rofi
ROFI_OPTIONS=""
while IFS= read -r line; do
    SINK_INDEX=$(echo "$line" | awk -F':' '{print $1}')
    SINK_NAME=$(echo "$line" | awk -F':' '{print $2}' | awk '{print $1}')
    SINK_DESC=$(echo "$line" | sed -E 's/^[0-9]+: [^ ]+ \((.*)\)/\1/')

    DISPLAY_NAME="$SINK_DESC"
    if [ "$SINK_NAME" == "$DEFAULT_SINK_NAME" ]; then
        DISPLAY_NAME="* $DISPLAY_NAME"
    fi
    ROFI_OPTIONS+="$DISPLAY_NAME\n"

    # Guardar el mapeo de nombre de visualización a nombre de sink real
    declare "sink_map[$(echo "$DISPLAY_NAME" | sed 's/\* //')]=$SINK_NAME"

done <<< "$SINKS"

# Mostrar Rofi y obtener la selección del usuario
SELECTED_DISPLAY_NAME=$(echo -e "$ROFI_OPTIONS" | rofi -dmenu -p "Dispositivo de Audio" -theme ~/.config/rofi/wifi-menu.rasi)

if [ -z "$SELECTED_DISPLAY_NAME" ]; then
    exit 0 # El usuario canceló
fi

# Eliminar el asterisco si estaba presente
CLEAN_SELECTED_DISPLAY_NAME=$(echo "$SELECTED_DISPLAY_NAME" | sed 's/\* //')

# Obtener el nombre del sink real a partir del mapeo
SELECTED_SINK_NAME="${sink_map[$CLEAN_SELECTED_DISPLAY_NAME]}"

if [ -z "$SELECTED_SINK_NAME" ]; then
    die "No se pudo encontrar el sink seleccionado."
}

# Cambiar el sink por defecto
pactl set-default-sink "$SELECTED_SINK_NAME"

# Mover todas las aplicaciones de audio al nuevo sink
for app in $(pactl list sink-inputs short | awk '{print $1}'); do
    pactl move-sink-input "$app" "$SELECTED_SINK_NAME"
done

notify-send "Dispositivo de audio cambiado a" "$CLEAN_SELECTED_DISPLAY_NAME" -u low -i "audio-card-symbolic"
