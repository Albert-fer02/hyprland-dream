#!/usr/bin/env bash
# Fuzzy Search Script for Rofi - Advanced Integration
# Provides enhanced fuzzy search with history and intelligent suggestions

set -e

SCRIPT_DIR="$(dirname "$0")"
ROOT_DIR="$SCRIPT_DIR/../.."
source "$ROOT_DIR/lib/utils.sh"

# Configuración
HISTORY_FILE="$HOME/.cache/rofi/history"
SUGGESTIONS_FILE="$HOME/.cache/rofi/suggestions"
MAX_HISTORY=100
MAX_SUGGESTIONS=20

# Crear directorios si no existen
mkdir -p "$(dirname "$HISTORY_FILE")"
mkdir -p "$(dirname "$SUGGESTIONS_FILE")"

# Función para agregar entrada al historial
add_to_history() {
    local query="$1"
    if [[ -n "$query" ]]; then
        # Agregar al inicio del archivo
        echo "$query" | cat - "$HISTORY_FILE" 2>/dev/null | head -n "$MAX_HISTORY" > "$HISTORY_FILE.tmp" && mv "$HISTORY_FILE.tmp" "$HISTORY_FILE"
    fi
}

# Función para obtener sugerencias del historial
get_history_suggestions() {
    local query="$1"
    if [[ -f "$HISTORY_FILE" ]]; then
        grep -i "$query" "$HISTORY_FILE" 2>/dev/null | head -n "$MAX_SUGGESTIONS" || true
    fi
}

# Función para obtener sugerencias de aplicaciones populares
get_app_suggestions() {
    local query="$1"
    # Obtener aplicaciones más usadas
    find /usr/share/applications -name "*.desktop" 2>/dev/null | \
    xargs grep -l "Name=" 2>/dev/null | \
    xargs grep -h "Name=" 2>/dev/null | \
    sed 's/Name=//' | \
    grep -i "$query" | \
    head -n "$MAX_SUGGESTIONS" || true
}

# Función para búsqueda fuzzy mejorada
fuzzy_search() {
    local query="$1"
    local results=()
    
    # Buscar en historial
    while IFS= read -r line; do
        if [[ -n "$line" ]]; then
            results+=("$line")
        fi
    done < <(get_history_suggestions "$query")
    
    # Buscar en aplicaciones
    while IFS= read -r line; do
        if [[ -n "$line" ]]; then
            results+=("$line")
        fi
    done < <(get_app_suggestions "$query")
    
    # Eliminar duplicados y mostrar
    printf '%s\n' "${results[@]}" | sort -u | head -n "$MAX_SUGGESTIONS"
}

# Función para búsqueda web rápida
web_search() {
    local query="$1"
    local search_engines=(
        "https://www.google.com/search?q="
        "https://duckduckgo.com/?q="
        "https://www.bing.com/search?q="
        "https://search.brave.com/search?q="
    )
    
    # Usar el primer motor de búsqueda por defecto
    local search_url="${search_engines[0]}"
    
    # Abrir en el navegador predeterminado
    if command -v xdg-open >/dev/null 2>&1; then
        xdg-open "${search_url}${query}"
    elif command -v firefox >/dev/null 2>&1; then
        firefox "${search_url}${query}"
    elif command -v chromium >/dev/null 2>&1; then
        chromium "${search_url}${query}"
    fi
}

# Función para cálculos matemáticos
math_calc() {
    local expression="$1"
    if command -v bc >/dev/null 2>&1; then
        echo "$expression" | bc -l 2>/dev/null || echo "Error en cálculo"
    elif command -v python3 >/dev/null 2>&1; then
        python3 -c "print(eval('$expression'))" 2>/dev/null || echo "Error en cálculo"
    else
        echo "Calculadora no disponible"
    fi
}

# Función para búsqueda de archivos
file_search() {
    local query="$1"
    local search_dir="$HOME"
    
    # Buscar archivos con find
    find "$search_dir" -type f -iname "*$query*" 2>/dev/null | \
    head -n 20 | \
    sed "s|$HOME|~|g"
}

# Función principal
main() {
    local mode="$1"
    local query="$2"
    
    case "$mode" in
        "history")
            get_history_suggestions "$query"
            ;;
        "apps")
            get_app_suggestions "$query"
            ;;
        "fuzzy")
            fuzzy_search "$query"
            ;;
        "web")
            web_search "$query"
            ;;
        "calc")
            math_calc "$query"
            ;;
        "files")
            file_search "$query"
            ;;
        "add")
            add_to_history "$query"
            ;;
        *)
            echo "Modo no válido. Uso: $0 {history|apps|fuzzy|web|calc|files|add} [query]"
            exit 1
            ;;
    esac
}

# Si se ejecuta directamente
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    if [[ $# -lt 1 ]]; then
        echo "Uso: $0 {history|apps|fuzzy|web|calc|files|add} [query]"
        exit 1
    fi
    
    main "$@"
fi 