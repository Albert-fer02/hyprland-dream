#!/usr/bin/env bash
# Web Search Script for Rofi - Advanced Integration
# Provides quick web search with multiple search engines and smart suggestions

set -e

SCRIPT_DIR="$(dirname "$0")"
ROOT_DIR="$SCRIPT_DIR/../.."
source "$ROOT_DIR/lib/utils.sh"

# Configuración
HISTORY_FILE="$HOME/.cache/rofi/web_search_history"
FAVORITES_FILE="$HOME/.cache/rofi/web_favorites"
MAX_HISTORY=100

# Crear directorios si no existen
mkdir -p "$(dirname "$HISTORY_FILE")"
mkdir -p "$(dirname "$FAVORITES_FILE")"

# Motores de búsqueda disponibles
declare -A SEARCH_ENGINES=(
    ["google"]="https://www.google.com/search?q="
    ["duckduckgo"]="https://duckduckgo.com/?q="
    ["bing"]="https://www.bing.com/search?q="
    ["brave"]="https://search.brave.com/search?q="
    ["startpage"]="https://www.startpage.com/do/search?q="
    ["searx"]="https://searx.be/?q="
    ["youtube"]="https://www.youtube.com/results?search_query="
    ["github"]="https://github.com/search?q="
    ["stackoverflow"]="https://stackoverflow.com/search?q="
    ["wikipedia"]="https://en.wikipedia.org/wiki/Special:Search?search="
    ["archwiki"]="https://wiki.archlinux.org/index.php?search="
    ["aur"]="https://aur.archlinux.org/packages/?K="
)

# Función para agregar búsqueda al historial
add_to_history() {
    local query="$1"
    local engine="$2"
    local timestamp=$(date +%s)
    
    if [[ -n "$query" ]]; then
        echo "$timestamp:$engine:$query" >> "$HISTORY_FILE"
        # Mantener solo las últimas entradas
        tail -n "$MAX_HISTORY" "$HISTORY_FILE" > "$HISTORY_FILE.tmp" && mv "$HISTORY_FILE.tmp" "$HISTORY_FILE"
    fi
}

# Función para abrir URL en navegador
open_url() {
    local url="$1"
    
    # Detectar navegador predeterminado
    if command -v xdg-open >/dev/null 2>&1; then
        xdg-open "$url"
    elif command -v firefox >/dev/null 2>&1; then
        firefox "$url"
    elif command -v chromium >/dev/null 2>&1; then
        chromium "$url"
    elif command -v google-chrome >/dev/null 2>&1; then
        google-chrome "$url"
    elif command -v brave-browser >/dev/null 2>&1; then
        brave-browser "$url"
    else
        print_warn "No se encontró navegador compatible"
        return 1
    fi
}

# Función para búsqueda web
web_search() {
    local query="$1"
    local engine="${2:-google}"
    
    # Verificar si el motor de búsqueda existe
    if [[ -z "${SEARCH_ENGINES[$engine]}" ]]; then
        print_warn "Motor de búsqueda no válido: $engine"
        return 1
    fi
    
    # Codificar query para URL
    local encoded_query=$(printf '%s' "$query" | jq -sRr @uri 2>/dev/null || echo "$query" | sed 's/ /%20/g')
    local search_url="${SEARCH_ENGINES[$engine]}${encoded_query}"
    
    # Agregar al historial
    add_to_history "$query" "$engine"
    
    # Abrir en navegador
    open_url "$search_url"
    
    print_ok "Búsqueda abierta en $engine: $query"
}

# Función para búsqueda rápida con detección automática
smart_search() {
    local query="$1"
    
    # Detectar tipo de búsqueda basado en el query
    case "$query" in
        # YouTube
        *"yt:"*|*"youtube:"*)
            local yt_query=$(echo "$query" | sed 's/^yt: *//; s/^youtube: *//')
            web_search "$yt_query" "youtube"
            ;;
        # GitHub
        *"gh:"*|*"github:"*)
            local gh_query=$(echo "$query" | sed 's/^gh: *//; s/^github: *//')
            web_search "$gh_query" "github"
            ;;
        # Stack Overflow
        *"so:"*|*"stackoverflow:"*)
            local so_query=$(echo "$query" | sed 's/^so: *//; s/^stackoverflow: *//')
            web_search "$so_query" "stackoverflow"
            ;;
        # Wikipedia
        *"wiki:"*|*"wikipedia:"*)
            local wiki_query=$(echo "$query" | sed 's/^wiki: *//; s/^wikipedia: *//')
            web_search "$wiki_query" "wikipedia"
            ;;
        # Arch Wiki
        *"arch:"*|*"archwiki:"*)
            local arch_query=$(echo "$query" | sed 's/^arch: *//; s/^archwiki: *//')
            web_search "$arch_query" "archwiki"
            ;;
        # AUR
        *"aur:"*)
            local aur_query=$(echo "$query" | sed 's/^aur: *//')
            web_search "$aur_query" "aur"
            ;;
        # Búsqueda general
        *)
            web_search "$query" "google"
            ;;
    esac
}

# Función para obtener sugerencias del historial
get_history_suggestions() {
    local query="$1"
    if [[ -f "$HISTORY_FILE" ]]; then
        grep -i "$query" "$HISTORY_FILE" 2>/dev/null | \
        cut -d: -f3 | \
        sort | uniq | \
        head -n 10 || true
    fi
}

# Función para mostrar historial de búsquedas
show_history() {
    if [[ -f "$HISTORY_FILE" ]]; then
        echo "=== Historial de Búsquedas Web ==="
        echo ""
        tail -n 15 "$HISTORY_FILE" | while IFS=: read -r timestamp engine query; do
            local date_str=$(date -d "@$timestamp" '+%Y-%m-%d %H:%M')
            printf "  %s [%s] %s\n" "$date_str" "$engine" "$query"
        done
    else
        echo "No hay historial de búsquedas disponible."
    fi
}

# Función para agregar favorito
add_favorite() {
    local name="$1"
    local url="$2"
    
    if [[ -n "$name" && -n "$url" ]]; then
        echo "$name:$url" >> "$FAVORITES_FILE"
        print_ok "Favorito agregado: $name"
    fi
}

# Función para listar favoritos
list_favorites() {
    if [[ -f "$FAVORITES_FILE" ]]; then
        echo "=== Favoritos Web ==="
        echo ""
        while IFS=: read -r name url; do
            echo "  $name: $url"
        done < "$FAVORITES_FILE"
    else
        echo "No hay favoritos guardados."
    fi
}

# Función para abrir favorito
open_favorite() {
    local name="$1"
    
    if [[ -f "$FAVORITES_FILE" ]]; then
        local url=$(grep "^$name:" "$FAVORITES_FILE" | cut -d: -f2-)
        if [[ -n "$url" ]]; then
            open_url "$url"
            print_ok "Favorito abierto: $name"
        else
            print_warn "Favorito no encontrado: $name"
        fi
    fi
}

# Función para mostrar motores de búsqueda disponibles
list_engines() {
    echo "=== Motores de Búsqueda Disponibles ==="
    echo ""
    for engine in "${!SEARCH_ENGINES[@]}"; do
        echo "  $engine: ${SEARCH_ENGINES[$engine]}"
    done
}

# Función para búsqueda directa con motor específico
search_with_engine() {
    local engine="$1"
    local query="$2"
    
    if [[ -z "$query" ]]; then
        print_warn "Se requiere una consulta de búsqueda"
        return 1
    fi
    
    web_search "$query" "$engine"
}

# Función para limpiar historial
clear_history() {
    if [[ -f "$HISTORY_FILE" ]]; then
        rm "$HISTORY_FILE"
        print_ok "Historial de búsquedas limpiado"
    fi
}

# Función para mostrar ayuda
show_help() {
    echo "=== Búsqueda Web Rápida para Rofi ==="
    echo ""
    echo "Uso: $0 {search|smart|history|favorites|engines|clear|help} [args...]"
    echo ""
    echo "Comandos:"
    echo "  search <query> [engine] - Búsqueda web con motor específico"
    echo "  smart <query>           - Búsqueda inteligente con detección automática"
    echo "  history                 - Mostrar historial de búsquedas"
    echo "  favorites               - Listar favoritos"
    echo "  add-fav <name> <url>    - Agregar favorito"
    echo "  open-fav <name>         - Abrir favorito"
    echo "  engines                 - Listar motores disponibles"
    echo "  clear                   - Limpiar historial"
    echo "  help                    - Mostrar esta ayuda"
    echo ""
    echo "Prefijos para búsqueda inteligente:"
    echo "  yt: o youtube:          - Buscar en YouTube"
    echo "  gh: o github:           - Buscar en GitHub"
    echo "  so: o stackoverflow:    - Buscar en Stack Overflow"
    echo "  wiki: o wikipedia:      - Buscar en Wikipedia"
    echo "  arch: o archwiki:       - Buscar en Arch Wiki"
    echo "  aur:                    - Buscar en AUR"
    echo ""
    echo "Ejemplos:"
    echo "  $0 search 'arch linux'"
    echo "  $0 smart 'yt: how to install arch linux'"
    echo "  $0 smart 'gh: rofi themes'"
    echo "  $0 add-fav 'Arch Wiki' 'https://wiki.archlinux.org'"
}

# Función principal
main() {
    local action="$1"
    shift
    
    case "$action" in
        "search")
            if [[ -z "$1" ]]; then
                echo "Error: Se requiere una consulta de búsqueda"
                exit 1
            fi
            search_with_engine "${2:-google}" "$1"
            ;;
        "smart")
            if [[ -z "$1" ]]; then
                echo "Error: Se requiere una consulta de búsqueda"
                exit 1
            fi
            smart_search "$1"
            ;;
        "history")
            show_history
            ;;
        "favorites")
            list_favorites
            ;;
        "add-fav")
            if [[ $# -lt 2 ]]; then
                echo "Error: Se requieren nombre y URL"
                exit 1
            fi
            add_favorite "$1" "$2"
            ;;
        "open-fav")
            if [[ -z "$1" ]]; then
                echo "Error: Se requiere nombre del favorito"
                exit 1
            fi
            open_favorite "$1"
            ;;
        "engines")
            list_engines
            ;;
        "clear")
            clear_history
            ;;
        "help"|"-h"|"--help")
            show_help
            ;;
        *)
            echo "Comando no válido. Use 'help' para ver opciones disponibles."
            exit 1
            ;;
    esac
}

# Si se ejecuta directamente
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    if [[ $# -lt 1 ]]; then
        echo "Uso: $0 {search|smart|history|favorites|engines|clear|help} [args...]"
        echo "Use 'help' para más información"
        exit 1
    fi
    
    main "$@"
fi 