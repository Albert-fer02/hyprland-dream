#!/usr/bin/env bash
# Sistema de validación de dependencias mejorado para hyprdream

# Configuración
DEPS_FILE="${DEPS_FILE:-$(dirname "$0")/../config/dependencies.conf}"
CACHE_FILE="/tmp/hyprdream_deps_cache"
CACHE_TIMEOUT=3600  # 1 hora

# Estados de dependencias
declare -A DEP_STATUS=(
    ["MISSING"]="FALTANTE"
    ["INSTALLED"]="INSTALADO"
    ["OPTIONAL"]="OPCIONAL"
    ["BROKEN"]="ROTO"
)

# Función para cargar dependencias desde archivo
load_dependencies() {
    local deps_file="$1"
    declare -gA REQUIRED_DEPS OPTIONAL_DEPS
    
    if [[ ! -f "$deps_file" ]]; then
        log_warn "Archivo de dependencias no encontrado: $deps_file"
        return 1
    fi
    
    while IFS='=' read -r dep_type deps; do
        [[ -z "$deps" || "$deps" =~ ^[[:space:]]*# ]] && continue
        
        case "$dep_type" in
            "REQUIRED")
                IFS=',' read -ra deps_array <<< "$deps"
                for dep in "${deps_array[@]}"; do
                    REQUIRED_DEPS["${dep// /}"]=1
                done
                ;;
            "OPTIONAL")
                IFS=',' read -ra deps_array <<< "$deps"
                for dep in "${deps_array[@]}"; do
                    OPTIONAL_DEPS["${dep// /}"]=1
                done
                ;;
        esac
    done < "$deps_file"
}

# Función para verificar si un paquete está instalado
check_package() {
    local pkg="$1"
    
    # Verificar en cache primero
    if [[ -f "$CACHE_FILE" ]]; then
        local cache_age=$(($(date +%s) - $(stat -c%Y "$CACHE_FILE" 2>/dev/null || echo 0)))
        if [[ $cache_age -lt $CACHE_TIMEOUT ]]; then
            if grep -q "^$pkg:" "$CACHE_FILE" 2>/dev/null; then
                local status=$(grep "^$pkg:" "$CACHE_FILE" | cut -d: -f2)
                echo "$status"
                return 0
            fi
        fi
    fi
    
    # Verificar si está instalado
    if pacman -Q "$pkg" &>/dev/null; then
        echo "INSTALLED"
    else
        echo "MISSING"
    fi
}

# Función para verificar si un comando está disponible
check_command() {
    local cmd="$1"
    
    if command -v "$cmd" &>/dev/null; then
        echo "INSTALLED"
    else
        echo "MISSING"
    fi
}

# Función para verificar si un archivo existe
check_file() {
    local file="$1"
    
    if [[ -f "$file" ]]; then
        echo "INSTALLED"
    else
        echo "MISSING"
    fi
}

# Función para verificar dependencias del sistema
check_system_deps() {
    local -a system_deps=(
        "pacman"
        "sudo"
        "bash"
        "grep"
        "sed"
        "awk"
    )
    
    local missing=0
    log_info "Verificando dependencias del sistema..."
    
    for dep in "${system_deps[@]}"; do
        local status=$(check_command "$dep")
        if [[ "$status" == "MISSING" ]]; then
            log_error "Dependencia crítica faltante: $dep"
            missing=$((missing + 1))
        else
            log_debug "Dependencia del sistema OK: $dep"
        fi
    done
    
    return $missing
}

# Función para verificar gestor de paquetes
check_package_manager() {
    log_info "Verificando gestor de paquetes..."
    
    # Verificar pacman
    if ! command -v pacman &>/dev/null; then
        log_error "Pacman no está disponible"
        return 1
    fi
    
    # Verificar AUR helper
    local aur_helper=""
    if command -v paru &>/dev/null; then
        aur_helper="paru"
    elif command -v yay &>/dev/null; then
        aur_helper="yay"
    else
        log_warn "No se encontró helper de AUR (paru/yay)"
    fi
    
    log_info "Gestor de paquetes: pacman + ${aur_helper:-ninguno}"
    return 0
}

# Función para verificar dependencias de Hyprland
check_hyprland_deps() {
    local -a hyprland_deps=(
        "hyprland"
        "waybar"
        "dunst"
        "kitty"
        "swww"
        "rofi"
        "mako"
        "wlogout"
        "swaylock"
    )
    
    local missing=0
    local optional_missing=0
    
    log_info "Verificando dependencias de Hyprland..."
    
    for dep in "${hyprland_deps[@]}"; do
        local status=$(check_package "$dep")
        
        case "$status" in
            "INSTALLED")
                log_info "✓ $dep está instalado"
                ;;
            "MISSING")
                if [[ " ${OPTIONAL_DEPS[*]} " =~ " ${dep} " ]]; then
                    log_warn "○ $dep (opcional) no está instalado"
                    optional_missing=$((optional_missing + 1))
                else
                    log_error "✗ $dep (requerido) no está instalado"
                    missing=$((missing + 1))
                fi
                ;;
        esac
    done
    
    echo "$missing:$optional_missing"
}

# Función para generar reporte de dependencias
generate_deps_report() {
    local report_file="${1:-/tmp/hyprdream_deps_report.txt}"
    
    {
        echo "=== Reporte de Dependencias hyprdream ==="
        echo "Fecha: $(date)"
        echo "Sistema: $(uname -a)"
        echo ""
        
        echo "--- Dependencias del Sistema ---"
        check_system_deps
        echo ""
        
        echo "--- Gestor de Paquetes ---"
        check_package_manager
        echo ""
        
        echo "--- Dependencias de Hyprland ---"
        local result=$(check_hyprland_deps)
        local missing=$(echo "$result" | cut -d: -f1)
        local optional=$(echo "$result" | cut -d: -f2)
        echo "Dependencias faltantes: $missing"
        echo "Opcionales faltantes: $optional"
        
    } > "$report_file"
    
    log_info "Reporte generado: $report_file"
}

# Función para instalar dependencias faltantes
install_missing_deps() {
    local deps_to_install=()
    
    log_info "Verificando dependencias faltantes..."
    
    # Verificar dependencias requeridas
    for dep in "${!REQUIRED_DEPS[@]}"; do
        local status=$(check_package "$dep")
        if [[ "$status" == "MISSING" ]]; then
            deps_to_install+=("$dep")
        fi
    done
    
    if [[ ${#deps_to_install[@]} -eq 0 ]]; then
        log_info "Todas las dependencias requeridas están instaladas"
        return 0
    fi
    
    log_info "Instalando dependencias faltantes: ${deps_to_install[*]}"
    
    # Instalar usando el helper disponible
    if command -v paru &>/dev/null; then
        paru -S --needed --noconfirm "${deps_to_install[@]}"
    elif command -v yay &>/dev/null; then
        yay -S --needed --noconfirm "${deps_to_install[@]}"
    else
        sudo pacman -S --needed --noconfirm "${deps_to_install[@]}"
    fi
    
    # Limpiar cache después de instalación
    rm -f "$CACHE_FILE"
    
    log_info "Instalación completada"
}

# Función principal de verificación
check_dependencies() {
    local action="${1:-check}"
    
    # Cargar dependencias
    load_dependencies "$DEPS_FILE"
    
    case "$action" in
        "check")
            check_system_deps || return 1
            check_package_manager || return 1
            check_hyprland_deps
            ;;
        "install")
            install_missing_deps
            ;;
        "report")
            generate_deps_report
            ;;
        "clean")
            rm -f "$CACHE_FILE"
            log_info "Cache de dependencias limpiado"
            ;;
        *)
            log_error "Acción desconocida: $action"
            return 1
            ;;
    esac
}

# Ejecutar si se llama directamente
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    source "$(dirname "$0")/logger.sh"
    init_logger
    
    check_dependencies "${1:-check}"
fi
