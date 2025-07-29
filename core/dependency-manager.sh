#!/usr/bin/env bash
# Gestor avanzado de dependencias para hyprdream
# Maneja repos AUR, instalación de helpers, resolución de conflictos y cache

source "$(dirname "$0")/colors.sh"
source "$(dirname "$0")/logger.sh"
source "$(dirname "$0")/progress.sh"

# Configuración
CACHE_DIR="${CACHE_DIR:-/var/cache/hyprdream}"
AUR_CACHE_DIR="${AUR_CACHE_DIR:-$CACHE_DIR/aur}"
PACMAN_CACHE_DIR="${PACMAN_CACHE_DIR:-$CACHE_DIR/pacman}"
CONFLICT_LOG="${CONFLICT_LOG:-/tmp/hyprdream_conflicts.log}"

# Variables globales
declare -A AUR_HELPERS=(
    ["paru"]="paru"
    ["yay"]="yay"
    ["pamac"]="pamac"
    ["trizen"]="trizen"
)
declare -A PACKAGE_CACHE=()
declare -A CONFLICT_RESOLUTIONS=()

# Función para verificar repos AUR habilitados
check_aur_repos() {
    log_info "Verificando repositorios AUR..."
    
    local aur_enabled=false
    local aur_helper=""
    
    # Verificar si hay repos AUR en pacman.conf
    if grep -q "\[aur\]" /etc/pacman.conf 2>/dev/null; then
        aur_enabled=true
        log_info "Repositorio AUR detectado en pacman.conf"
    fi
    
    # Verificar helpers de AUR disponibles
    for helper in "${!AUR_HELPERS[@]}"; do
        if command -v "$helper" &>/dev/null; then
            aur_helper="$helper"
            log_info "Helper AUR detectado: $helper"
            break
        fi
    done
    
    # Verificar si paru está disponible en repos oficiales
    if [[ -z "$aur_helper" ]]; then
        if pacman -Ss paru &>/dev/null; then
            log_info "Paru disponible en repositorios oficiales"
            aur_helper="paru"
        fi
    fi
    
    echo "$aur_enabled:$aur_helper"
}

# Función para instalar helper AUR automáticamente
install_aur_helper() {
    local preferred_helper="${1:-paru}"
    
    log_info "Instalando helper AUR: $preferred_helper"
    
    case "$preferred_helper" in
        "paru")
            install_paru
            ;;
        "yay")
            install_yay
            ;;
        *)
            log_error "Helper AUR no soportado: $preferred_helper"
            return 1
            ;;
    esac
}

# Función para instalar paru
install_paru() {
    log_info "Instalando paru..."
    
    # Verificar si ya está instalado
    if command -v paru &>/dev/null; then
        log_info "Paru ya está instalado"
        return 0
    fi
    
    # Intentar instalar desde repos oficiales
    if pacman -Ss paru &>/dev/null; then
        log_info "Instalando paru desde repositorios oficiales"
        sudo pacman -S --needed --noconfirm paru
        return $?
    fi
    
    # Instalación manual desde AUR
    log_info "Instalando paru manualmente desde AUR"
    
    local temp_dir=$(mktemp -d)
    cd "$temp_dir"
    
    # Clonar paru
    git clone https://aur.archlinux.org/paru.git
    cd paru
    
    # Instalar dependencias
    makepkg --syncdeps --needed --noconfirm
    
    # Instalar paru
    makepkg --install --needed --noconfirm
    
    # Limpiar
    cd /
    rm -rf "$temp_dir"
    
    log_info "Paru instalado exitosamente"
}

# Función para instalar yay
install_yay() {
    log_info "Instalando yay..."
    
    # Verificar si ya está instalado
    if command -v yay &>/dev/null; then
        log_info "Yay ya está instalado"
        return 0
    fi
    
    # Instalación manual desde AUR
    log_info "Instalando yay manualmente desde AUR"
    
    local temp_dir=$(mktemp -d)
    cd "$temp_dir"
    
    # Clonar yay
    git clone https://aur.archlinux.org/yay.git
    cd yay
    
    # Instalar dependencias
    makepkg --syncdeps --needed --noconfirm
    
    # Instalar yay
    makepkg --install --needed --noconfirm
    
    # Limpiar
    cd /
    rm -rf "$temp_dir"
    
    log_info "Yay instalado exitosamente"
}

# Función para verificar dependencias con cache
check_package_with_cache() {
    local package="$1"
    
    # Verificar cache primero
    if [[ -n "${PACKAGE_CACHE[$package]}" ]]; then
        echo "${PACKAGE_CACHE[$package]}"
        return 0
    fi
    
    # Verificar si está instalado
    local package_status="MISSING"
    if pacman -Q "$package" &>/dev/null; then
        package_status="INSTALLED"
    fi
    
    # Guardar en cache
    PACKAGE_CACHE["$package"]="$package_status"
    
    echo "$package_status"
}

# Función para resolver conflictos de paquetes
resolve_package_conflicts() {
    local packages=("$@")
    local conflicts=()
    
    log_info "Verificando conflictos de paquetes..."
    
    for package in "${packages[@]}"; do
        # Verificar conflictos con pacman
        local conflict_info=$(pacman -Si "$package" 2>/dev/null | grep "Conflicts With" | cut -d: -f2- | tr -d ' ')
        
        if [[ -n "$conflict_info" ]]; then
            IFS=',' read -ra conflict_packages <<< "$conflict_info"
            
            for conflict_pkg in "${conflict_packages[@]}"; do
                if pacman -Q "$conflict_pkg" &>/dev/null; then
                    conflicts+=("$package:$conflict_pkg")
                    log_warn "Conflicto detectado: $package <-> $conflict_pkg"
                fi
            done
        fi
    done
    
    # Resolver conflictos automáticamente
    for conflict in "${conflicts[@]}"; do
        local new_pkg=$(echo "$conflict" | cut -d: -f1)
        local old_pkg=$(echo "$conflict" | cut -d: -f2)
        
        log_info "Resolviendo conflicto: reemplazando $old_pkg con $new_pkg"
        
        # Desinstalar paquete conflictivo
        sudo pacman -R --noconfirm "$old_pkg" 2>/dev/null || true
        
        # Registrar resolución
        CONFLICT_RESOLUTIONS["$old_pkg"]="$new_pkg"
    done
    
    echo "${conflicts[*]}"
}

# Función para instalar paquetes con resolución de conflictos
install_packages_smart() {
    local packages=("$@")
    local total=${#packages[@]}
    
    log_info "Instalando $total paquetes con resolución inteligente..."
    
    # Mostrar progress bar
    show_package_install_progress "${packages[@]}"
    
    # Resolver conflictos antes de instalar
    resolve_package_conflicts "${packages[@]}"
    
    # Determinar helper AUR
    local aur_info=$(check_aur_repos)
    local aur_enabled=$(echo "$aur_info" | cut -d: -f1)
    local aur_helper=$(echo "$aur_info" | cut -d: -f2)
    
    # Instalar paquetes
    for i in "${!packages[@]}"; do
        local package="${packages[$i]}"
        local current=$((i + 1))
        
        log_info "Instalando paquete $current/$total: $package"
        
        # Verificar si es un paquete AUR
        local is_aur=false
        if ! pacman -Ss "$package" &>/dev/null; then
            is_aur=true
        fi
        
        # Instalar según el tipo
        if [[ "$is_aur" == "true" ]]; then
            if [[ -n "$aur_helper" ]]; then
                log_info "Instalando paquete AUR: $package con $aur_helper"
                "$aur_helper" -S --needed --noconfirm "$package"
            else
                log_error "No se puede instalar paquete AUR $package: no hay helper disponible"
                return 1
            fi
        else
            log_info "Instalando paquete oficial: $package"
            sudo pacman -S --needed --noconfirm "$package"
        fi
        
        # Verificar instalación
        if ! pacman -Q "$package" &>/dev/null; then
            log_error "Error al instalar $package"
            return 1
        fi
    done
    
    log_info "Instalación de paquetes completada"
}

# Función para gestionar cache de paquetes
manage_package_cache() {
    local action="${1:-status}"
    
    case "$action" in
        "status")
            show_cache_status
            ;;
        "clean")
            clean_package_cache
            ;;
        "update")
            update_package_cache
            ;;
        "optimize")
            optimize_package_cache
            ;;
        *)
            log_error "Acción de cache desconocida: $action"
            return 1
            ;;
    esac
}

# Función para mostrar estado del cache
show_cache_status() {
    echo -e "\n${CYAN}=== Estado del Cache de Paquetes ===${RESET}"
    
    # Cache de pacman
    if [[ -d "$PACMAN_CACHE_DIR" ]]; then
        local pacman_size=$(du -sh "$PACMAN_CACHE_DIR" 2>/dev/null | cut -f1)
        echo -e "${BLUE}Cache de Pacman:${RESET} $pacman_size"
    else
        echo -e "${BLUE}Cache de Pacman:${RESET} No configurado"
    fi
    
    # Cache de AUR
    if [[ -d "$AUR_CACHE_DIR" ]]; then
        local aur_size=$(du -sh "$AUR_CACHE_DIR" 2>/dev/null | cut -f1)
        echo -e "${BLUE}Cache de AUR:${RESET} $aur_size"
    else
        echo -e "${BLUE}Cache de AUR:${RESET} No configurado"
    fi
    
    # Cache en memoria
    local memory_cache_count=${#PACKAGE_CACHE[@]}
    echo -e "${BLUE}Cache en memoria:${RESET} $memory_cache_count paquetes"
    
    echo ""
}

# Función para limpiar cache
clean_package_cache() {
    log_info "Limpiando cache de paquetes..."
    
    # Limpiar cache de pacman
    if [[ -d "$PACMAN_CACHE_DIR" ]]; then
        log_info "Limpiando cache de pacman..."
        sudo pacman -Sc --noconfirm
    fi
    
    # Limpiar cache de AUR
    if [[ -d "$AUR_CACHE_DIR" ]]; then
        log_info "Limpiando cache de AUR..."
        rm -rf "$AUR_CACHE_DIR"/*
    fi
    
    # Limpiar cache en memoria
    PACKAGE_CACHE=()
    
    log_info "Cache limpiado"
}

# Función para actualizar cache
update_package_cache() {
    log_info "Actualizando cache de paquetes..."
    
    # Actualizar base de datos de pacman
    sudo pacman -Sy
    
    # Actualizar cache de AUR helpers
    local aur_info=$(check_aur_repos)
    local aur_helper=$(echo "$aur_info" | cut -d: -f2)
    
    if [[ -n "$aur_helper" ]]; then
        log_info "Actualizando cache de $aur_helper..."
        "$aur_helper" -Syu --noconfirm
    fi
    
    log_info "Cache actualizado"
}

# Función para optimizar cache
optimize_package_cache() {
    log_info "Optimizando cache de paquetes..."
    
    # Optimizar base de datos de pacman
    sudo pacman -Sc --noconfirm
    
    # Limpiar paquetes huérfanos
    sudo pacman -Rns $(pacman -Qtdq) --noconfirm 2>/dev/null || true
    
    # Optimizar base de datos
    sudo pacman-optimize
    
    log_info "Cache optimizado"
}

# Función para verificar dependencias del sistema
check_system_dependencies() {
    log_info "Verificando dependencias del sistema..."
    
    local missing_deps=()
    local system_deps=(
        "pacman"
        "sudo"
        "bash"
        "grep"
        "sed"
        "awk"
        "git"
        "base-devel"
    )
    
    for dep in "${system_deps[@]}"; do
        local status=$(check_package_with_cache "$dep")
        
        if [[ "$status" == "MISSING" ]]; then
            missing_deps+=("$dep")
            log_warn "Dependencia faltante: $dep"
        else
            log_debug "Dependencia OK: $dep"
        fi
    done
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        log_info "Instalando dependencias del sistema faltantes..."
        install_packages_smart "${missing_deps[@]}"
    else
        log_info "Todas las dependencias del sistema están instaladas"
    fi
}

# Función para verificar dependencias de desarrollo
check_development_dependencies() {
    log_info "Verificando dependencias de desarrollo..."
    
    local dev_deps=(
        "base-devel"
        "git"
        "cmake"
        "ninja"
        "meson"
        "pkgconf"
    )
    
    local missing_dev_deps=()
    
    for dep in "${dev_deps[@]}"; do
        local status=$(check_package_with_cache "$dep")
        
        if [[ "$status" == "MISSING" ]]; then
            missing_dev_deps+=("$dep")
        fi
    done
    
    if [[ ${#missing_dev_deps[@]} -gt 0 ]]; then
        log_info "Instalando dependencias de desarrollo..."
        install_packages_smart "${missing_dev_deps[@]}"
    else
        log_info "Todas las dependencias de desarrollo están instaladas"
    fi
}

# Función para generar reporte de dependencias
generate_dependency_report() {
    local report_file="${1:-/tmp/hyprdream_deps_report.txt}"
    
    log_info "Generando reporte de dependencias..."
    
    {
        echo "=== Reporte de Dependencias hyprdream ==="
        echo "Fecha: $(date)"
        echo "Sistema: $(uname -a)"
        echo ""
        
        echo "--- Estado de AUR ---"
        local aur_info=$(check_aur_repos)
        local aur_enabled=$(echo "$aur_info" | cut -d: -f1)
        local aur_helper=$(echo "$aur_info" | cut -d: -f2)
        echo "AUR habilitado: $aur_enabled"
        echo "Helper AUR: ${aur_helper:-ninguno}"
        echo ""
        
        echo "--- Cache de Paquetes ---"
        show_cache_status
        echo ""
        
        echo "--- Conflictos Resueltos ---"
        for old_pkg in "${!CONFLICT_RESOLUTIONS[@]}"; do
            local new_pkg="${CONFLICT_RESOLUTIONS[$old_pkg]}"
            echo "$old_pkg -> $new_pkg"
        done
        echo ""
        
        echo "--- Paquetes en Cache ---"
        for pkg in "${!PACKAGE_CACHE[@]}"; do
            local status="${PACKAGE_CACHE[$pkg]}"
            echo "$pkg: $status"
        done
        
    } > "$report_file"
    
    log_info "Reporte generado: $report_file"
}

# Función para inicializar gestor de dependencias
init_dependency_manager() {
    log_info "Inicializando gestor de dependencias..."
    
    # Crear directorios de cache con permisos correctos
    if [[ ! -d "$CACHE_DIR" ]]; then
        log_info "Creando directorio de cache: $CACHE_DIR"
        if sudo mkdir -p "$CACHE_DIR" 2>/dev/null; then
            sudo chown "$USER:$USER" "$CACHE_DIR"
            sudo chmod 755 "$CACHE_DIR"
            log_info "Directorio de cache creado con permisos correctos"
        else
            log_warn "No se pudo crear directorio de cache del sistema, usando directorio temporal"
            CACHE_DIR="/tmp/hyprdream_cache"
            mkdir -p "$CACHE_DIR"
        fi
    fi
    mkdir -p "$AUR_CACHE_DIR"
    mkdir -p "$PACMAN_CACHE_DIR"
    
    # Verificar dependencias del sistema
    check_system_dependencies
    
    # Verificar y configurar AUR
    local aur_info=$(check_aur_repos)
    local aur_enabled=$(echo "$aur_info" | cut -d: -f1)
    local aur_helper=$(echo "$aur_info" | cut -d: -f2)
    
    if [[ "$aur_enabled" == "false" && -z "$aur_helper" ]]; then
        log_warn "No se detectó soporte AUR, instalando paru..."
        install_aur_helper "paru"
    fi
    
    log_info "Gestor de dependencias inicializado"
}

# Ejecutar si se llama directamente
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    init_logger
    
    case "${1:-help}" in
        "init")
            init_dependency_manager
            ;;
        "check")
            check_aur_repos
            ;;
        "install-helper")
            install_aur_helper "${2:-paru}"
            ;;
        "install")
            shift
            install_packages_smart "$@"
            ;;
        "cache")
            manage_package_cache "${2:-status}"
            ;;
        "report")
            generate_dependency_report "${2:-}"
            ;;
        "test")
            # Test del gestor de dependencias
            echo -e "${CYAN}=== Test del Gestor de Dependencias ===${RESET}"
            
            init_dependency_manager
            
            # Test de instalación de paquetes
            install_packages_smart "htop" "neofetch"
            
            # Test de cache
            manage_package_cache "status"
            
            # Test de reporte
            generate_dependency_report
            ;;
        *)
            echo "Uso: $0 [init|check|install-helper|install|cache|report|test]"
            echo ""
            echo "Comandos:"
            echo "  init          - Inicializar gestor de dependencias"
            echo "  check         - Verificar repos AUR"
            echo "  install-helper - Instalar helper AUR"
            echo "  install       - Instalar paquetes con resolución de conflictos"
            echo "  cache         - Gestionar cache de paquetes"
            echo "  report        - Generar reporte de dependencias"
            echo "  test          - Probar gestor de dependencias"
            ;;
    esac
fi 