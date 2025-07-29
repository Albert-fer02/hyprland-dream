#!/usr/bin/env bash
# Script de gestión de energía para Hyprland con swayidle

# Dependencias: swayidle, swaylock, systemd

set -euo pipefail

# --- CONFIGURACIÓN ---
LOCK_CMD="swaylock -c ~/.config/swaylock/config" # Comando para bloquear la pantalla

# Tiempos en segundos
INACTIVITY_LOCK=300   # Bloquear después de 5 minutos de inactividad
INACTIVITY_SLEEP=600  # Suspender después de 10 minutos de inactividad

# --- FUNCIONES ---

die() {
    echo "ERROR: $1" >&2
    exit 1
}

# --- VALIDACIONES ---

command -v swayidle >/dev/null 2>&1 || die "swayidle no está instalado. Por favor, instálalo."
command -v swaylock >/dev/null 2>&1 || die "swaylock no está instalado. Por favor, instálalo."

# --- LÓGICA PRINCIPAL ---

# Limpia cualquier instancia anterior de swayidle
pkill -f "swayidle"

# Inicia swayidle
swayidle \
    -w \
    timeout "$INACTIVITY_LOCK" "$LOCK_CMD" \
    timeout "$INACTIVITY_SLEEP" "$LOCK_CMD && systemctl suspend" \
    before-sleep "$LOCK_CMD"

# Manejo de cierre de tapa (solo para laptops)
# Esto se configurará en hyprland.conf para ejecutar un script.
# Aquí solo se define la acción de bloqueo.

# Puedes añadir scripts pre/post suspend aquí si es necesario.
# Por ejemplo, para desconectar dispositivos Bluetooth o guardar estado.
# handle_suspend_pre() {
#     echo "Ejecutando acciones antes de suspender..."
# }
# handle_suspend_post() {
#     echo "Ejecutando acciones después de reanudar..."
# }

# swayidle \
#     ... (tus timeouts existentes) \
#     before-sleep "handle_suspend_pre" \
#     after-resume "handle_suspend_post"

# Mantener el script en ejecución para que swayidle siga funcionando
wait
