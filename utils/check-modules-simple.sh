#!/usr/bin/env bash
# Verificador simplificado de coherencia de módulos
# Verifica que kitty, fastfetch, nano y zsh tengan estructura coherente

set -e

ROOT_DIR="$(dirname "$0")/.."
source "$ROOT_DIR/core/colors.sh"

# Módulos a verificar
MODULES=("kitty" "fastfetch" "nano" "zsh")

# Verificar estructura de módulo
verify_module_structure() {
    local module="$1"
    local module_dir="$ROOT_DIR/modules/$module"
    local errors=0
    
    # Verificar que el directorio existe
    if [[ ! -d "$module_dir" ]]; then
        echo -e "${RED}✗ Directorio no encontrado: $module${RESET}"
        return 1
    fi
    
    # Verificar archivos requeridos
    local required_files=("install.sh")
    for file in "${required_files[@]}"; do
        if [[ ! -f "$module_dir/$file" ]]; then
            echo -e "${RED}✗ Archivo faltante: $module/$file${RESET}"
            ((errors++))
        fi
    done
    
    # Verificar permisos de ejecución en install.sh
    if [[ -f "$module_dir/install.sh" ]] && [[ ! -x "$module_dir/install.sh" ]]; then
        echo -e "${RED}✗ install.sh sin permisos: $module${RESET}"
        ((errors++))
    fi
    
    # Verificar directorio config (opcional para fastfetch)
    if [[ ! -d "$module_dir/config" ]]; then
        if [[ "$module" != "fastfetch" ]]; then
            echo -e "${RED}✗ Directorio config faltante: $module${RESET}"
            ((errors++))
        fi
    fi
    
    # Verificar archivos de configuración
    local config_files=()
    case "$module" in
        "kitty")
            config_files=("kitty.conf" "colors-dreamcoder.conf")
            ;;
        "fastfetch")
            config_files=("config.json")
            ;;
        "nano")
            config_files=("nanorc.conf")
            ;;
        "zsh")
            config_files=(".zshrc")
            ;;
    esac
    
    for file in "${config_files[@]}"; do
        if [[ ! -f "$module_dir/config/$file" ]] && [[ ! -f "$module_dir/$file" ]]; then
            echo -e "${RED}✗ Config faltante: $module/$file${RESET}"
            ((errors++))
        fi
    done
    
    return $errors
}

# Verificar coherencia de temas
verify_theme_coherence() {
    local module="$1"
    local module_dir="$ROOT_DIR/modules/$module"
    local errors=0
    
    case "$module" in
        "kitty")
            if grep -q "FiraCode Nerd Font" "$module_dir/config/kitty.conf" 2>/dev/null; then
                echo -e "${GREEN}✓ Kitty: FiraCode Nerd Font${RESET}"
            else
                echo -e "${YELLOW}⚠ Kitty: Fuente no verificada${RESET}"
                ((errors++))
            fi
            ;;
        "fastfetch")
            if grep -q "Catppuccin\|catppuccin" "$module_dir/config.json" 2>/dev/null; then
                echo -e "${GREEN}✓ Fastfetch: Tema Catppuccin${RESET}"
            else
                echo -e "${YELLOW}⚠ Fastfetch: Tema no verificado${RESET}"
            fi
            ;;
        "nano")
            if grep -q "Catppuccin Mocha" "$module_dir/nanorc.conf" 2>/dev/null; then
                echo -e "${GREEN}✓ Nano: Tema Catppuccin Mocha${RESET}"
            else
                echo -e "${YELLOW}⚠ Nano: Tema no verificado${RESET}"
                ((errors++))
            fi
            ;;
        "zsh")
            if grep -q "powerlevel10k" "$module_dir/config/.zshrc" 2>/dev/null; then
                echo -e "${GREEN}✓ Zsh: Powerlevel10k${RESET}"
            else
                echo -e "${YELLOW}⚠ Zsh: Powerlevel10k no verificado${RESET}"
                ((errors++))
            fi
            ;;
    esac
    
    return $errors
}

# Función principal
main() {
    echo -e "${CYAN}=== Verificación de Coherencia de Módulos ===${RESET}"
    echo ""
    
    local total_errors=0
    local total_modules=${#MODULES[@]}
    local successful_modules=0
    
    for module in "${MODULES[@]}"; do
        echo -e "${BLUE}Verificando: $module${RESET}"
        
        local module_errors=0
        
        # Verificar estructura
        if verify_module_structure "$module"; then
            echo -e "${GREEN}✓ Estructura: OK${RESET}"
        else
            echo -e "${RED}✗ Estructura: ERRORES${RESET}"
            ((module_errors++))
        fi
        
        # Verificar coherencia de temas
        if verify_theme_coherence "$module"; then
            echo -e "${GREEN}✓ Temas: OK${RESET}"
        else
            echo -e "${YELLOW}⚠ Temas: ADVERTENCIAS${RESET}"
        fi
        
        if [[ $module_errors -eq 0 ]]; then
            ((successful_modules++))
        else
            ((total_errors += module_errors))
        fi
        
        echo ""
    done
    
    # Resumen final
    echo -e "${CYAN}=== Resumen ===${RESET}"
    echo -e "Módulos verificados: $total_modules"
    echo -e "Módulos exitosos: $successful_modules"
    echo -e "Errores totales: $total_errors"
    echo ""
    
    if [[ $total_errors -eq 0 ]]; then
        echo -e "${GREEN}✓ Todos los módulos están coherentes${RESET}"
        return 0
    else
        echo -e "${RED}✗ Se encontraron errores de coherencia${RESET}"
        return 1
    fi
}

# Ejecutar si se llama directamente
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main "$@"
fi 