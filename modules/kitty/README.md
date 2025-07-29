# Módulo Kitty para hyprdream

Este módulo permite instalar y configurar **Kitty** de forma modular y reutilizable en Arch Linux, como parte del entorno hyprdream.

## Estructura
- `install.sh`: Script principal para instalar Kitty y copiar su configuración. Usa funciones de `lib/utils.sh`.
- `config/`: Carpeta con archivos de configuración de ejemplo para Kitty (puedes agregar los tuyos).
- Funciones reutilizables: `install_package`, `copy_config`, `print_info`, `print_ok`, `print_error`, `print_warn`.
- Compatible con **pacman** y **paru** (AUR helper).

## Uso
Puedes ejecutar el script directamente:

```bash
bash install.sh
```

Se mostrará un menú interactivo:
- Instalar Kitty (paquete y configuración)
- Copiar solo la configuración

También puedes importar funciones desde otros scripts para reutilizarlas.

## Integración
Este módulo está diseñado para integrarse fácilmente con menús interactivos globales o scripts principales del proyecto hyprdream.

## Requisitos
- Arch Linux
- Pacman o Paru (el script detecta y usa el que esté disponible)
- `lib/utils.sh` en la raíz del proyecto

## Autoría
hyprdream - https://github.com/dreamcoder08/hyprland-dream 