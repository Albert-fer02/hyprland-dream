#!/usr/bin/env bash
# Script de demostración del sistema de temas Hyprland Dream

set -e

SCRIPT_DIR="$(dirname "$0")"
ROOT_DIR="$SCRIPT_DIR/../.."
source "$ROOT_DIR/lib/utils.sh"
source "$ROOT_DIR/core/logger.sh"

init_logger

show_demo_menu() {
    clear
    echo -e "\n${CYAN}╔══════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${CYAN}║                DEMO - Sistema de Temas Hyprland Dream        ║${RESET}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${RESET}"
    echo
    echo -e "${GREEN}🎨 Características del Sistema:${RESET}"
    echo -e "  • 4 temas predefinidos + constructor personalizado"
    echo -e "  • Cambio instantáneo con preservación de configuraciones"
    echo -e "  • Sincronización automática de wallpapers"
    echo -e "  • Programación día/noche automática"
    echo -e "  • Preview antes de aplicar"
    echo -e "  • Backup y restore automático"
    echo
    echo -e "${YELLOW}📋 Opciones de Demostración:${RESET}"
    echo -e "  1) Mostrar todos los temas disponibles"
    echo -e "  2) Demo rápido - Cambiar entre temas"
    echo -e "  3) Demo de preview de temas"
    echo -e "  4) Demo de sincronización de wallpapers"
    echo -e "  5) Demo de programación día/noche"
    echo -e "  6) Demo de backup y restore"
    echo -e "  7) Crear tema personalizado de ejemplo"
    echo -e "  8) Mostrar integración con componentes"
    echo -e "  0) Salir"
    echo
    echo -e "${BLUE}💡 Tip: Usa 'theme-switcher --help' para ver todos los comandos${RESET}"
    echo
}

demo_show_themes() {
    echo -e "\n${CYAN}🎨 Temas Disponibles:${RESET}"
    echo
    
    # Nord
    echo -e "${BLUE}┌─ Nord (Azules fríos)${RESET}"
    echo -e "   ├─ Colores: Azules y grises nórdicos"
    echo -e "   ├─ Estilo: Minimalismo limpio"
    echo -e "   └─ Uso: Trabajo profesional"
    echo
    
    # Dracula
    echo -e "${MAGENTA}┌─ Dracula (Morados vibrantes)${RESET}"
    echo -e "   ├─ Colores: Morados y púrpuras"
    echo -e "   ├─ Estilo: Elegancia oscura"
    echo -e "   └─ Uso: Desarrollo y creatividad"
    echo
    
    # Catppuccin
    echo -e "${GREEN}┌─ Catppuccin (Pasteles suaves)${RESET}"
    echo -e "   ├─ Colores: Pasteles cálidos"
    echo -e "   ├─ Estilo: Suave y acogedor"
    echo -e "   └─ Uso: Uso diario y confort"
    echo
    
    # Tokyo Night
    echo -e "${CYAN}┌─ Tokyo Night (Neones urbanos)${RESET}"
    echo -e "   ├─ Colores: Neones y azules"
    echo -e "   ├─ Estilo: Cyberpunk urbano"
    echo -e "   └─ Uso: Gaming y multimedia"
    echo
    
    # Custom
    echo -e "${YELLOW}┌─ Custom (Constructor personalizado)${RESET}"
    echo -e "   ├─ Colores: Definidos por el usuario"
    echo -e "   ├─ Estilo: Personalizado"
    echo -e "   └─ Uso: Personalización total"
    echo
    
    read -p "Presiona Enter para continuar..."
}

demo_quick_switch() {
    echo -e "\n${CYAN}⚡ Demo de Cambio Rápido de Temas${RESET}"
    echo -e "Cambiando entre temas cada 3 segundos..."
    echo
    
    local themes=("nord" "dracula" "catppuccin" "tokyo-night")
    local theme_names=("Nord" "Dracula" "Catppuccin" "Tokyo Night")
    
    for i in "${!themes[@]}"; do
        echo -e "${GREEN}→ Aplicando ${theme_names[$i]}...${RESET}"
        "$SCRIPT_DIR/theme-switcher.sh" apply "${themes[$i]}" --no-preview --no-wallpaper
        sleep 3
    done
    
    echo -e "\n${GREEN}✅ Demo completado. Tema actual: $(cat ~/.config/hyprdream/current-theme.conf 2>/dev/null | grep CURRENT_THEME | cut -d'=' -f2 || echo "No aplicado")${RESET}"
    read -p "Presiona Enter para continuar..."
}

demo_preview() {
    echo -e "\n${CYAN}👁️ Demo de Preview de Temas${RESET}"
    echo -e "Mostrando preview de cada tema..."
    echo
    
    local themes=("nord" "dracula" "catppuccin" "tokyo-night")
    local theme_names=("Nord" "Dracula" "Catppuccin" "Tokyo Night")
    
    for i in "${!themes[@]}"; do
        echo -e "${GREEN}→ Mostrando preview de ${theme_names[$i]}...${RESET}"
        "$SCRIPT_DIR/theme-switcher.sh" preview "${themes[$i]}"
        read -p "Presiona Enter para continuar al siguiente tema..."
    done
    
    echo -e "\n${GREEN}✅ Demo de preview completado${RESET}"
}

demo_wallpaper_sync() {
    echo -e "\n${CYAN}🖼️ Demo de Sincronización de Wallpapers${RESET}"
    echo -e "Nota: Este demo requiere swww instalado y wallpapers en los directorios de temas"
    echo
    
    if ! command -v swww >/dev/null 2>&1; then
        echo -e "${YELLOW}⚠️ swww no está instalado. Instalando...${RESET}"
        sudo pacman -S swww --noconfirm
    fi
    
    echo -e "${GREEN}→ Inicializando swww...${RESET}"
    swww init
    
    local themes=("nord" "dracula" "catppuccin" "tokyo-night")
    local theme_names=("Nord" "Dracula" "Catppuccin" "Tokyo Night")
    
    for i in "${!themes[@]}"; do
        echo -e "${GREEN}→ Aplicando ${theme_names[$i]} con wallpaper...${RESET}"
        "$SCRIPT_DIR/theme-switcher.sh" apply "${themes[$i]}" --no-preview
        sleep 2
    done
    
    echo -e "\n${GREEN}✅ Demo de sincronización de wallpapers completado${RESET}"
    read -p "Presiona Enter para continuar..."
}

demo_scheduling() {
    echo -e "\n${CYAN}⏰ Demo de Programación Día/Noche${RESET}"
    echo -e "Configurando cambio automático entre Catppuccin (día) y Tokyo Night (noche)..."
    echo
    
    "$SCRIPT_DIR/theme-switcher.sh" schedule catppuccin tokyo-night
    
    echo -e "${GREEN}✅ Programación configurada${RESET}"
    echo -e "${BLUE}📋 Para verificar el estado:${RESET}"
    echo -e "   systemctl --user status auto-theme-switcher.timer"
    echo -e "   systemctl --user list-timers | grep theme"
    echo
    echo -e "${YELLOW}💡 El cambio automático ocurrirá cada hora${RESET}"
    read -p "Presiona Enter para continuar..."
}

demo_backup_restore() {
    echo -e "\n${CYAN}💾 Demo de Backup y Restore${RESET}"
    echo -e "Creando backup de la configuración actual..."
    echo
    
    # Crear backup
    local backup_path=$("$SCRIPT_DIR/theme-switcher.sh" backup)
    echo -e "${GREEN}✅ Backup creado en: $backup_path${RESET}"
    
    echo -e "\n${BLUE}→ Aplicando tema diferente...${RESET}"
    "$SCRIPT_DIR/theme-switcher.sh" apply dracula --no-preview --no-wallpaper
    
    echo -e "\n${YELLOW}¿Restaurar el backup? (s/n):${RESET}"
    read -r response
    
    if [[ "$response" =~ ^[Ss]$ ]]; then
        echo -e "${GREEN}→ Restaurando backup...${RESET}"
        "$SCRIPT_DIR/theme-switcher.sh" restore "$backup_path"
        echo -e "${GREEN}✅ Backup restaurado${RESET}"
    else
        echo -e "${BLUE}→ Backup no restaurado${RESET}"
    fi
    
    read -p "Presiona Enter para continuar..."
}

demo_custom_theme() {
    echo -e "\n${CYAN}🎨 Demo de Tema Personalizado${RESET}"
    echo -e "Creando tema personalizado de ejemplo..."
    echo
    
    # Crear tema personalizado
    "$SCRIPT_DIR/theme-switcher.sh" create demo-custom
    
    echo -e "${GREEN}✅ Tema personalizado 'demo-custom' creado${RESET}"
    echo -e "${BLUE}📁 Ubicación: ~/.config/hyprdream/themes/demo-custom/${RESET}"
    echo
    echo -e "${YELLOW}💡 Para personalizar:${RESET}"
    echo -e "   nano ~/.config/hyprdream/themes/demo-custom/colors.conf"
    echo
    echo -e "${BLUE}→ Aplicando tema personalizado...${RESET}"
    "$SCRIPT_DIR/theme-switcher.sh" apply demo-custom --no-preview
    
    echo -e "\n${GREEN}✅ Demo de tema personalizado completado${RESET}"
    read -p "Presiona Enter para continuar..."
}

demo_integration() {
    echo -e "\n${CYAN}🔧 Demo de Integración con Componentes${RESET}"
    echo -e "Mostrando cómo el sistema se integra con cada componente:"
    echo
    
    echo -e "${GREEN}┌─ Hyprland${RESET}"
    echo -e "   ├─ Colores de ventana y bordes"
    echo -e "   ├─ Configuración de blur y transparencia"
    echo -e "   └─ Decoración automática"
    echo
    
    echo -e "${GREEN}┌─ Waybar${RESET}"
    echo -e "   ├─ Variables CSS por tema"
    echo -e "   ├─ Colores de módulos"
    echo -e "   └─ Estados de batería, red, etc."
    echo
    
    echo -e "${GREEN}┌─ Rofi${RESET}"
    echo -e "   ├─ Temas RASI automáticos"
    echo -e "   ├─ Transparencias y blur"
    echo -e "   └─ Colores de elementos"
    echo
    
    echo -e "${GREEN}┌─ Kitty${RESET}"
    echo -e "   ├─ Color schemes automáticos"
    echo -e "   ├─ Configuración de transparencia"
    echo -e "   └─ Fuentes Nerd Fonts"
    echo
    
    echo -e "${GREEN}┌─ Notificaciones (Dunst/Mako)${RESET}"
    echo -e "   ├─ Colores de fondo y texto"
    echo -e "   ├─ Bordes y transparencias"
    echo -e "   └─ Estados de urgencia"
    echo
    
    echo -e "${BLUE}📋 Comandos de verificación:${RESET}"
    echo -e "   hyprctl reload                    # Recargar Hyprland"
    echo -e "   waybar-msg cmd reload            # Recargar Waybar"
    echo -e "   rofi -show drun                  # Probar Rofi"
    echo -e "   kitty --config ~/.config/kitty/kitty.conf  # Probar Kitty"
    echo
    
    read -p "Presiona Enter para continuar..."
}

main() {
    while true; do
        show_demo_menu
        echo -n "Opción: "
        read -r opt
        
        case $opt in
            1) demo_show_themes ;;
            2) demo_quick_switch ;;
            3) demo_preview ;;
            4) demo_wallpaper_sync ;;
            5) demo_scheduling ;;
            6) demo_backup_restore ;;
            7) demo_custom_theme ;;
            8) demo_integration ;;
            0) 
                echo -e "\n${GREEN}¡Gracias por probar el sistema de temas!${RESET}"
                echo -e "${BLUE}Para más información: theme-switcher --help${RESET}"
                exit 0 
                ;;
            *) 
                echo -e "\n${RED}Opción inválida.${RESET}"
                sleep 1
                ;;
        esac
    done
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main "$@"
fi 