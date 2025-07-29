#!/usr/bin/env bash
# Pausa la reproducción multimedia al desconectar auriculares

# Dependencias: pactl, playerctl

set -euo pipefail

# --- FUNCIONES ---

die() {
    echo "ERROR: $1" >&2
    exit 1
}

# --- VALIDACIONES ---

command -v pactl >/dev/null 2>&1 || die "pactl no está instalado. Por favor, instálalo."
command -v playerctl >/dev/null 2>&1 || die "playerctl no está instalado. Por favor, instálalo."

# --- LÓGICA PRINCIPAL ---

# Escucha eventos de PulseAudio/PipeWire
pactl subscribe | while read -r event; do
    if echo "$event" | grep -q "sink #.* removed"; then
        # Un sink ha sido removido (posiblemente auriculares desconectados)
        # Verificar si el sink removido era el predeterminado o un auricular
        # Esto es una heurística, puede que necesite ajustes para casos específicos
        if playerctl status &>/dev/null; then
            playerctl pause
            notify-send "Reproducción pausada" "Auriculares desconectados" -u low -i "audio-headphones-symbolic"
        fi
    fi
done
