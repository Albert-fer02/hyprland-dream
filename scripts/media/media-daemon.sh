#!/usr/bin/env bash
# Daemon de control multimedia para Hyprland Dream
# Monitoreo en tiempo real y control automático de multimedia

set -euo pipefail

# --- CONFIGURACIÓN ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CACHE_DIR="$HOME/.cache/hyprland-dream/media-daemon"
CONFIG_DIR="$HOME/.config/hyprland-dream/media-daemon"
LOG_FILE="$CACHE_DIR/media-daemon.log"
PID_FILE="$CACHE_DIR/media-daemon.pid"
STATE_FILE="$CACHE_DIR/current-state.json"

# Crear directorios necesarios
mkdir -p "$CACHE_DIR" "$CONFIG_DIR"

# --- FUNCIONES ---

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

die() {
    log "ERROR: $1"
    echo "ERROR: $1" >&2
    exit 1
}

usage() {
    cat << EOF
Uso: $0 [COMANDO] [OPCIONES]

Comandos:
  start           Inicia el daemon de multimedia
  stop            Detiene el daemon
  restart         Reinicia el daemon
  status          Muestra estado del daemon
  monitor         Modo monitor (sin daemon)
  config          Gestiona configuración

Opciones:
  --config=FILE   Archivo de configuración personalizado
  --debug         Modo debug
  --foreground    Ejecutar en primer plano

Ejemplos:
  $0 start
  $0 status
  $0 monitor
  $0 config --show
EOF
    exit 1
}

# Verificar si el daemon está ejecutándose
is_daemon_running() {
    if [[ -f "$PID_FILE" ]]; then
        local pid=$(cat "$PID_FILE")
        if kill -0 "$pid" 2>/dev/null; then
            return 0
        else
            rm -f "$PID_FILE"
            return 1
        fi
    fi
    return 1
}

# Iniciar daemon
start_daemon() {
    if is_daemon_running; then
        echo "El daemon ya está ejecutándose (PID: $(cat "$PID_FILE"))"
        return 1
    fi
    
    if [[ "$FOREGROUND" == "true" ]]; then
        echo "Iniciando daemon en primer plano..."
        run_daemon
    else
        echo "Iniciando daemon en segundo plano..."
        nohup "$0" run-daemon >/dev/null 2>&1 &
        local pid=$!
        echo "$pid" > "$PID_FILE"
        sleep 1
        
        if is_daemon_running; then
            echo "Daemon iniciado (PID: $pid)"
            log "Daemon iniciado con PID: $pid"
        else
            echo "Error al iniciar el daemon"
            return 1
        fi
    fi
}

# Detener daemon
stop_daemon() {
    if ! is_daemon_running; then
        echo "El daemon no está ejecutándose"
        return 1
    fi
    
    local pid=$(cat "$PID_FILE")
    echo "Deteniendo daemon (PID: $pid)..."
    
    kill "$pid" 2>/dev/null || true
    sleep 2
    
    if kill -0 "$pid" 2>/dev/null; then
        echo "Forzando detención..."
        kill -9 "$pid" 2>/dev/null || true
    fi
    
    rm -f "$PID_FILE"
    echo "Daemon detenido"
    log "Daemon detenido"
}

# Ejecutar daemon principal
run_daemon() {
    log "Daemon iniciado"
    
    # Configurar trap para limpieza
    trap 'cleanup_daemon' EXIT INT TERM
    
    # Inicializar estado
    initialize_state
    
    # Bucle principal
    while true; do
        # Monitorear cambios de reproductores
        monitor_players
        
        # Monitorear cambios de dispositivos de audio
        monitor_audio_devices
        
        # Monitorear cambios de volumen
        monitor_volume
        
        # Monitorear auriculares
        monitor_headphones
        
        # Esperar antes de la siguiente verificación
        sleep 2
    done
}

# Limpiar al salir
cleanup_daemon() {
    log "Daemon detenido"
    rm -f "$PID_FILE"
    exit 0
}

# Inicializar estado
initialize_state() {
    local state=$(cat << EOF
{
    "players": {},
    "audio_devices": {},
    "volume": {},
    "headphones": "unknown",
    "last_update": "$(date -Iseconds)"
}
EOF
)
    echo "$state" > "$STATE_FILE"
    log "Estado inicializado"
}

# Monitorear reproductores multimedia
monitor_players() {
    local players=($(playerctl -l 2>/dev/null))
    local current_state=$(cat "$STATE_FILE")
    
    for player in "${players[@]}"; do
        local status=$(playerctl -p "$player" status 2>/dev/null || echo "Stopped")
        local title=$(playerctl -p "$player" metadata title 2>/dev/null || echo "")
        local artist=$(playerctl -p "$player" metadata artist 2>/dev/null || echo "")
        
        # Verificar si hay cambios
        local old_status=$(echo "$current_state" | jq -r ".players.\"$player\".status // \"unknown\"")
        if [[ "$status" != "$old_status" ]]; then
            log "Cambio de estado en $player: $old_status -> $status"
            
            # Enviar notificación si es necesario
            if [[ "$status" == "Playing" ]]; then
                notify-send "Reproducción iniciada" "$title - $artist" -u low -i "media-playback-start-symbolic"
            elif [[ "$status" == "Paused" ]]; then
                notify-send "Reproducción pausada" "$title - $artist" -u low -i "media-playback-pause-symbolic"
            fi
        fi
        
        # Actualizar estado
        current_state=$(echo "$current_state" | jq --arg player "$player" --arg status "$status" --arg title "$title" --arg artist "$artist" '
            .players[$player] = {
                "status": $status,
                "title": $title,
                "artist": $artist,
                "last_update": now
            }
        ')
    done
    
    echo "$current_state" > "$STATE_FILE"
}

# Monitorear dispositivos de audio
monitor_audio_devices() {
    local current_sink=$(pactl info | grep "Default Sink:" | awk '{print $3}')
    local current_state=$(cat "$STATE_FILE")
    local old_sink=$(echo "$current_state" | jq -r '.audio_devices.default_sink // "unknown"')
    
    if [[ "$current_sink" != "$old_sink" ]]; then
        log "Cambio de dispositivo de audio: $old_sink -> $current_sink"
        
        # Obtener descripción del dispositivo
        local description=$(pactl list sinks | awk -v sink="$current_sink" '
            $1 == "Name:" && $2 == sink { in_sink=1; next }
            /^Sink / { in_sink=0 }
            in_sink && $1 == "Description:" { print substr($0, index($0, $2)); exit }
        ')
        
        notify-send "Dispositivo de audio cambiado" "$description" -u low -i "audio-card-symbolic"
        
        # Actualizar estado
        current_state=$(echo "$current_state" | jq --arg sink "$current_sink" --arg desc "$description" '
            .audio_devices.default_sink = $sink |
            .audio_devices.description = $desc |
            .audio_devices.last_update = now
        ')
        echo "$current_state" > "$STATE_FILE"
    fi
}

# Monitorear volumen
monitor_volume() {
    local volume=$(pamixer --get-volume)
    local muted=$(pamixer --get-mute)
    local current_state=$(cat "$STATE_FILE")
    local old_volume=$(echo "$current_state" | jq -r '.volume.level // "unknown"')
    local old_muted=$(echo "$current_state" | jq -r '.volume.muted // "unknown"')
    
    if [[ "$volume" != "$old_volume" ]] || [[ "$muted" != "$old_muted" ]]; then
        log "Cambio de volumen: $old_volume%/$old_muted -> $volume%/$muted"
        
        # Actualizar estado
        current_state=$(echo "$current_state" | jq --arg volume "$volume" --arg muted "$muted" '
            .volume.level = $volume |
            .volume.muted = $muted |
            .volume.last_update = now
        ')
        echo "$current_state" > "$STATE_FILE"
    fi
}

# Monitorear auriculares
monitor_headphones() {
    local current_state=$(cat "$STATE_FILE")
    local old_state=$(echo "$current_state" | jq -r '.headphones // "unknown"')
    
    # Detectar auriculares usando el script existente
    local headphones_connected=false
    if "$SCRIPT_DIR/auto-pause-headphones.sh" check >/dev/null 2>&1; then
        headphones_connected=true
    fi
    
    local new_state="disconnected"
    if [[ "$headphones_connected" == "true" ]]; then
        new_state="connected"
    fi
    
    if [[ "$new_state" != "$old_state" ]]; then
        log "Cambio de estado de auriculares: $old_state -> $new_state"
        
        if [[ "$new_state" == "connected" ]]; then
            notify-send "Auriculares conectados" "Reproducción disponible" -u low -i "audio-headphones-symbolic"
        else
            notify-send "Auriculares desconectados" "Reproducción pausada" -u low -i "audio-headphones-symbolic"
            # Auto-pausar si hay reproducción activa
            if playerctl status 2>/dev/null | grep -q "Playing"; then
                playerctl pause
            fi
        fi
        
        # Actualizar estado
        current_state=$(echo "$current_state" | jq --arg state "$new_state" '
            .headphones = $state |
            .last_update = now
        ')
        echo "$current_state" > "$STATE_FILE"
    fi
}

# Mostrar estado del daemon
show_status() {
    if is_daemon_running; then
        local pid=$(cat "$PID_FILE")
        echo "✓ Daemon ejecutándose (PID: $pid)"
        
        if [[ -f "$STATE_FILE" ]]; then
            echo ""
            echo "Estado actual:"
            echo "=============="
            cat "$STATE_FILE" | jq '.' 2>/dev/null || cat "$STATE_FILE"
        fi
    else
        echo "✗ Daemon no está ejecutándose"
    fi
}

# Modo monitor (sin daemon)
monitor_mode() {
    echo "Modo monitor iniciado..."
    echo "Presiona Ctrl+C para detener"
    
    # Configurar trap
    trap 'echo "Monitor detenido"; exit 0' INT TERM
    
    # Inicializar estado
    initialize_state
    
    # Ejecutar monitoreo
    run_daemon
}

# Gestionar configuración
manage_config() {
    local action="${1:-}"
    
    case "$action" in
        show)
            echo "Configuración actual:"
            echo "===================="
            if [[ -f "$CONFIG_DIR/config.conf" ]]; then
                cat "$CONFIG_DIR/config.conf"
            else
                echo "No hay configuración personalizada"
            fi
            ;;
        create)
            cat > "$CONFIG_DIR/config.conf" << EOF
# Configuración del daemon de multimedia
# Generado automáticamente el $(date)

# Configuración de monitoreo
MONITOR_INTERVAL=2
ENABLE_PLAYER_MONITORING=true
ENABLE_AUDIO_MONITORING=true
ENABLE_VOLUME_MONITORING=true
ENABLE_HEADPHONE_MONITORING=true

# Configuración de notificaciones
ENABLE_NOTIFICATIONS=true
NOTIFICATION_URGENCY=low

# Configuración de logging
ENABLE_LOGGING=true
LOG_LEVEL=info

# Configuración de reproductores
MONITORED_PLAYERS=("spotify" "vlc" "mpv" "firefox" "chromium" "youtube-music")

# Configuración de auto-pausa
AUTO_PAUSE_ON_HEADPHONE_DISCONNECT=true
AUTO_RESUME_ON_HEADPHONE_CONNECT=false
EOF
            echo "Configuración creada en: $CONFIG_DIR/config.conf"
            ;;
        *)
            echo "Acciones de configuración disponibles:"
            echo "  show   - Muestra configuración actual"
            echo "  create - Crea configuración por defecto"
            ;;
    esac
}

# --- VALIDACIONES ---

command -v playerctl >/dev/null 2>&1 || die "playerctl no está instalado"
command -v pactl >/dev/null 2>&1 || die "pactl no está instalado"
command -v pamixer >/dev/null 2>&1 || die "pamixer no está instalado"
command -v notify-send >/dev/null 2>&1 || die "notify-send no está disponible"
command -v jq >/dev/null 2>&1 || die "jq no está instalado"

# --- VARIABLES GLOBALES ---
FOREGROUND=false
DEBUG=false

# --- PARSING DE ARGUMENTOS ---
while [[ $# -gt 0 ]]; do
    case $1 in
        --foreground)
            FOREGROUND=true
            shift
            ;;
        --debug)
            DEBUG=true
            shift
            ;;
        --config=*)
            CONFIG_FILE="${1#*=}"
            shift
            ;;
        -h|--help)
            usage
            ;;
        *)
            break
            ;;
    esac
done

COMMAND="${1:-}"
if [[ -z "$COMMAND" ]]; then
    usage
fi

# --- LÓGICA PRINCIPAL ---

if [[ "$DEBUG" == "true" ]]; then
    log "Comando ejecutado: $0 $*"
fi

case "$COMMAND" in
    start)
        start_daemon
        ;;
    stop)
        stop_daemon
        ;;
    restart)
        stop_daemon
        sleep 1
        start_daemon
        ;;
    status)
        show_status
        ;;
    run-daemon)
        run_daemon
        ;;
    monitor)
        monitor_mode
        ;;
    config)
        manage_config "$2"
        ;;
    *)
        usage
        ;;
esac 