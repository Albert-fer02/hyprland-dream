#!/usr/bin/env bash
# Script para el módulo de control multimedia de Waybar
# Proporciona estado dinámico y control de reproductores

set -euo pipefail

# --- CONFIGURACIÓN ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CACHE_DIR="$HOME/.cache/hyprland-dream/waybar-multimedia"

# Crear directorio de caché
mkdir -p "$CACHE_DIR"

# --- FUNCIONES ---

# Obtener estado del reproductor activo
get_player_status() {
    local player=$(playerctl -l 2>/dev/null | head -1)
    if [[ -z "$player" ]]; then
        echo '{"text": "󰐊", "tooltip": "No hay reproductores activos", "class": "inactive"}'
        return 0
    fi
    
    local status=$(playerctl -p "$player" status 2>/dev/null || echo "Stopped")
    local title=$(playerctl -p "$player" metadata title 2>/dev/null || echo "Desconocido")
    local artist=$(playerctl -p "$player" metadata artist 2>/dev/null || echo "Desconocido")
    
    local icon="󰐊"
    local class="paused"
    
    case "$status" in
        "Playing")
            icon="󰏤"
            class="playing"
            ;;
        "Paused")
            icon="󰐊"
            class="paused"
            ;;
        "Stopped")
            icon="󰐊"
            class="stopped"
            ;;
    esac
    
    local tooltip="Control Multimedia\n\nReproductor: $player\nEstado: $status\nTítulo: $title\nArtista: $artist\n\nClic: Play/Pause\nClic derecho: Siguiente\nClic medio: Anterior"
    
    echo "{\"text\": \"$icon\", \"tooltip\": \"$tooltip\", \"class\": \"$class\"}"
}

# --- LÓGICA PRINCIPAL ---

case "${1:-}" in
    "status")
        get_player_status
        ;;
    "play-pause")
        playerctl play-pause
        ;;
    "next")
        playerctl next
        ;;
    "previous")
        playerctl previous
        ;;
    "stop")
        playerctl stop
        ;;
    *)
        get_player_status
        ;;
esac 