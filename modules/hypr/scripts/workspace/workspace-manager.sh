#!/usr/bin/env bash
# Gestor de workspaces para Hyprland (versión inicial)
#
# Este script proporciona una base para funcionalidades de gestión de workspaces.
# La auto-organización y restauración de layouts son complejas y pueden
# requerir herramientas más avanzadas o plugins de Hyprland.

set -euo pipefail

# --- FUNCIONES ---

die() {
    echo "ERROR: $1" >&2
    exit 1
}

usage() {
    echo "Uso: $0 [next|prev|goto <ws>|organize]"
    echo "  next:      Va al siguiente workspace ocupado"
    echo "  prev:      Va al workspace ocupado anterior"
    echo "  goto <ws>: Va a un workspace específico (numérico o por nombre)"
    echo "  organize:  Mueve ventanas comunes a sus workspaces designados"
    exit 1
}

# --- VALIDACIONES ---

command -v hyprctl >/dev/null 2>&1 || die "hyprctl no está instalado."
command -v jq >/dev/null 2>&1 || die "jq no está instalado. Por favor, instálalo."

# --- LÓGICA PRINCIPAL ---

ACTION=${1:-}

case "$ACTION" in
    next|prev)
        # Obtiene workspaces ocupados y el actual
        read -r -a occupied_workspaces <<< "$(hyprctl workspaces -j | jq -r '[.[] | select(.windows > 0)] | sort_by(.id) | .[].id')"
        current_workspace=$(hyprctl activeworkspace -j | jq -r '.id')
        
        if [ ${#occupied_workspaces[@]} -eq 0 ]; then
            exit 0 # No hay nada que hacer
        fi

        # Encuentra el índice del workspace actual
        current_index=-1
        for i in "${!occupied_workspaces[@]}"; do
            if [[ "${occupied_workspaces[$i]}" == "$current_workspace" ]]; then
                current_index=$i
                break
            fi
        done

        # Calcula el siguiente/anterior índice
        if [ "$ACTION" == "next" ]; then
            next_index=$(( (current_index + 1) % ${#occupied_workspaces[@]} ))
        else # prev
            next_index=$(( (current_index - 1 + ${#occupied_workspaces[@]}) % ${#occupied_workspaces[@]} ))
        fi
        
        hyprctl dispatch workspace "${occupied_workspaces[$next_index]}"
        ;;
    goto)
        WORKSPACE=${2:?"Debes especificar un workspace"}
        hyprctl dispatch workspace "$WORKSPACE"
        ;;
    organize)
        # Ejemplo de cómo mover ventanas a sus workspaces predefinidos
        # Esto se basa en las windowrules que ya configuramos.
        # Esta función puede ser lenta si hay muchas ventanas.
        echo "Organizando ventanas..."
        hyprctl clients -j | jq -c '.[]' | while read -r client; do
            class=$(echo "$client" | jq -r '.class')
            case "$class" in
                kitty)
                    hyprctl dispatch movetoworkspacesilent name:,address:$(echo "$client" | jq -r '.address')
                    ;;
                firefox|chrome|brave)
                    hyprctl dispatch movetoworkspacesilent name:,address:$(echo "$client" | jq -r '.address')
                    ;;
                code-oss|vscodium)
                    hyprctl dispatch movetoworkspacesilent name:,address:$(echo "$client" | jq -r '.address')
                    ;;
                # Añade más reglas aquí
            esac
        done
        echo "Organización completada."
        ;;
    *)
        usage
        ;;
esac