#!/usr/bin/env bash
# App History Script for Rofi - Advanced Integration
# Manages application usage history and provides statistics

set -e

SCRIPT_DIR="$(dirname "$0")"
ROOT_DIR="$SCRIPT_DIR/../.."
source "$ROOT_DIR/lib/utils.sh"

# Configuración
HISTORY_FILE="$HOME/.cache/rofi/app_history"
STATS_FILE="$HOME/.cache/rofi/app_stats"
MAX_HISTORY=200
MAX_DISPLAY=50

# Crear directorios si no existen
mkdir -p "$(dirname "$HISTORY_FILE")"
mkdir -p "$(dirname "$STATS_FILE")"

# Función para agregar aplicación al historial
add_app_to_history() {
    local app_name="$1"
    local timestamp=$(date +%s)
    
    if [[ -n "$app_name" ]]; then
        # Agregar entrada con timestamp
        echo "$timestamp:$app_name" >> "$HISTORY_FILE"
        
        # Mantener solo las últimas entradas
        tail -n "$MAX_HISTORY" "$HISTORY_FILE" > "$HISTORY_FILE.tmp" && mv "$HISTORY_FILE.tmp" "$HISTORY_FILE"
        
        # Actualizar estadísticas
        update_stats "$app_name"
    fi
}

# Función para actualizar estadísticas
update_stats() {
    local app_name="$1"
    local stats_file="$STATS_FILE"
    
    # Incrementar contador para la aplicación
    if grep -q "^$app_name:" "$stats_file" 2>/dev/null; then
        # Obtener contador actual
        local current_count=$(grep "^$app_name:" "$stats_file" | cut -d: -f2)
        local new_count=$((current_count + 1))
        
        # Actualizar contador
        sed -i "s/^$app_name:$current_count/$app_name:$new_count/" "$stats_file"
    else
        # Agregar nueva entrada
        echo "$app_name:1" >> "$stats_file"
    fi
}

# Función para obtener aplicaciones más usadas
get_most_used_apps() {
    if [[ -f "$STATS_FILE" ]]; then
        sort -t: -k2 -nr "$STATS_FILE" | head -n "$MAX_DISPLAY" | cut -d: -f1
    fi
}

# Función para obtener aplicaciones recientes
get_recent_apps() {
    if [[ -f "$HISTORY_FILE" ]]; then
        sort -t: -k1 -nr "$HISTORY_FILE" | head -n "$MAX_DISPLAY" | cut -d: -f2 | uniq
    fi
}

# Función para buscar aplicaciones en el historial
search_history() {
    local query="$1"
    if [[ -f "$HISTORY_FILE" ]]; then
        grep -i "$query" "$HISTORY_FILE" | cut -d: -f2 | sort | uniq | head -n "$MAX_DISPLAY"
    fi
}

# Función para obtener estadísticas detalladas
get_detailed_stats() {
    echo "=== Estadísticas de Aplicaciones ==="
    echo ""
    
    if [[ -f "$STATS_FILE" ]]; then
        echo "Aplicaciones más usadas:"
        sort -t: -k2 -nr "$STATS_FILE" | head -n 10 | while IFS=: read -r app count; do
            printf "  %-30s %d veces\n" "$app" "$count"
        done
    else
        echo "No hay estadísticas disponibles."
    fi
    
    echo ""
    echo "Aplicaciones recientes:"
    get_recent_apps | head -n 10 | while read -r app; do
        echo "  $app"
    done
}

# Función para limpiar historial
clean_history() {
    local days="$1"
    if [[ -z "$days" ]]; then
        days=30
    fi
    
    local cutoff_date=$(date -d "$days days ago" +%s)
    
    if [[ -f "$HISTORY_FILE" ]]; then
        # Filtrar entradas más recientes que la fecha de corte
        while IFS=: read -r timestamp app_name; do
            if [[ "$timestamp" -gt "$cutoff_date" ]]; then
                echo "$timestamp:$app_name"
            fi
        done < "$HISTORY_FILE" > "$HISTORY_FILE.tmp"
        
        mv "$HISTORY_FILE.tmp" "$HISTORY_FILE"
        print_ok "Historial limpiado (entradas más antiguas de $days días eliminadas)"
    fi
}

# Función para exportar historial
export_history() {
    local format="$1"
    local output_file="$2"
    
    if [[ -z "$output_file" ]]; then
        output_file="$HOME/rofi_history_$(date +%Y%m%d_%H%M%S).txt"
    fi
    
    case "$format" in
        "text")
            if [[ -f "$HISTORY_FILE" ]]; then
                while IFS=: read -r timestamp app_name; do
                    local date_str=$(date -d "@$timestamp" '+%Y-%m-%d %H:%M:%S')
                    echo "$date_str: $app_name"
                done < "$HISTORY_FILE" > "$output_file"
            fi
            ;;
        "csv")
            echo "timestamp,app_name,date" > "$output_file"
            if [[ -f "$HISTORY_FILE" ]]; then
                while IFS=: read -r timestamp app_name; do
                    local date_str=$(date -d "@$timestamp" '+%Y-%m-%d %H:%M:%S')
                    echo "$timestamp,$app_name,$date_str" >> "$output_file"
                done < "$HISTORY_FILE"
            fi
            ;;
        *)
            print_warn "Formato no válido. Usando texto por defecto."
            export_history "text" "$output_file"
            return
            ;;
    esac
    
    print_ok "Historial exportado a: $output_file"
}

# Función para obtener sugerencias inteligentes
get_smart_suggestions() {
    local query="$1"
    local suggestions=()
    
    # Buscar en aplicaciones más usadas
    while IFS= read -r app; do
        if [[ "$app" =~ $query ]]; then
            suggestions+=("$app")
        fi
    done < <(get_most_used_apps)
    
    # Buscar en aplicaciones recientes
    while IFS= read -r app; do
        if [[ "$app" =~ $query ]] && [[ ! " ${suggestions[@]} " =~ " $app " ]]; then
            suggestions+=("$app")
        fi
    done < <(get_recent_apps)
    
    # Mostrar sugerencias
    printf '%s\n' "${suggestions[@]}" | head -n "$MAX_DISPLAY"
}

# Función principal
main() {
    local action="$1"
    shift
    
    case "$action" in
        "add")
            add_app_to_history "$1"
            ;;
        "recent")
            get_recent_apps
            ;;
        "popular")
            get_most_used_apps
            ;;
        "search")
            search_history "$1"
            ;;
        "stats")
            get_detailed_stats
            ;;
        "clean")
            clean_history "$1"
            ;;
        "export")
            export_history "$1" "$2"
            ;;
        "suggest")
            get_smart_suggestions "$1"
            ;;
        *)
            echo "Uso: $0 {add|recent|popular|search|stats|clean|export|suggest} [args...]"
            echo ""
            echo "Comandos:"
            echo "  add <app>           - Agregar aplicación al historial"
            echo "  recent              - Mostrar aplicaciones recientes"
            echo "  popular             - Mostrar aplicaciones más usadas"
            echo "  search <query>      - Buscar en el historial"
            echo "  stats               - Mostrar estadísticas detalladas"
            echo "  clean [days]        - Limpiar historial (días por defecto: 30)"
            echo "  export <format> [file] - Exportar historial (text|csv)"
            echo "  suggest <query>     - Obtener sugerencias inteligentes"
            exit 1
            ;;
    esac
}

# Si se ejecuta directamente
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    if [[ $# -lt 1 ]]; then
        echo "Uso: $0 {add|recent|popular|search|stats|clean|export|suggest} [args...]"
        exit 1
    fi
    
    main "$@"
fi 