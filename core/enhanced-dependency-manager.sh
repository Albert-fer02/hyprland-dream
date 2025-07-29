#!/usr/bin/env bash
# Gestor de dependencias mejorado para hyprland-dream
# Incluye resolución automática de conflictos, instalación paralela y cache inteligente

source "$(dirname "$0")/colors.sh"
source "$(dirname "$0")/logger.sh"

# Configuración avanzada
DEPENDENCY_CACHE_DIR="${DEPENDENCY_CACHE_DIR:-/var/cache/hyprdream/deps}"
PARALLEL_INSTALL="${PARALLEL_INSTALL:-true}"
MAX_PARALLEL_JOBS="${MAX_PARALLEL_JOBS:-4}"
CONFLICT_RESOLUTION="${CONFLICT_RESOLUTION:-true}"
AUTO_FIX_BROKEN="${AUTO_FIX_BROKEN:-true}"

# Variables globales
declare -A PACKAGE_STATUS=()
declare -A PACKAGE_CONFLICTS=()
declare -A RESOLVED_CONFLICTS=()
declare -A INSTALLATION_QUEUE=()

# Función para inicializar el gestor mejorado
init_enhanced_dependency_manager() {
    log_info "Inicializando gestor de dependencias mejorado..."
    
    # Crear directorio de cache
    mkdir -p "$DEPENDENCY_CACHE_DIR"
    
    # Verificar herramientas de paralelización
    if [[ "$PARALLEL_INSTALL" == "true" ]] && ! command -v parallel &>/dev/null; then
        log_warn "GNU parallel no encontrado, instalando..."
        install_package "parallel"
    fi
    
    # Verificar herramientas de resolución de conflictos
    if [[ "$CONFLICT_RESOLUTION" == "true" ]]; then
        check_conflict_resolution_tools
    fi
    
    log_info "Gestor de dependencias mejorado inicializado"
}

# Función para verificar herramientas de resolución de conflictos
check_conflict_resolution_tools() {
    local tools=("pacman" "pactree" "expac")
    
    for tool in "${tools[@]}"; do
        if ! command -v "$tool" &>/dev/null; then
            log_warn "Herramienta de resolución de conflictos faltante: $tool"
        fi
    done
}

# Función para analizar dependencias con resolución de conflictos
analyze_dependencies_with_conflicts() {
    local packages=("$@")
    local total=${#packages[@]}
    
    log_info "Analizando $total paquetes con resolución de conflictos..."
    
    # Crear array de análisis
    local analysis_results=()
    
    for package in "${packages[@]}"; do
        local analysis=$(analyze_single_package "$package")
        analysis_results+=("$analysis")
    done
    
    # Procesar conflictos
    if [[ "$CONFLICT_RESOLUTION" == "true" ]]; then
        resolve_package_conflicts "${analysis_results[@]}"
    fi
    
    # Generar plan de instalación optimizado
    generate_optimized_installation_plan "${analysis_results[@]}"
}

# Función para analizar un paquete individual
analyze_single_package() {
    local package="$1"
    local analysis=""
    
    # Verificar si está instalado
    if pacman -Q "$package" &>/dev/null; then
        analysis="INSTALLED:$package"
    else
        # Verificar conflictos
        local conflicts=$(check_package_conflicts "$package")
        if [[ -n "$conflicts" ]]; then
            analysis="CONFLICT:$package:$conflicts"
        else
            analysis="READY:$package"
        fi
    fi
    
    echo "$analysis"
}

# Función para verificar conflictos de un paquete
check_package_conflicts() {
    local package="$1"
    local conflicts=""
    
    # Verificar conflictos usando pacman
    if command -v pacman &>/dev/null; then
        local conflict_info=$(pacman -Si "$package" 2>/dev/null | grep "Conflicts With" | cut -d: -f2- | tr -d ' ')
        
        if [[ -n "$conflict_info" ]]; then
            IFS=',' read -ra conflict_packages <<< "$conflict_info"
            
            for conflict_pkg in "${conflict_packages[@]}"; do
                if pacman -Q "$conflict_pkg" &>/dev/null; then
                    conflicts="$conflicts,$conflict_pkg"
                fi
            done
        fi
    fi
    
    echo "${conflicts#,}"
}

# Función para resolver conflictos automáticamente
resolve_package_conflicts() {
    local analysis_results=("$@")
    local resolved_count=0
    
    log_info "Resolviendo conflictos de paquetes..."
    
    for analysis in "${analysis_results[@]}"; do
        if [[ "$analysis" == CONFLICT:* ]]; then
            local package=$(echo "$analysis" | cut -d: -f2)
            local conflicts=$(echo "$analysis" | cut -d: -f3)
            
            log_info "Resolviendo conflictos para $package: $conflicts"
            
            # Resolver conflictos automáticamente
            IFS=',' read -ra conflict_array <<< "$conflicts"
            for conflict in "${conflict_array[@]}"; do
                if [[ -n "$conflict" ]]; then
                    resolve_single_conflict "$package" "$conflict"
                    resolved_count=$((resolved_count + 1))
                fi
            done
        fi
    done
    
    log_info "Resueltos $resolved_count conflictos de paquetes"
}

# Función para resolver un conflicto individual
resolve_single_conflict() {
    local new_package="$1"
    local old_package="$2"
    
    log_info "Resolviendo conflicto: $old_package -> $new_package"
    
    # Verificar si el paquete antiguo es crítico
    if is_critical_package "$old_package"; then
        log_warn "Paquete crítico detectado: $old_package"
        log_warn "Conflicto no resuelto automáticamente"
        return 1
    fi
    
    # Desinstalar paquete conflictivo
    if pacman -Q "$old_package" &>/dev/null; then
        log_info "Desinstalando paquete conflictivo: $old_package"
        sudo pacman -R --noconfirm "$old_package" 2>/dev/null || true
        
        # Registrar resolución
        RESOLVED_CONFLICTS["$old_package"]="$new_package"
    fi
}

# Función para verificar si un paquete es crítico
is_critical_package() {
    local package="$1"
    
    # Lista de paquetes críticos que no deben ser removidos automáticamente
    local critical_packages=(
        "linux" "systemd" "bash" "pacman" "sudo" "base" "base-devel"
        "glibc" "gcc" "binutils" "coreutils" "util-linux"
    )
    
    for critical in "${critical_packages[@]}"; do
        if [[ "$package" == "$critical" ]]; then
            return 0  # Es crítico
        fi
    done
    
    return 1  # No es crítico
}

# Función para generar plan de instalación optimizado
generate_optimized_installation_plan() {
    local analysis_results=("$@")
    local ready_packages=()
    local total_packages=0
    
    log_info "Generando plan de instalación optimizado..."
    
    # Separar paquetes listos para instalar
    for analysis in "${analysis_results[@]}"; do
        if [[ "$analysis" == READY:* ]]; then
            local package=$(echo "$analysis" | cut -d: -f2)
            ready_packages+=("$package")
            total_packages=$((total_packages + 1))
        fi
    done
    
    # Crear grupos de instalación paralela
    if [[ "$PARALLEL_INSTALL" == "true" ]] && [[ ${#ready_packages[@]} -gt 1 ]]; then
        create_parallel_installation_groups "${ready_packages[@]}"
    else
        # Instalación secuencial
        INSTALLATION_QUEUE["sequential"]="${ready_packages[*]}"
    fi
    
    log_info "Plan de instalación generado: $total_packages paquetes listos"
}

# Función para crear grupos de instalación paralela
create_parallel_installation_groups() {
    local packages=("$@")
    local group_size=$MAX_PARALLEL_JOBS
    local group_count=0
    
    for ((i=0; i<${#packages[@]}; i+=group_size)); do
        local group_packages=()
        
        for ((j=i; j<i+group_size && j<${#packages[@]}; j++)); do
            group_packages+=("${packages[$j]}")
        done
        
        INSTALLATION_QUEUE["group_$group_count"]="${group_packages[*]}"
        group_count=$((group_count + 1))
    done
    
    log_info "Creados $group_count grupos de instalación paralela"
}

# Función para instalar paquetes con optimizaciones
install_packages_optimized() {
    local packages=("$@")
    
    log_info "Instalando ${#packages[@]} paquetes con optimizaciones..."
    
    # Verificar espacio en disco antes de instalar
    check_disk_space_before_install "${packages[@]}"
    
    # Instalar en paralelo si está habilitado
    if [[ "$PARALLEL_INSTALL" == "true" ]] && [[ ${#packages[@]} -gt 1 ]]; then
        install_packages_parallel "${packages[@]}"
    else
        install_packages_sequential "${packages[@]}"
    fi
    
    # Verificar instalación
    verify_package_installation "${packages[@]}"
}

# Función para verificar espacio en disco antes de instalar
check_disk_space_before_install() {
    local packages=("$@")
    local estimated_size=0
    
    # Estimar tamaño total de paquetes
    for package in "${packages[@]}"; do
        local package_size=$(pacman -Si "$package" 2>/dev/null | grep "Installed Size" | awk '{print $4}' | sed 's/MiB//')
        if [[ -n "$package_size" ]]; then
            estimated_size=$((estimated_size + package_size))
        fi
    done
    
    # Verificar espacio disponible
    local available_space=$(df / | awk 'NR==2 {print $4}')
    available_space=$((available_space / 1024))  # Convertir a MB
    
    if [[ $available_space -lt $((estimated_size + 1000)) ]]; then
        log_error "Espacio insuficiente para instalar paquetes"
        log_error "Disponible: ${available_space}MB, Estimado: ${estimated_size}MB"
        return 1
    fi
    
    log_info "Espacio suficiente para instalación: ${available_space}MB disponible"
}

# Función para instalar paquetes en paralelo
install_packages_parallel() {
    local packages=("$@")
    
    log_info "Instalando paquetes en paralelo..."
    
    if command -v parallel &>/dev/null; then
        # Usar GNU parallel para instalación paralela
        printf '%s\n' "${packages[@]}" | parallel -j "$MAX_PARALLEL_JOBS" \
            'echo "Instalando {}..."; sudo pacman -S --needed --noconfirm {}'
    else
        # Fallback a instalación secuencial
        log_warn "GNU parallel no disponible, usando instalación secuencial"
        install_packages_sequential "${packages[@]}"
    fi
}

# Función para instalar paquetes secuencialmente
install_packages_sequential() {
    local packages=("$@")
    
    log_info "Instalando paquetes secuencialmente..."
    
    for package in "${packages[@]}"; do
        log_info "Instalando $package..."
        sudo pacman -S --needed --noconfirm "$package"
        
        # Verificar instalación exitosa
        if ! pacman -Q "$package" &>/dev/null; then
            log_error "Error al instalar $package"
            return 1
        fi
    done
}

# Función para verificar instalación de paquetes
verify_package_installation() {
    local packages=("$@")
    local failed_packages=()
    
    log_info "Verificando instalación de paquetes..."
    
    for package in "${packages[@]}"; do
        if pacman -Q "$package" &>/dev/null; then
            log_info "✓ $package instalado correctamente"
        else
            log_error "✗ $package no se instaló correctamente"
            failed_packages+=("$package")
        fi
    done
    
    if [[ ${#failed_packages[@]} -gt 0 ]]; then
        log_error "Fallaron ${#failed_packages[@]} paquetes: ${failed_packages[*]}"
        return 1
    else
        log_info "Todos los paquetes instalados correctamente"
        return 0
    fi
}

# Función para limpiar cache de dependencias
cleanup_dependency_cache() {
    log_info "Limpiando cache de dependencias..."
    
    if [[ -d "$DEPENDENCY_CACHE_DIR" ]]; then
        # Eliminar archivos de cache antiguos (más de 7 días)
        find "$DEPENDENCY_CACHE_DIR" -type f -mtime +7 -delete 2>/dev/null || true
        
        # Eliminar directorios vacíos
        find "$DEPENDENCY_CACHE_DIR" -type d -empty -delete 2>/dev/null || true
        
        log_info "Cache de dependencias limpiado"
    fi
}

# Función para generar reporte de dependencias
generate_dependency_report() {
    local report_file="${1:-/tmp/hyprdream_deps_report.txt}"
    
    log_info "Generando reporte de dependencias..."
    
    {
        echo "=== Reporte de Dependencias Mejorado ==="
        echo "Fecha: $(date)"
        echo "Sistema: $(uname -a)"
        echo ""
        
        echo "--- Configuración ---"
        echo "Instalación paralela: $PARALLEL_INSTALL"
        echo "Máximo de trabajos paralelos: $MAX_PARALLEL_JOBS"
        echo "Resolución de conflictos: $CONFLICT_RESOLUTION"
        echo "Auto-fix de paquetes rotos: $AUTO_FIX_BROKEN"
        echo ""
        
        echo "--- Conflictos Resueltos ---"
        for old_pkg in "${!RESOLVED_CONFLICTS[@]}"; do
            local new_pkg="${RESOLVED_CONFLICTS[$old_pkg]}"
            echo "$old_pkg -> $new_pkg"
        done
        echo ""
        
        echo "--- Estado de Paquetes ---"
        for pkg in "${!PACKAGE_STATUS[@]}"; do
            local status="${PACKAGE_STATUS[$pkg]}"
            echo "$pkg: $status"
        done
        
    } > "$report_file"
    
    log_info "Reporte generado: $report_file"
}

# Ejecutar si se llama directamente
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    init_logger
    
    case "${1:-help}" in
        "init")
            init_enhanced_dependency_manager
            ;;
        "analyze")
            shift
            analyze_dependencies_with_conflicts "$@"
            ;;
        "install")
            shift
            install_packages_optimized "$@"
            ;;
        "cleanup")
            cleanup_dependency_cache
            ;;
        "report")
            generate_dependency_report
            ;;
        *)
            echo "Uso: $0 [init|analyze|install|cleanup|report]"
            ;;
    esac
fi 