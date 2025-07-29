#!/usr/bin/env bash
# Script de diagnóstico completo para hyprland-dream
# Identifica todos los problemas que impiden el funcionamiento perfecto

set -e

echo "=== DIAGNÓSTICO COMPLETO DEL SISTEMA ==="
echo "Fecha: $(date)"
echo ""

# 1. Verificar espacio en disco
echo "1. VERIFICANDO ESPACIO EN DISCO:"
echo "--------------------------------"
if command -v df &>/dev/null; then
    df -h 2>/dev/null || echo "Error al verificar espacio en disco"
else
    echo "Comando 'df' no disponible"
fi
echo ""

# 2. Verificar permisos y directorios críticos
echo "2. VERIFICANDO PERMISOS Y DIRECTORIOS:"
echo "--------------------------------------"
for dir in /tmp /var/cache /home/dreamcoder08/Documentos/hyprland-dream; do
    if [[ -d "$dir" ]]; then
        echo "✓ $dir existe"
        if [[ -w "$dir" ]]; then
            echo "  ✓ Permisos de escritura OK"
        else
            echo "  ✗ Sin permisos de escritura"
        fi
    else
        echo "✗ $dir no existe"
    fi
done
echo ""

# 3. Verificar dependencias críticas
echo "3. VERIFICANDO DEPENDENCIAS CRÍTICAS:"
echo "------------------------------------"
deps=("bash" "sudo" "pacman" "git" "curl" "wget")
for dep in "${deps[@]}"; do
    if command -v "$dep" &>/dev/null; then
        echo "✓ $dep disponible"
    else
        echo "✗ $dep NO disponible"
    fi
done
echo ""

# 4. Verificar conectividad de red
echo "4. VERIFICANDO CONECTIVIDAD:"
echo "----------------------------"
if ping -c 1 8.8.8.8 &>/dev/null; then
    echo "✓ Conectividad a internet OK"
else
    echo "✗ Sin conectividad a internet"
fi
echo ""

# 5. Verificar repositorios de Arch
echo "5. VERIFICANDO REPOSITORIOS:"
echo "----------------------------"
if command -v pacman &>/dev/null; then
    if sudo pacman -Sy &>/dev/null; then
        echo "✓ Repositorios de Arch actualizados"
    else
        echo "✗ Error al actualizar repositorios"
    fi
else
    echo "✗ Pacman no disponible"
fi
echo ""

# 6. Verificar archivos del proyecto
echo "6. VERIFICANDO ARCHIVOS DEL PROYECTO:"
echo "------------------------------------"
ROOT_DIR="/home/dreamcoder08/Documentos/hyprland-dream"
critical_files=(
    "install.sh"
    "core/colors.sh"
    "core/logger.sh"
    "core/hardware-detector.sh"
    "core/progress.sh"
    "core/rollback.sh"
    "core/dependency-manager.sh"
    "lib/utils.sh"
)

for file in "${critical_files[@]}"; do
    full_path="$ROOT_DIR/$file"
    if [[ -f "$full_path" ]]; then
        if [[ -r "$full_path" ]]; then
            echo "✓ $file existe y es legible"
        else
            echo "✗ $file existe pero no es legible"
        fi
    else
        echo "✗ $file NO existe"
    fi
done
echo ""

# 7. Verificar variables de entorno
echo "7. VERIFICANDO VARIABLES DE ENTORNO:"
echo "-----------------------------------"
env_vars=("HOME" "USER" "PATH" "SHELL")
for var in "${env_vars[@]}"; do
    if [[ -n "${!var}" ]]; then
        echo "✓ $var = ${!var}"
    else
        echo "✗ $var no está definida"
    fi
done
echo ""

# 8. Verificar sistema de archivos
echo "8. VERIFICANDO SISTEMA DE ARCHIVOS:"
echo "----------------------------------"
if mount | grep -q " / " 2>/dev/null; then
    echo "✓ Sistema de archivos montado"
    mount_point=$(mount | grep " / " | awk '{print $3}')
    fs_type=$(mount | grep " / " | awk '{print $5}')
    echo "  Montaje: $mount_point"
    echo "  Tipo: $fs_type"
else
    echo "✗ No se puede verificar el sistema de archivos"
fi
echo ""

# 9. Verificar memoria disponible
echo "9. VERIFICANDO MEMORIA:"
echo "----------------------"
if [[ -f /proc/meminfo ]]; then
    total_mem=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    free_mem=$(grep MemAvailable /proc/meminfo | awk '{print $2}')
    echo "✓ Memoria total: $((total_mem/1024)) MB"
    echo "✓ Memoria disponible: $((free_mem/1024)) MB"
else
    echo "✗ No se puede verificar la memoria"
fi
echo ""

# 10. Verificar permisos de usuario
echo "10. VERIFICANDO PERMISOS DE USUARIO:"
echo "-----------------------------------"
current_user=$(whoami)
echo "Usuario actual: $current_user"
if [[ "$current_user" == "root" ]]; then
    echo "⚠️  Ejecutando como root (no recomendado)"
elif groups | grep -q sudo 2>/dev/null; then
    echo "✓ Usuario en grupo sudo"
else
    echo "✗ Usuario no está en grupo sudo"
fi
echo ""

echo "=== RESUMEN DE PROBLEMAS IDENTIFICADOS ==="
echo ""

# Detectar problemas críticos
problems=()

# Verificar espacio en disco
if ! df -h &>/dev/null; then
    problems+=("SIN ESPACIO EN DISCO - CRÍTICO")
fi

# Verificar permisos de escritura
if [[ ! -w /tmp ]]; then
    problems+=("SIN PERMISOS DE ESCRITURA EN /tmp")
fi

# Verificar conectividad
if ! ping -c 1 8.8.8.8 &>/dev/null; then
    problems+=("SIN CONECTIVIDAD A INTERNET")
fi

# Verificar archivos críticos
for file in "${critical_files[@]}"; do
    if [[ ! -f "$ROOT_DIR/$file" ]]; then
        problems+=("ARCHIVO CRÍTICO FALTANTE: $file")
    fi
done

if [[ ${#problems[@]} -eq 0 ]]; then
    echo "✅ No se detectaron problemas críticos"
else
    echo "❌ PROBLEMAS CRÍTICOS DETECTADOS:"
    for problem in "${problems[@]}"; do
        echo "  • $problem"
    done
fi

echo ""
echo "=== RECOMENDACIONES ==="
echo ""

if [[ " ${problems[@]} " =~ " SIN ESPACIO EN DISCO " ]]; then
    echo "🔥 URGENTE: Liberar espacio en disco"
    echo "   - Ejecutar: sudo pacman -Sc (limpiar cache)"
    echo "   - Ejecutar: sudo journalctl --vacuum-time=3d (limpiar logs)"
    echo "   - Eliminar archivos temporales grandes"
fi

if [[ " ${problems[@]} " =~ " SIN CONECTIVIDAD " ]]; then
    echo "🌐 Verificar conexión a internet"
    echo "   - Verificar configuración de red"
    echo "   - Verificar DNS"
fi

echo ""
echo "Diagnóstico completado." 