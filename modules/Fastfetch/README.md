# Fastfetch - Información del Sistema

## Descripción
Configuración personalizada de Fastfetch con tema Catppuccin y logo personalizado para mostrar información del sistema de manera elegante.

## Características
- 🎨 Tema Catppuccin Mocha
- 🖼️ Logo personalizado rotativo (4 variantes)
- 📊 Información detallada del sistema
- 🎯 Diseño minimalista y elegante
- 🔧 Integración con el tema del sistema

## Información Mostrada
- Usuario y hostname
- Uptime del sistema
- Distribución y kernel
- Entorno de escritorio
- Terminal y shell
- CPU y memoria
- Disco y red
- Paleta de colores

## Logo Personalizado
El sistema incluye 4 variantes del logo que se seleccionan aleatoriamente:
- Dreamcoder01.jpg
- Dreamcoder02.jpg
- Dreamcoder03.jpg
- Dreamcoder04.jpg

## Instalación
```bash
# Instalar completo
./install.sh

# Solo configuración
./install.sh 2
```

## Configuración
El archivo de configuración se instala en `~/.config/fastfetch/config.json` y las imágenes en `~/.config/fastfetch/`.

## Uso
```bash
fastfetch
```

## Personalización
Para cambiar el logo, reemplaza las imágenes en `~/.config/fastfetch/` con tus propias imágenes. 