#!/usr/bin/env bash
# Verificador de coherencia de módulos para hyprdream
# Verifica que kitty, fastfetch, nano y zsh tengan estructura coherente

set -e

ROOT_DIR="$(dirname "$0")/.."
source "$ROOT_DIR/core/colors.sh"
source "$ROOT_DIR/core/logger.sh"

init_logger

# Módulos a verificar
MODULES=("kitty" "fastfetch" "nano" "zsh")

# Verificar estructura de módulo
verify_module_structure() {
    local module="$1"
    local module_dir="$ROOT_DIR/modules/$module"
    local errors=0
    
    log_info "Verificando estructura de módulo: $module"
    
    # Verificar que el directorio existe
    if [[ ! -d "$module_dir" ]]; then
        log_error "Directorio de módulo no encontrado: $module_dir"
        return 1
    fi
    
    # Verificar archivos requeridos
    local required_files=("install.sh")
    for file in "${required_files[@]}"; do
        if [[ ! -f "$module_dir/$file" ]]; then
            log_error "Archivo requerido no encontrado: $module_dir/$file"
            ((errors++))
        fi
    done
    
    # Verificar README.md (opcional para módulos básicos)
    if [[ ! -f "$module_dir/README.md" ]]; then
        log_info "README.md no encontrado en $module (opcional para módulos básicos)"
    fi
    
    # Verificar permisos de ejecución en install.sh
    if [[ -f "$module_dir/install.sh" ]] && [[ ! -x "$module_dir/install.sh" ]]; then
        log_error "install.sh no tiene permisos de ejecución: $module_dir/install.sh"
        ((errors++))
    fi
    
    # Verificar directorio config (opcional para algunos módulos)
    if [[ ! -d "$module_dir/config" ]]; then
        # Para fastfetch, el config.json está en el directorio raíz
        if [[ "$module" == "fastfetch" ]]; then
            log_info "Fastfetch usa configuración en directorio raíz (coherente)"
        else
            log_error "Directorio config no encontrado: $module_dir/config"
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
            log_error "Archivo de configuración no encontrado: $file"
            ((errors++))
        else
            log_info "Archivo de configuración encontrado: $file"
        fi
    done
    
    return $errors
}

# Verificar coherencia de temas
verify_theme_coherence() {
    local module="$1"
    local module_dir="$ROOT_DIR/modules/$module"
    local errors=0
    
    log_info "Verificando coherencia de temas en: $module"
    
    case "$module" in
        "kitty")
            # Verificar que usa FiraCode Nerd Font
            if grep -q "FiraCode Nerd Font" "$module_dir/config/kitty.conf" 2>/dev/null; then
                log_info "Kitty usa FiraCode Nerd Font (coherente)"
            else
                log_warn "Kitty no usa FiraCode Nerd Font"
                ((errors++))
            fi
            ;;
        "fastfetch")
            # Verificar que usa tema Catppuccin
            if grep -q "Catppuccin\|catppuccin" "$module_dir/config.json" 2>/dev/null; then
                log_info "Fastfetch usa tema Catppuccin (coherente)"
            else
                log_warn "Fastfetch no usa tema Catppuccin explícitamente"
            fi
            ;;
        "nano")
            # Verificar que usa tema Catppuccin Mocha
            if grep -q "Catppuccin Mocha" "$module_dir/nanorc.conf" 2>/dev/null; then
                log_info "Nano usa tema Catppuccin Mocha (coherente)"
            else
                log_warn "Nano no usa tema Catppuccin Mocha explícitamente"
                ((errors++))
            fi
            ;;
        "zsh")
            # Verificar que usa Powerlevel10k y Oh My Zsh
            if grep -q "powerlevel10k" "$module_dir/config/.zshrc" 2>/dev/null; then
                log_info "Zsh usa Powerlevel10k (coherente)"
            else
                log_warn "Zsh no usa Powerlevel10k"
                ((errors++))
            fi
            ;;
    esac
    
    return $errors
}

# Verificar integración con el instalador principal
verify_installer_integration() {
    local module="$1"
    local errors=0
    
    log_info "Verificando integración del instalador para: $module"
    
    # Verificar que el módulo aparece en la lista de módulos disponibles
    if grep -q "$module" "$ROOT_DIR/install.sh" 2>/dev/null; then
        log_info "Módulo $module está integrado en el instalador principal"
    else
        log_warn "Módulo $module no aparece explícitamente en el instalador principal"
        # Esto no es necesariamente un error, ya que se detecta automáticamente
    fi
    
    return $errors
}

# Función principal
main() {
    log_info "Iniciando verificación de coherencia de módulos"
    
    local total_errors=0
    local total_modules=${#MODULES[@]}
    local successful_modules=0
    
    echo -e "${CYAN}=== Verificación de Coherencia de Módulos ===${RESET}"
    echo ""
    
    for module in "${MODULES[@]}"; do
        echo -e "${BLUE}Verificando módulo: $module${RESET}"
        
        local module_errors=0
        
        # Verificar estructura
        if verify_module_structure "$module"; then
            log_info "Estructura de $module: OK"
        else
            log_error "Estructura de $module: ERRORES"
            ((module_errors++))
        fi
        
        # Verificar coherencia de temas
        if verify_theme_coherence "$module"; then
            log_info "Temas de $module: OK"
        else
            log_warn "Temas de $module: ADVERTENCIAS"
        fi
        
        # Verificar integración
        if verify_installer_integration "$module"; then
            log_info "Integración de $module: OK"
        else
            log_warn "Integración de $module: ADVERTENCIAS"
        fi
        
        if [[ $module_errors -eq 0 ]]; then
            ((successful_modules++))
            echo -e "${GREEN}✓ $module: VERIFICADO${RESET}"
        else
            ((total_errors += module_errors))
            echo -e "${RED}✗ $module: ERRORES${RESET}"
        fi
        
        echo ""
    done
    
    # Resumen final
    echo -e "${CYAN}=== Resumen de Verificación ===${RESET}"
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