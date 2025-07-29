#!/usr/bin/env bash
# Script de instalación del sistema multimedia para Hyprland Dream
# Instala dependencias, configura servicios y establece hotkeys

set -euo pipefail

# --- CONFIGURACIÓN ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
CACHE_DIR="$HOME/.cache/hyprland-dream/multimedia-install"
LOG_FILE="$CACHE_DIR/install.log"

# Crear directorio de caché
mkdir -p "$CACHE_DIR"

# --- FUNCIONES ---

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

die() {
    log "ERROR: $1"
    echo "ERROR: $1" >&2
    exit 1
}

print_header() {
    echo -e "\n${BLUE}================================${NC}"
    echo -e "${BLUE}  Instalación Sistema Multimedia  ${NC}"
    echo -e "${BLUE}================================${NC}\n"
}

print_step() {
    echo -e "${YELLOW}[$1]${NC} $2"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# --- VALIDACIONES INICIALES ---

check_arch_linux() {
    if [[ ! -f /etc/arch-release ]]; then
        die "Este script está diseñado para Arch Linux"
    fi
}

check_user() {
    if [[ $EUID -eq 0 ]]; then
        die "No ejecutar como root. Usar un usuario normal."
    fi
}

# --- INSTALACIÓN DE DEPENDENCIAS ---

install_dependencies() {
    print_step "1" "Instalando dependencias..."
    
    # Dependencias principales
    local main_deps=(
        "playerctl"
        "pamixer"
        "pulseaudio-alsa"
        "pulseaudio-bluetooth"
        "bluez"
        "bluez-utils"
    )
    
    # Dependencias opcionales
    local optional_deps=(
        "rofi"
        "jq"
        "wget"
        "mako"
        "dunst"
    )
    
    # Instalar dependencias principales
    for dep in "${main_deps[@]}"; do
        if ! pacman -Q "$dep" >/dev/null 2>&1; then
            log "Instalando $dep..."
            sudo pacman -S --noconfirm "$dep"
            print_success "Instalado: $dep"
        else
            print_success "Ya instalado: $dep"
        fi
    done
    
    # Instalar dependencias opcionales
    for dep in "${optional_deps[@]}"; do
        if ! pacman -Q "$dep" >/dev/null 2>&1; then
            log "Instalando dependencia opcional: $dep..."
            sudo pacman -S --noconfirm "$dep"
            print_success "Instalado: $dep"
        else
            print_success "Ya instalado: $dep"
        fi
    done
    
    print_success "Todas las dependencias instaladas"
}

# --- CONFIGURACIÓN DE DIRECTORIOS ---

setup_directories() {
    print_step "2" "Configurando directorios..."
    
    local dirs=(
        "$HOME/.config/hyprland-dream/media"
        "$HOME/.config/hyprland-dream/audio"
        "$HOME/.config/hyprland-dream/headphones"
        "$HOME/.cache/hyprland-dream/media"
        "$HOME/.cache/hyprland-dream/audio"
        "$HOME/.cache/hyprland-dream/headphones"
        "$HOME/.cache/hyprland-dream/media-daemon"
        "$HOME/.cache/hyprland-dream/hotkeys"
        "$HOME/.cache/hyprland-dream/waybar-multimedia"
    )
    
    for dir in "${dirs[@]}"; do
        if [[ ! -d "$dir" ]]; then
            mkdir -p "$dir"
            print_success "Creado: $dir"
        else
            print_success "Ya existe: $dir"
        fi
    done
}

# --- CONFIGURACIÓN DE SCRIPTS ---

setup_scripts() {
    print_step "3" "Configurando scripts..."
    
    # Hacer ejecutables todos los scripts
    chmod +x "$SCRIPT_DIR"/*.sh
    chmod +x "$PROJECT_ROOT/modules/waybar/config/scripts/multimedia-control.sh"
    
    print_success "Scripts configurados"
}

# --- CONFIGURACIÓN DE SERVICIOS SYSTEMD ---

setup_systemd_services() {
    print_step "4" "Configurando servicios systemd..."
    
    local services=(
        "media-daemon.service"
        "auto-pause-headphones.service"
    )
    
    for service in "${services[@]}"; do
        local service_file="$PROJECT_ROOT/modules/power-management/systemd/$service"
        local user_service_dir="$HOME/.config/systemd/user"
        
        # Crear directorio si no existe
        mkdir -p "$user_service_dir"
        
        # Copiar servicio
        cp "$service_file" "$user_service_dir/"
        
        # Recargar systemd
        systemctl --user daemon-reload
        
        # Habilitar servicio
        systemctl --user enable "$service"
        
        print_success "Servicio configurado: $service"
    done
}

# --- CONFIGURACIÓN DE HOTKEYS ---

setup_hotkeys() {
    print_step "5" "Configurando hotkeys..."
    
    local hyprland_config="$HOME/.config/hyprland/hyprland.conf"
    local hotkeys_config="$PROJECT_ROOT/scripts/media/hotkeys.conf"
    
    # Crear archivo de configuración de hotkeys
    cat > "$hotkeys_config" << 'EOF'
# Hotkeys multimedia para Hyprland Dream
# Agregar estas líneas a ~/.config/hyprland/hyprland.conf

# Control multimedia
bind = , XF86AudioPlay, exec, ~/Documentos/hyprland-dream/scripts/media/multimedia-hotkeys.sh play-pause
bind = , XF86AudioNext, exec, ~/Documentos/hyprland-dream/scripts/media/multimedia-hotkeys.sh next
bind = , XF86AudioPrev, exec, ~/Documentos/hyprland-dream/scripts/media/multimedia-hotkeys.sh previous
bind = , XF86AudioStop, exec, ~/Documentos/hyprland-dream/scripts/media/multimedia-hotkeys.sh stop

# Control de volumen
bind = , XF86AudioRaiseVolume, exec, ~/Documentos/hyprland-dream/scripts/media/multimedia-hotkeys.sh volume-up
bind = , XF86AudioLowerVolume, exec, ~/Documentos/hyprland-dream/scripts/media/multimedia-hotkeys.sh volume-down
bind = , XF86AudioMute, exec, ~/Documentos/hyprland-dream/scripts/media/multimedia-hotkeys.sh volume-mute

# Gestión de dispositivos
bind = $mainMod, A, exec, ~/Documentos/hyprland-dream/scripts/media/multimedia-hotkeys.sh device-switch
bind = $mainMod, P, exec, ~/Documentos/hyprland-dream/scripts/media/multimedia-hotkeys.sh player-switch

# Hotkeys personalizadas
bind = $mainMod, M, exec, ~/Documentos/hyprland-dream/scripts/media/media-control.sh info
bind = $mainMod SHIFT, M, exec, ~/Documentos/hyprland-dream/scripts/media/media-daemon.sh status
bind = $mainMod CTRL, M, exec, ~/Documentos/hyprland-dream/scripts/media/volume-osd.sh set 50
EOF
    
    print_success "Archivo de hotkeys creado: $hotkeys_config"
    echo -e "${YELLOW}Nota:${NC} Revisa el archivo $hotkeys_config y agrega las líneas a tu configuración de Hyprland"
}

# --- CONFIGURACIÓN DE WAYBAR ---

setup_waybar() {
    print_step "6" "Configurando Waybar..."
    
    local waybar_config="$HOME/.config/waybar/config.json"
    local waybar_style="$HOME/.config/waybar/style.css"
    
    # Verificar si existe configuración de Waybar
    if [[ ! -f "$waybar_config" ]]; then
        print_error "Configuración de Waybar no encontrada en $waybar_config"
        echo -e "${YELLOW}Sugerencia:${NC} Instala y configura Waybar primero"
        return 0
    fi
    
    # Agregar módulos multimedia si no están presentes
    if ! grep -q "mpris" "$waybar_config"; then
        print_success "Agregando módulos multimedia a Waybar"
        echo -e "${YELLOW}Nota:${NC} Agrega 'mpris' y 'pulseaudio' a tu configuración de Waybar"
    else
        print_success "Módulos multimedia ya configurados en Waybar"
    fi
}

# --- CONFIGURACIÓN DE NOTIFICACIONES ---

setup_notifications() {
    print_step "7" "Configurando notificaciones..."
    
    # Verificar servidor de notificaciones
    if command -v mako >/dev/null 2>&1; then
        local mako_config="$HOME/.config/mako/config"
        if [[ ! -f "$mako_config" ]]; then
            mkdir -p "$(dirname "$mako_config")"
            cat > "$mako_config" << 'EOF'
# Configuración de Mako para Hyprland Dream
default-timeout=5000
group-by=app-name
format=<b>%s</b>\n%b
EOF
            print_success "Configuración de Mako creada"
        else
            print_success "Configuración de Mako ya existe"
        fi
    elif command -v dunst >/dev/null 2>&1; then
        print_success "Dunst detectado como servidor de notificaciones"
    else
        print_error "No se encontró servidor de notificaciones"
        echo -e "${YELLOW}Sugerencia:${NC} Instala mako o dunst"
    fi
}

# --- CONFIGURACIÓN DE PULSEAUDIO ---

setup_pulseaudio() {
    print_step "8" "Configurando PulseAudio..."
    
    # Verificar si PulseAudio está ejecutándose
    if ! pulseaudio --check 2>/dev/null; then
        print_success "Iniciando PulseAudio..."
        pulseaudio --start
    else
        print_success "PulseAudio ya está ejecutándose"
    fi
    
    # Configurar módulo Bluetooth si está disponible
    if command -v bluetoothctl >/dev/null 2>&1; then
        pactl load-module module-bluetooth-discover 2>/dev/null || true
        print_success "Módulo Bluetooth configurado"
    fi
}

# --- PRUEBAS DEL SISTEMA ---

test_system() {
    print_step "9" "Probando sistema multimedia..."
    
    local tests=(
        "playerctl --version"
        "pamixer --version"
        "pactl info"
        "notify-send 'Test' 'Sistema multimedia funcionando'"
    )
    
    for test in "${tests[@]}"; do
        if eval "$test" >/dev/null 2>&1; then
            print_success "Prueba exitosa: $test"
        else
            print_error "Prueba fallida: $test"
        fi
    done
}

# --- INICIAR SERVICIOS ---

start_services() {
    print_step "10" "Iniciando servicios..."
    
    # Iniciar servicios systemd
    systemctl --user start media-daemon.service 2>/dev/null || true
    systemctl --user start auto-pause-headphones.service 2>/dev/null || true
    
    print_success "Servicios iniciados"
}

# --- MOSTRAR INFORMACIÓN FINAL ---

show_final_info() {
    echo -e "\n${GREEN}================================${NC}"
    echo -e "${GREEN}  Instalación Completada        ${NC}"
    echo -e "${GREEN}================================${NC}\n"
    
    echo -e "${BLUE}Próximos pasos:${NC}"
    echo "1. Revisa el archivo de hotkeys: $PROJECT_ROOT/scripts/media/hotkeys.conf"
    echo "2. Agrega las hotkeys a tu configuración de Hyprland"
    echo "3. Configura los módulos multimedia en Waybar"
    echo "4. Prueba los comandos multimedia:"
    echo "   - ~/Documentos/hyprland-dream/scripts/media/media-control.sh info"
    echo "   - ~/Documentos/hyprland-dream/scripts/media/audio-device-switcher.sh list"
    echo "   - ~/Documentos/hyprland-dream/scripts/media/volume-osd.sh get"
    
    echo -e "\n${BLUE}Documentación:${NC}"
    echo "Lee $PROJECT_ROOT/scripts/media/README.md para más información"
    
    echo -e "\n${BLUE}Servicios activos:${NC}"
    systemctl --user list-units --type=service | grep -E "(media-daemon|auto-pause)" || echo "No hay servicios multimedia activos"
    
    echo -e "\n${GREEN}¡Sistema multimedia listo! 🎵${NC}"
}

# --- FUNCIÓN PRINCIPAL ---

main() {
    print_header
    
    # Validaciones
    check_arch_linux
    check_user
    
    # Instalación
    install_dependencies
    setup_directories
    setup_scripts
    setup_systemd_services
    setup_hotkeys
    setup_waybar
    setup_notifications
    setup_pulseaudio
    test_system
    start_services
    
    # Información final
    show_final_info
}

# --- EJECUCIÓN ---

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi 