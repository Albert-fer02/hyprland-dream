#!/usr/bin/env bash
# Advanced Calculator Script for Rofi
# Provides mathematical calculations, unit conversions, and scientific functions

set -e

SCRIPT_DIR="$(dirname "$0")"
ROOT_DIR="$SCRIPT_DIR/../.."
source "$ROOT_DIR/lib/utils.sh"

# Configuración
HISTORY_FILE="$HOME/.cache/rofi/calc_history"
MAX_HISTORY=50

# Crear directorios si no existen
mkdir -p "$(dirname "$HISTORY_FILE")"

# Función para agregar cálculo al historial
add_to_history() {
    local expression="$1"
    local result="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    if [[ -n "$expression" && -n "$result" ]]; then
        echo "$timestamp: $expression = $result" >> "$HISTORY_FILE"
        # Mantener solo las últimas entradas
        tail -n "$MAX_HISTORY" "$HISTORY_FILE" > "$HISTORY_FILE.tmp" && mv "$HISTORY_FILE.tmp" "$HISTORY_FILE"
    fi
}

# Función para cálculo básico
basic_calc() {
    local expression="$1"
    local result
    
    # Limpiar expresión de caracteres especiales
    expression=$(echo "$expression" | sed 's/[^0-9+\-*/().,]/ /g')
    
    if command -v bc >/dev/null 2>&1; then
        result=$(echo "scale=6; $expression" | bc -l 2>/dev/null)
    elif command -v python3 >/dev/null 2>&1; then
        result=$(python3 -c "print(eval('$expression'))" 2>/dev/null)
    else
        echo "Error: No se encontró calculadora disponible"
        return 1
    fi
    
    if [[ -n "$result" && "$result" != "Error" ]]; then
        echo "$result"
        add_to_history "$expression" "$result"
    else
        echo "Error en el cálculo"
    fi
}

# Función para conversión de unidades
unit_conversion() {
    local from="$1"
    local to="$2"
    local value="$3"
    
    case "$from:$to" in
        "km:mi")
            echo "scale=6; $value * 0.621371" | bc -l
            ;;
        "mi:km")
            echo "scale=6; $value * 1.60934" | bc -l
            ;;
        "kg:lb")
            echo "scale=6; $value * 2.20462" | bc -l
            ;;
        "lb:kg")
            echo "scale=6; $value * 0.453592" | bc -l
            ;;
        "c:f")
            echo "scale=6; $value * 9/5 + 32" | bc -l
            ;;
        "f:c")
            echo "scale=6; ($value - 32) * 5/9" | bc -l
            ;;
        "c:k")
            echo "scale=6; $value + 273.15" | bc -l
            ;;
        "k:c")
            echo "scale=6; $value - 273.15" | bc -l
            ;;
        "f:k")
            echo "scale=6; ($value - 32) * 5/9 + 273.15" | bc -l
            ;;
        "k:f")
            echo "scale=6; ($value - 273.15) * 9/5 + 32" | bc -l
            ;;
        *)
            echo "Conversión no soportada: $from -> $to"
            return 1
            ;;
    esac
}

# Función para funciones trigonométricas
trig_calc() {
    local function="$1"
    local value="$2"
    local result
    
    if command -v python3 >/dev/null 2>&1; then
        case "$function" in
            "sin")
                result=$(python3 -c "import math; print(math.sin(math.radians($value)))")
                ;;
            "cos")
                result=$(python3 -c "import math; print(math.cos(math.radians($value)))")
                ;;
            "tan")
                result=$(python3 -c "import math; print(math.tan(math.radians($value)))")
                ;;
            "asin")
                result=$(python3 -c "import math; print(math.degrees(math.asin($value)))")
                ;;
            "acos")
                result=$(python3 -c "import math; print(math.degrees(math.acos($value)))")
                ;;
            "atan")
                result=$(python3 -c "import math; print(math.degrees(math.atan($value)))")
                ;;
            *)
                echo "Función trigonométrica no soportada: $function"
                return 1
                ;;
        esac
        echo "$result"
    else
        echo "Error: Python3 requerido para funciones trigonométricas"
    fi
}

# Función para funciones matemáticas avanzadas
advanced_calc() {
    local function="$1"
    local value="$2"
    local result
    
    if command -v python3 >/dev/null 2>&1; then
        case "$function" in
            "sqrt")
                result=$(python3 -c "import math; print(math.sqrt($value))")
                ;;
            "log")
                result=$(python3 -c "import math; print(math.log10($value))")
                ;;
            "ln")
                result=$(python3 -c "import math; print(math.log($value))")
                ;;
            "exp")
                result=$(python3 -c "import math; print(math.exp($value))")
                ;;
            "pow")
                local base="$value"
                local exponent="$3"
                result=$(python3 -c "print($base ** $exponent)")
                ;;
            "factorial")
                result=$(python3 -c "import math; print(math.factorial(int($value)))")
                ;;
            *)
                echo "Función no soportada: $function"
                return 1
                ;;
        esac
        echo "$result"
    else
        echo "Error: Python3 requerido para funciones avanzadas"
    fi
}

# Función para mostrar historial de cálculos
show_history() {
    if [[ -f "$HISTORY_FILE" ]]; then
        echo "=== Historial de Cálculos ==="
        echo ""
        tail -n 10 "$HISTORY_FILE" | while read -r line; do
            echo "  $line"
        done
    else
        echo "No hay historial de cálculos disponible."
    fi
}

# Función para limpiar historial
clear_history() {
    if [[ -f "$HISTORY_FILE" ]]; then
        rm "$HISTORY_FILE"
        print_ok "Historial de cálculos limpiado"
    fi
}

# Función para mostrar ayuda
show_help() {
    echo "=== Calculadora Avanzada para Rofi ==="
    echo ""
    echo "Uso: $0 {basic|unit|trig|advanced|history|clear|help} [args...]"
    echo ""
    echo "Comandos:"
    echo "  basic <expression>    - Cálculo básico (ej: 2+3*4)"
    echo "  unit <from> <to> <value> - Conversión de unidades"
    echo "  trig <function> <value> - Funciones trigonométricas"
    echo "  advanced <function> <value> [arg2] - Funciones avanzadas"
    echo "  history               - Mostrar historial"
    echo "  clear                 - Limpiar historial"
    echo "  help                  - Mostrar esta ayuda"
    echo ""
    echo "Conversiones soportadas:"
    echo "  km<->mi, kg<->lb, c<->f<->k"
    echo ""
    echo "Funciones trigonométricas:"
    echo "  sin, cos, tan, asin, acos, atan"
    echo ""
    echo "Funciones avanzadas:"
    echo "  sqrt, log, ln, exp, pow, factorial"
    echo ""
    echo "Ejemplos:"
    echo "  $0 basic '2+3*4'"
    echo "  $0 unit km mi 100"
    echo "  $0 trig sin 30"
    echo "  $0 advanced sqrt 16"
}

# Función principal
main() {
    local action="$1"
    shift
    
    case "$action" in
        "basic")
            if [[ -z "$1" ]]; then
                echo "Error: Se requiere una expresión"
                exit 1
            fi
            basic_calc "$1"
            ;;
        "unit")
            if [[ $# -lt 3 ]]; then
                echo "Error: Se requieren 3 argumentos: from to value"
                exit 1
            fi
            unit_conversion "$1" "$2" "$3"
            ;;
        "trig")
            if [[ $# -lt 2 ]]; then
                echo "Error: Se requieren 2 argumentos: function value"
                exit 1
            fi
            trig_calc "$1" "$2"
            ;;
        "advanced")
            if [[ $# -lt 2 ]]; then
                echo "Error: Se requieren al menos 2 argumentos: function value [arg2]"
                exit 1
            fi
            if [[ "$1" == "pow" && $# -lt 3 ]]; then
                echo "Error: pow requiere 3 argumentos: pow base exponent"
                exit 1
            fi
            advanced_calc "$@"
            ;;
        "history")
            show_history
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
        echo "Uso: $0 {basic|unit|trig|advanced|history|clear|help} [args...]"
        echo "Use 'help' para más información"
        exit 1
    fi
    
    main "$@"
fi 