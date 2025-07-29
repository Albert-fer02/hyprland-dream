#!/usr/bin/env bash
# Funciones reutilizables para módulos hyprdream (solo Arch Linux)

ROOT_DIR="$(dirname "${BASH_SOURCE[0]}")/.."
source "$ROOT_DIR/core/colors.sh"

print_info()   { echo -e "$INFO $*"; }
print_ok()     { echo -e "$SUCCESS $*"; }
print_error()  { echo -e "$ERROR $*"; }
print_warn()   { echo -e "$WARN $*"; }

# Instala un paquete usando paru o pacman
install_package() {
    local pkg="$1"
    if command -v paru &>/dev/null; then
        paru -S --needed --noconfirm "$pkg"
    else
        sudo pacman -S --needed --noconfirm "$pkg"
    fi
}

# Copia configuración desde un origen a ~/.config/<modulo>
copy_config() {
    local src="$1"
    local module_name=$(basename "$(dirname "$src")")
    local dest=~/.config/$module_name
    mkdir -p "$dest"
    cp -ru "$src/"* "$dest/"
    print_ok "Configuración de '$module_name' copiada a $dest."
}

# Copia scripts desde un origen a ~/.config/<modulo>/scripts
copy_scripts() {
    local src="$1"
    local module_name=""

    if [[ "$src" == "$ROOT_DIR/scripts/media" ]]; then
        module_name="media"
    else
        module_name=$(basename "$(dirname "$src")")
    fi

    if [ ! -d "$src" ]; then
        print_info "No se encontró directorio de scripts para $module_name, omitiendo."
        return
    fi

    local dest=~/.config/$module_name/scripts
    mkdir -p "$dest"
    cp -ru "$src/"* "$dest/"
    print_ok "Scripts de '$module_name' copiados a $dest."

}

# Verifica que se está en Arch Linux
require_arch() {
    if ! grep -qi arch /etc/os-release; then
        print_error "Este script solo funciona en Arch Linux."; exit 1
    fi
} 