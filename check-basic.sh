#!/bin/bash
echo "=== VERIFICACIÓN BÁSICA DEL SISTEMA ==="
echo "Fecha: $(date)"
echo ""

echo "1. Verificando comandos básicos:"
echo "   - whoami: $(whoami)"
echo "   - pwd: $(pwd)"
echo "   - ls: $(ls -la | head -1)"

echo ""
echo "2. Verificando espacio en disco:"
if command -v df >/dev/null 2>&1; then
    df -h 2>/dev/null || echo "Error al verificar espacio"
else
    echo "Comando df no disponible"
fi

echo ""
echo "3. Verificando directorios:"
echo "   - /tmp existe: $([ -d /tmp ] && echo "SÍ" || echo "NO")"
echo "   - /tmp escribible: $([ -w /tmp ] && echo "SÍ" || echo "NO")"
echo "   - Directorio actual escribible: $([ -w . ] && echo "SÍ" || echo "NO")"

echo ""
echo "4. Verificando archivos del proyecto:"
echo "   - install.sh: $([ -f install.sh ] && echo "EXISTE" || echo "NO EXISTE")"
echo "   - core/colors.sh: $([ -f core/colors.sh ] && echo "EXISTE" || echo "NO EXISTE")"

echo ""
echo "Verificación básica completada." 