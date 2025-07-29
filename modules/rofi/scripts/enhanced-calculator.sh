#!/usr/bin/env bash
# Enhanced Calculator for Rofi
# Features: scientific functions, history, unit conversion, better error handling

set -e

SCRIPT_DIR="$(dirname "$0")"
HISTORY_FILE="$HOME/.cache/rofi-calculator-history"
CONFIG_FILE="$HOME/.config/rofi/calculator-config.conf"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
RESET='\033[0m'

# Mathematical constants
PI=3.14159265359
E=2.71828182846

# Load configuration
load_config() {
    if [[ -f "$CONFIG_FILE" ]]; then
        source "$CONFIG_FILE"
    else
        # Default configuration
        DECIMAL_PLACES=6
        HISTORY_SIZE=50
        ENABLE_UNITS=true
        ENABLE_SCIENTIFIC=true
    fi
}

# Initialize history file
init_history() {
    mkdir -p "$(dirname "$HISTORY_FILE")"
    touch "$HISTORY_FILE"
}

# Add to history
add_to_history() {
    local expression="$1"
    local result="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    echo "$timestamp|$expression|$result" >> "$HISTORY_FILE"
    
    # Keep history manageable
    if [[ $(wc -l < "$HISTORY_FILE") -gt $HISTORY_SIZE ]]; then
        tail -$HISTORY_SIZE "$HISTORY_FILE" > "$HISTORY_FILE.tmp"
        mv "$HISTORY_FILE.tmp" "$HISTORY_FILE"
    fi
}

# Get calculation history
get_history() {
    if [[ -f "$HISTORY_FILE" ]]; then
        while IFS='|' read -r timestamp expression result; do
            echo "$expression = $result"
        done < "$HISTORY_FILE" | tail -10
    fi
}

# Basic arithmetic operations
basic_calc() {
    local expression="$1"
    
    # Replace common symbols
    expression=$(echo "$expression" | sed 's/×/*/g' | sed 's/÷/\//g' | sed 's/π/3.14159265359/g' | sed 's/e/2.71828182846/g')
    
    # Validate expression
    if [[ ! "$expression" =~ ^[0-9+\-*/().\s]+$ ]] && [[ ! "$expression" =~ ^[0-9+\-*/().\s]+$ ]]; then
        echo "Error: Invalid characters in expression"
        return 1
    fi
    
    # Calculate using bc
    local result=$(echo "scale=$DECIMAL_PLACES; $expression" | bc -l 2>/dev/null)
    
    if [[ $? -eq 0 ]] && [[ -n "$result" ]]; then
        echo "$result"
    else
        echo "Error: Invalid expression"
        return 1
    fi
}

# Scientific functions
scientific_calc() {
    local expression="$1"
    local result
    
    # Trigonometric functions
    if [[ "$expression" =~ ^sin\((.*)\)$ ]]; then
        local arg="${BASH_REMATCH[1]}"
        local rad=$(echo "scale=10; $arg * $PI / 180" | bc -l)
        result=$(echo "scale=$DECIMAL_PLACES; s($rad)" | bc -l)
    elif [[ "$expression" =~ ^cos\((.*)\)$ ]]; then
        local arg="${BASH_REMATCH[1]}"
        local rad=$(echo "scale=10; $arg * $PI / 180" | bc -l)
        result=$(echo "scale=$DECIMAL_PLACES; c($rad)" | bc -l)
    elif [[ "$expression" =~ ^tan\((.*)\)$ ]]; then
        local arg="${BASH_REMATCH[1]}"
        local rad=$(echo "scale=10; $arg * $PI / 180" | bc -l)
        result=$(echo "scale=$DECIMAL_PLACES; s($rad) / c($rad)" | bc -l)
    elif [[ "$expression" =~ ^asin\((.*)\)$ ]]; then
        local arg="${BASH_REMATCH[1]}"
        result=$(echo "scale=10; a($arg / sqrt(1 - $arg * $arg)) * 180 / $PI" | bc -l)
        result=$(echo "scale=$DECIMAL_PLACES; $result" | bc -l)
    elif [[ "$expression" =~ ^acos\((.*)\)$ ]]; then
        local arg="${BASH_REMATCH[1]}"
        result=$(echo "scale=10; a(sqrt(1 - $arg * $arg) / $arg) * 180 / $PI" | bc -l)
        result=$(echo "scale=$DECIMAL_PLACES; $result" | bc -l)
    elif [[ "$expression" =~ ^atan\((.*)\)$ ]]; then
        local arg="${BASH_REMATCH[1]}"
        result=$(echo "scale=10; a($arg) * 180 / $PI" | bc -l)
        result=$(echo "scale=$DECIMAL_PLACES; $result" | bc -l)
    # Logarithmic functions
    elif [[ "$expression" =~ ^ln\((.*)\)$ ]]; then
        local arg="${BASH_REMATCH[1]}"
        result=$(echo "scale=$DECIMAL_PLACES; l($arg)" | bc -l)
    elif [[ "$expression" =~ ^log\((.*)\)$ ]]; then
        local arg="${BASH_REMATCH[1]}"
        result=$(echo "scale=$DECIMAL_PLACES; l($arg) / l(10)" | bc -l)
    elif [[ "$expression" =~ ^log2\((.*)\)$ ]]; then
        local arg="${BASH_REMATCH[1]}"
        result=$(echo "scale=$DECIMAL_PLACES; l($arg) / l(2)" | bc -l)
    # Power and root functions
    elif [[ "$expression" =~ ^sqrt\((.*)\)$ ]]; then
        local arg="${BASH_REMATCH[1]}"
        result=$(echo "scale=$DECIMAL_PLACES; sqrt($arg)" | bc -l)
    elif [[ "$expression" =~ ^cbrt\((.*)\)$ ]]; then
        local arg="${BASH_REMATCH[1]}"
        result=$(echo "scale=$DECIMAL_PLACES; e(l($arg) / 3)" | bc -l)
    elif [[ "$expression" =~ ^pow\((.*),(.*)\)$ ]]; then
        local base="${BASH_REMATCH[1]}"
        local exp="${BASH_REMATCH[2]}"
        result=$(echo "scale=$DECIMAL_PLACES; $base ^ $exp" | bc -l)
    # Other functions
    elif [[ "$expression" =~ ^abs\((.*)\)$ ]]; then
        local arg="${BASH_REMATCH[1]}"
        if [[ $(echo "$arg < 0" | bc -l) -eq 1 ]]; then
            result=$(echo "scale=$DECIMAL_PLACES; -1 * $arg" | bc -l)
        else
            result=$(echo "scale=$DECIMAL_PLACES; $arg" | bc -l)
        fi
    elif [[ "$expression" =~ ^factorial\((.*)\)$ ]]; then
        local arg="${BASH_REMATCH[1]}"
        if [[ $arg -eq 0 ]] || [[ $arg -eq 1 ]]; then
            result=1
        else
            result=1
            for ((i=2; i<=arg; i++)); do
                result=$((result * i))
            done
        fi
    else
        return 1
    fi
    
    if [[ -n "$result" ]] && [[ "$result" != "Error" ]]; then
        echo "$result"
    else
        echo "Error: Invalid scientific function"
        return 1
    fi
}

# Unit conversions
unit_conversion() {
    local expression="$1"
    local result
    
    # Length conversions
    if [[ "$expression" =~ ^([0-9.]+)\s*(km|m|cm|mm|mi|yd|ft|in)\s*to\s*(km|m|cm|mm|mi|yd|ft|in)$ ]]; then
        local value="${BASH_REMATCH[1]}"
        local from_unit="${BASH_REMATCH[2]}"
        local to_unit="${BASH_REMATCH[3]}"
        
        # Convert to meters first
        local meters=0
        case $from_unit in
            km) meters=$(echo "scale=10; $value * 1000" | bc -l) ;;
            m) meters=$value ;;
            cm) meters=$(echo "scale=10; $value / 100" | bc -l) ;;
            mm) meters=$(echo "scale=10; $value / 1000" | bc -l) ;;
            mi) meters=$(echo "scale=10; $value * 1609.344" | bc -l) ;;
            yd) meters=$(echo "scale=10; $value * 0.9144" | bc -l) ;;
            ft) meters=$(echo "scale=10; $value * 0.3048" | bc -l) ;;
            in) meters=$(echo "scale=10; $value * 0.0254" | bc -l) ;;
        esac
        
        # Convert from meters to target unit
        case $to_unit in
            km) result=$(echo "scale=6; $meters / 1000" | bc -l) ;;
            m) result=$(echo "scale=6; $meters" | bc -l) ;;
            cm) result=$(echo "scale=6; $meters * 100" | bc -l) ;;
            mm) result=$(echo "scale=6; $meters * 1000" | bc -l) ;;
            mi) result=$(echo "scale=6; $meters / 1609.344" | bc -l) ;;
            yd) result=$(echo "scale=6; $meters / 0.9144" | bc -l) ;;
            ft) result=$(echo "scale=6; $meters / 0.3048" | bc -l) ;;
            in) result=$(echo "scale=6; $meters / 0.0254" | bc -l) ;;
        esac
        
        echo "$value $from_unit = $result $to_unit"
        return 0
    fi
    
    # Temperature conversions
    if [[ "$expression" =~ ^([0-9.-]+)\s*(C|F|K)\s*to\s*(C|F|K)$ ]]; then
        local value="${BASH_REMATCH[1]}"
        local from_unit="${BASH_REMATCH[2]}"
        local to_unit="${BASH_REMATCH[3]}"
        
        # Convert to Celsius first
        local celsius=0
        case $from_unit in
            C) celsius=$value ;;
            F) celsius=$(echo "scale=6; ($value - 32) * 5 / 9" | bc -l) ;;
            K) celsius=$(echo "scale=6; $value - 273.15" | bc -l) ;;
        esac
        
        # Convert from Celsius to target unit
        case $to_unit in
            C) result=$celsius ;;
            F) result=$(echo "scale=6; $celsius * 9 / 5 + 32" | bc -l) ;;
            K) result=$(echo "scale=6; $celsius + 273.15" | bc -l) ;;
        esac
        
        echo "$value°$from_unit = $result°$to_unit"
        return 0
    fi
    
    # Weight conversions
    if [[ "$expression" =~ ^([0-9.]+)\s*(kg|g|lb|oz)\s*to\s*(kg|g|lb|oz)$ ]]; then
        local value="${BASH_REMATCH[1]}"
        local from_unit="${BASH_REMATCH[2]}"
        local to_unit="${BASH_REMATCH[3]}"
        
        # Convert to grams first
        local grams=0
        case $from_unit in
            kg) grams=$(echo "scale=10; $value * 1000" | bc -l) ;;
            g) grams=$value ;;
            lb) grams=$(echo "scale=10; $value * 453.59237" | bc -l) ;;
            oz) grams=$(echo "scale=10; $value * 28.349523125" | bc -l) ;;
        esac
        
        # Convert from grams to target unit
        case $to_unit in
            kg) result=$(echo "scale=6; $grams / 1000" | bc -l) ;;
            g) result=$(echo "scale=6; $grams" | bc -l) ;;
            lb) result=$(echo "scale=6; $grams / 453.59237" | bc -l) ;;
            oz) result=$(echo "scale=6; $grams / 28.349523125" | bc -l) ;;
        esac
        
        echo "$value $from_unit = $result $to_unit"
        return 0
    fi
    
    return 1
}

# Main calculation function
calculate() {
    local expression="$1"
    local result
    
    # Remove extra spaces
    expression=$(echo "$expression" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    
    # Check for unit conversion first
    if [[ "$ENABLE_UNITS" == "true" ]]; then
        result=$(unit_conversion "$expression")
        if [[ $? -eq 0 ]]; then
            echo "$result"
            return 0
        fi
    fi
    
    # Check for scientific functions
    if [[ "$ENABLE_SCIENTIFIC" == "true" ]]; then
        result=$(scientific_calc "$expression")
        if [[ $? -eq 0 ]]; then
            echo "$result"
            add_to_history "$expression" "$result"
            return 0
        fi
    fi
    
    # Try basic arithmetic
    result=$(basic_calc "$expression")
    if [[ $? -eq 0 ]]; then
        echo "$result"
        add_to_history "$expression" "$result"
        return 0
    fi
    
    echo "Error: Could not evaluate expression"
    return 1
}

# Show help
show_help() {
    echo "Enhanced Calculator Help:"
    echo ""
    echo "Basic Operations:"
    echo "  2 + 3 * 4"
    echo "  (5 + 3) / 2"
    echo "  10 % 3"
    echo ""
    echo "Scientific Functions:"
    echo "  sin(45)     - Sine (degrees)"
    echo "  cos(60)     - Cosine (degrees)"
    echo "  tan(30)     - Tangent (degrees)"
    echo "  sqrt(16)    - Square root"
    echo "  pow(2,3)    - Power (2^3)"
    echo "  ln(10)      - Natural logarithm"
    echo "  log(100)    - Base-10 logarithm"
    echo "  abs(-5)     - Absolute value"
    echo "  factorial(5) - Factorial"
    echo ""
    echo "Unit Conversions:"
    echo "  5 km to m"
    echo "  32 F to C"
    echo "  2 lb to kg"
    echo ""
    echo "Constants:"
    echo "  π (pi)"
    echo "  e (euler's number)"
    echo ""
    echo "History:"
    echo "  Type 'history' to see recent calculations"
}

# Main function
main() {
    load_config
    init_history
    
    local input="$1"
    
    if [[ -z "$input" ]]; then
        echo "Enter expression or 'help' for assistance"
        return 0
    fi
    
    case "$input" in
        "help"|"h"|"?")
            show_help
            ;;
        "history"|"hist")
            get_history
            ;;
        "clear"|"cls")
            > "$HISTORY_FILE"
            echo "History cleared"
            ;;
        *)
            calculate "$input"
            ;;
    esac
}

# Handle Rofi integration
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    if [[ "$1" == "--rofi" ]]; then
        # Called by Rofi, expect input on stdin
        while read -r line; do
            if [[ -n "$line" ]]; then
                result=$(calculate "$line")
                if [[ $? -eq 0 ]]; then
                    echo "$result"
                fi
            fi
        done
    else
        main "$1"
    fi
fi 