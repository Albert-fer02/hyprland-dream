#!/usr/bin/env bash
# Verificador de estructura modular para hyprdream (solo Arch Linux)
set -e

ROOT_DIR="$(dirname "$0")/.."
source "$ROOT_DIR/core/colors.sh"

ok()   { echo -e "$SUCCESS $*"; }
warn() { echo -e "$WARN $*"; }
err()  { echo -e "$ERROR $*"; }

# 1. Verificar Arch Linux
if ! grep -qi arch /etc/os-release; then
    err "Este script solo funciona en Arch Linux."
    exit 1
fi
ok "Sistema Arch Linux detectado."

# 2. Verificar que solo hay carpetas en modules/
sh_files=$(find "$ROOT_DIR/modules" -maxdepth 1 -type f -name "*.sh")
if [[ -n "$sh_files" ]]; then
    warn "Se encontraron scripts sueltos en modules/:"
    echo "$sh_files"
else
    ok "No hay scripts sueltos en modules/. Solo carpetas."
fi

# 3. Verificar estructura de cada módulo
fail=0
for mod in "$ROOT_DIR"/modules/*/; do
    name=$(basename "$mod")
    missing=()
    [[ -f "$mod/install.sh" ]] || missing+=(install.sh)
    [[ -d "$mod/config" ]]    || missing+=(config/)
    [[ -f "$mod/README.md" ]] || missing+=(README.md)
    if [[ ${#missing[@]} -eq 0 ]]; then
        ok "Módulo $name: estructura correcta."
    else
        warn "Módulo $name: faltan ${missing[*]}"
        fail=1
    fi
done

if [[ $fail -eq 0 ]]; then
    ok "Todos los módulos tienen la estructura recomendada."
else
    warn "Algunos módulos no cumplen la estructura recomendada."
fi 