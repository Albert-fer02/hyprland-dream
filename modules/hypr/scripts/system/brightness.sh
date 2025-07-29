#!/usr/bin/env bash
# Control de brillo con notificaciones para Hyprland
#
# Dependencias: brightnessctl, mako (o cualquier servidor de notificaciones)

set -euo pipefail

# --- CONFIGURACIÓN ---
STEP=5 # Porcentaje de cambio de brillo

# --- FUNCIONES ---

# Muestra un mensaje de error y sale
die() {
    echo "ERROR: $1" >&2
    exit 1
}

# Muestra la ayuda
usage() {
    echo "Uso: $0 [up|down|get]"
    echo "  up:    Sube el brillo"
    echo "  down:  Baja el brillo"
    echo "  get:   Obtiene el brillo actual (en %)"
    exit 1
}

# Envía una notificación
# $1: Icono
# $2: Título
# $3: Barra de progreso (valor)
send_notification() {
    local icon="$1"
    local title="$2"
    local value="$3"
    notify-send -h "string:x-canonical-private-synchronous:brightness" -h "int:value:$value" -u low -i "$icon" "$title"
}

# --- VALIDACIONES ---

# Verifica que brightnessctl esté instalado
command -v brightnessctl >/dev/null 2>&1 || die "brightnessctl no está instalado. Por favor, instálalo."
# Verifica que notify-send esté disponible
command -v notify-send >/dev/null 2>&1 || die "notify-send no está disponible. Instala un servidor de notificaciones como mako."

# --- LÓGICA PRINCIPAL ---

ACTION=${1:-}

case "$ACTION" in
    up)
        brightnessctl set "${STEP}%+"
        ;;
    down)
        brightnessctl set "${STEP}%-"
        ;;
    get)
        brightnessctl -m | cut -d, -f4
        exit 0
        ;;
    *)
        usage
        ;;
esac

# Obtiene el brillo actual y máximo para todos los dispositivos
# y calcula el promedio para la notificación.
# Esto es un enfoque simple para múltiples monitores.
# Una solución más avanzada podría controlarlos individualmente.
CURRENT_BRIGHTNESS=$(brightnessctl -m | awk -F, '{sum+=$4} END {print sum/NR}')
CURRENT_BRIGHTNESS=${CURRENT_BRIGHTNESS%.*} # Convierte a entero

# Determina el icono a usar
ICON="display-brightness-medium-symbolic"
if (( CURRENT_BRIGHTNESS > 70 )); then
    ICON="display-brightness-high-symbolic"
elif (( CURRENT_BRIGHTNESS < 30 )); then
    ICON="display-brightness-low-symbolic"
fi

# Envía la notificación
send_notification "$ICON" "Brillo: ${CURRENT_BRIGHTNESS}%" "$CURRENT_BRIGHTNESS"
