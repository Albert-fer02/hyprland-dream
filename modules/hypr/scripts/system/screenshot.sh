#!/usr/bin/env bash
# Script de capturas de pantalla para Hyprland
#
# Dependencias: grim, slurp, wl-copy, mako

set -euo pipefail

# --- CONFIGURACIÓN ---
SCREENSHOT_DIR=~/Imágenes/Capturas

# --- FUNCIONES ---

die() {
    echo "ERROR: $1" >&2
    exit 1
}

usage() {
    echo "Uso: $0 [full|area|window]"
    echo "  full:    Captura la pantalla completa"
    echo "  area:    Selecciona un área para capturar"
    echo "  window:  Selecciona una ventana para capturar"
    exit 1
}

send_notification() {
    notify-send -u low -i "$1" "$2" "$3"
}

# --- VALIDACIONES ---

for cmd in grim slurp wl-copy notify-send; do
    command -v "$cmd" >/dev/null 2>&1 || die "$cmd no está instalado. Por favor, instálalo."
done

# Crea el directorio de capturas si no existe
mkdir -p "$SCREENSHOT_DIR"

# --- LÓGICA PRINCIPAL ---

MODE=${1:-area}
TIMESTAMP=$(date +%Y-%m-%d_%H-%M-%S)
FILE_PATH="$SCREENSHOT_DIR/screenshot_$TIMESTAMP.png"

case "$MODE" in
    full)
        grim "$FILE_PATH"
        ;;
    area)
        # slurp devuelve las coordenadas de la selección
        GEOMETRY=$(slurp)
        [ -z "$GEOMETRY" ] && exit 1 # Salir si no se selecciona nada
        grim -g "$GEOMETRY" "$FILE_PATH"
        ;;
    window)
        # hyprctl clients -j nos da info de las ventanas en JSON
        # jq procesa el JSON para que slurp lo entienda
        FOCUSED_WINDOW=$(hyprctl activewindow -j)
        GEOMETRY=$(hyprctl clients -j | jq -r '.[] | select(.address == "'$(echo "$FOCUSED_WINDOW" | jq -r .address)'") | "\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"')
        [ -z "$GEOMETRY" ] && die "No se pudo obtener la geometría de la ventana activa."
        grim -g "$GEOMETRY" "$FILE_PATH"
        ;;
    *)
        usage
        ;;
esac

# Copia al portapapeles y envía notificación
wl-copy < "$FILE_PATH"
send_notification "$FILE_PATH" "Captura de pantalla creada" "Copiada al portapapeles."
