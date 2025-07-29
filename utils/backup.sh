#!/usr/bin/env bash
# hyprdream - Backup seguro de configuraciones y assets
set -e

source "$(dirname "$0")/../core/colors.sh"

BACKUP_DIR=~/Backups/hyprland-dream/$(date +"%Y-%m-%d_%H-%M-%S")

show_menu() {
    echo -e "\n$CYAN=== Backup hyprdream ===$RESET"
    echo "¿Qué deseas respaldar? (elige separando por espacios, ej: 1 2 3)"
    echo " 1) ~/.config (todas las configuraciones)"
    echo " 2) ~/.zshrc"
    echo " 3) Fondos de pantalla (~/Imágenes, ~/Pictures)"
    echo " 4) Todo"
    echo " 0) Salir"
    echo -n "Opción/es: "
    read -r opciones
}

backup_configs() {
    mkdir -p "$BACKUP_DIR/config"
    cp -ru ~/.config/* "$BACKUP_DIR/config/"
    echo -e "$SUCCESS Configuraciones respaldadas en $BACKUP_DIR/config."
}

backup_zshrc() {
    mkdir -p "$BACKUP_DIR/home"
    cp -u ~/.zshrc "$BACKUP_DIR/home/" 2>/dev/null || true
    echo -e "$SUCCESS .zshrc respaldado en $BACKUP_DIR/home."
}

backup_wallpapers() {
    mkdir -p "$BACKUP_DIR/wallpapers"
    cp -ru ~/Imágenes/* "$BACKUP_DIR/wallpapers/" 2>/dev/null || true
    cp -ru ~/Pictures/* "$BACKUP_DIR/wallpapers/" 2>/dev/null || true
    echo -e "$SUCCESS Fondos respaldados en $BACKUP_DIR/wallpapers."
}

main() {
    while true; do
        show_menu
        for opt in $opciones; do
            case $opt in
                1) backup_configs;;
                2) backup_zshrc;;
                3) backup_wallpapers;;
                4)
                    backup_configs
                    backup_zshrc
                    backup_wallpapers
                    ;;
                0) echo -e "$INFO Saliendo..."; exit 0;;
                *) echo -e "$WARN Opción inválida: $opt";;
            esac
        done
        echo -e "$SUCCESS Backup completado en $BACKUP_DIR."
        break
    done
}

main "$@"

