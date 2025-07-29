#!/usr/bin/env bash
# Script para cambiar el tema de Waybar dinámicamente

set -euo pipefail

WAYBAR_CONFIG_DIR=~/.config/waybar
STYLE_FILE="$WAYBAR_CONFIG_DIR/style.css"
THEMES_DIR="$WAYBAR_CONFIG_DIR/themes"

usage() {
    echo "Uso: $0 <nombre_del_tema>"
    echo "Temas disponibles:"
    for theme in "$THEMES_DIR"/*.css; do
        echo "  - $(basename "$theme" .css)"
    done
    exit 1
}

# Verifica que se haya pasado un argumento
if [ -z "${1:-}" ]; then
    usage
fi

THEME_NAME="$1"
THEME_FILE="$THEMES_DIR/$THEME_NAME.css"

# Verifica que el archivo del tema exista
if [ ! -f "$THEME_FILE" ]; then
    echo "Error: El tema '$THEME_NAME' no existe." >&2
    usage
fi

# Actualiza la línea @import en el style.css principal
# sed -i es para edición in-place
sed -i "s|@import .*;|@import \"themes/$THEME_NAME.css\";|" "$STYLE_FILE"

# Recarga Waybar para aplicar los cambios
# pkill -SIGUSR2 waybar envía una señal para que se recargue
# sin matar el proceso por completo.
pkill -SIGUSR2 waybar

echo "Tema de Waybar cambiado a '$THEME_NAME' con éxito."

