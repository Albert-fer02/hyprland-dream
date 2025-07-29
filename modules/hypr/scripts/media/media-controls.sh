#!/usr/bin/env bash
# Script para controles de media usando playerctl
set -e

ROOT_DIR="$(dirname "$0")/../.."
source "$ROOT_DIR/core/logger.sh"

init_logger

# Verificar si playerctl está instalado
check_playerctl() {
    if ! command -v playerctl &>/dev/null; then
        log_error "playerctl no está instalado. Instálalo con: sudo pacman -S playerctl"
        exit 1
    fi
}

# Obtener información del reproductor actual
get_player_info() {
    local player=$(playerctl -l 2>/dev/null | head -1)
    if [[ -n "$player" ]]; then
        echo "$player"
    else
        echo "none"
    fi
}

# Mostrar estado del reproductor
show_status() {
    local player=$(get_player_info)
    
    if [[ "$player" == "none" ]]; then
        echo "No hay reproductores activos"
        return
    fi
    
    echo -e "$CYAN=== Estado del Reproductor ===$RESET"
    echo -e "$BLUE Reproductor:$RESET $player"
    echo -e "$BLUE Estado:$RESET $(playerctl -p "$player" status 2>/dev/null || echo "Desconocido")"
    echo -e "$BLUE Título:$RESET $(playerctl -p "$player" metadata title 2>/dev/null || echo "Desconocido")"
    echo -e "$BLUE Artista:$RESET $(playerctl -p "$player" metadata artist 2>/dev/null || echo "Desconocido")"
    echo -e "$BLUE Álbum:$RESET $(playerctl -p "$player" metadata album 2>/dev/null || echo "Desconocido")"
}

# Controlar reproducción
control_playback() {
    local action="$1"
    local player=$(get_player_info)
    
    if [[ "$player" == "none" ]]; then
        log_error "No hay reproductores activos"
        return 1
    fi
    
    case "$action" in
        "play")
            playerctl -p "$player" play
            log_info "Reproduciendo"
            ;;
        "pause")
            playerctl -p "$player" pause
            log_info "Pausado"
            ;;
        "play-pause")
            playerctl -p "$player" play-pause
            log_info "Play/Pause"
            ;;
        "next")
            playerctl -p "$player" next
            log_info "Siguiente"
            ;;
        "previous")
            playerctl -p "$player" previous
            log_info "Anterior"
            ;;
        "stop")
            playerctl -p "$player" stop
            log_info "Detenido"
            ;;
        *)
            log_error "Acción desconocida: $action"
            return 1
            ;;
    esac
}

# Controlar volumen
control_volume() {
    local action="$1"
    local value="$2"
    
    case "$action" in
        "up")
            if [[ -n "$value" ]]; then
                playerctl volume "$value"
            else
                playerctl volume 0.1+
            fi
            log_info "Volumen aumentado"
            ;;
        "down")
            if [[ -n "$value" ]]; then
                playerctl volume "$value"
            else
                playerctl volume 0.1-
            fi
            log_info "Volumen disminuido"
            ;;
        "set")
            if [[ -n "$value" ]]; then
                playerctl volume "$value"
                log_info "Volumen establecido a $value"
            else
                log_error "Valor de volumen requerido"
                return 1
            fi
            ;;
        *)
            log_error "Acción de volumen desconocida: $action"
            return 1
            ;;
    esac
}

# Listar reproductores disponibles
list_players() {
    echo -e "$CYAN=== Reproductores Disponibles ===$RESET"
    local players=$(playerctl -l 2>/dev/null)
    
    if [[ -n "$players" ]]; then
        echo "$players" | while read -r player; do
            local status=$(playerctl -p "$player" status 2>/dev/null || echo "Desconocido")
            echo -e "$BLUE $player:$RESET $status"
        done
    else
        echo "No hay reproductores disponibles"
    fi
}

# Mostrar menú interactivo
show_menu() {
    echo -e "\n$CYAN=== Controles de Media ===$RESET"
    echo " 1) Mostrar estado"
    echo " 2) Play/Pause"
    echo " 3) Siguiente"
    echo " 4) Anterior"
    echo " 5) Detener"
    echo " 6) Subir volumen"
    echo " 7) Bajar volumen"
    echo " 8) Listar reproductores"
    echo " 0) Salir"
    echo -n "Opción: "
    read -r opt
    
    case $opt in
        1) show_status ;;
        2) control_playback "play-pause" ;;
        3) control_playback "next" ;;
        4) control_playback "previous" ;;
        5) control_playback "stop" ;;
        6) control_volume "up" ;;
        7) control_volume "down" ;;
        8) list_players ;;
        0) log_info "Saliendo..."; exit 0 ;;
        *) log_warn "Opción inválida." ;;
    esac
}

# Función principal
main() {
    check_playerctl
    
    local action="${1:-menu}"
    
    case "$action" in
        "status")
            show_status
            ;;
        "play")
            control_playback "play"
            ;;
        "pause")
            control_playback "pause"
            ;;
        "play-pause")
            control_playback "play-pause"
            ;;
        "next")
            control_playback "next"
            ;;
        "previous")
            control_playback "previous"
            ;;
        "stop")
            control_playback "stop"
            ;;
        "volume-up")
            control_volume "up" "$2"
            ;;
        "volume-down")
            control_volume "down" "$2"
            ;;
        "volume-set")
            control_volume "set" "$2"
            ;;
        "list")
            list_players
            ;;
        "menu"|"")
            show_menu
            ;;
        *)
            log_error "Acción desconocida: $action"
            echo "Uso: $0 [status|play|pause|play-pause|next|previous|stop|volume-up|volume-down|volume-set|list|menu]"
            exit 1
            ;;
    esac
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main "$@"
fi 