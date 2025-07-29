# Sistema de Temas Coherente e Intercambiable para Hyprland Dream

## 🎨 Descripción

Este módulo proporciona un sistema completo de gestión de temas para Hyprland Dream con características avanzadas de personalización, cambio instantáneo de temas, sincronización automática de wallpapers y programación de cambios día/noche.

## ✨ Características Principales

### 🎯 **Temas Incluidos**
- **Nord** - Azules fríos y minimalismo nórdico
- **Dracula** - Morados vibrantes y elegancia oscura
- **Catppuccin** - Pasteles suaves y colores cálidos
- **Tokyo Night** - Neones urbanos y estética cyberpunk
- **Custom** - Constructor de temas personalizados

### 🔄 **Cambio Instantáneo**
- Script `theme-switcher.sh` para cambios inmediatos
- Preservación automática de configuraciones personales
- Backup y restore de configuraciones
- Preview antes de aplicar cambios

### 🖼️ **Sincronización de Wallpapers**
- Integración automática con `swww`
- Wallpapers específicos por tema
- Cambio aleatorio de wallpapers
- Soporte para múltiples formatos (jpg, png, webp)

### ⏰ **Programación Automática**
- Cambio automático día/noche
- Configuración de horarios personalizables
- Servicio systemd para ejecución automática
- Temas diferentes para día y noche

### 🎭 **Aplicación Universal**
- **Hyprland** - Colores de ventana y decoración
- **Waybar** - Esquemas de color y estilos
- **Rofi** - Temas matching y transparencias
- **Kitty** - Color schemes y configuración
- **Dunst/Mako** - Notificaciones con tema

## 📁 Estructura del Sistema

```
modules/themes/
├── themes/
│   ├── nord/
│   │   ├── colors.conf          # Configuración de colores
│   │   ├── wallpapers/          # Wallpapers específicos
│   │   └── configs/
│   │       └── waybar.css       # CSS específico para Waybar
│   ├── dracula/
│   ├── catppuccin/
│   ├── tokyo-night/
│   └── custom/
├── theme-switcher.sh            # Script principal
├── install.sh                   # Instalador del módulo
└── README.md                    # Esta documentación
```

## 🚀 Instalación

### Instalación Completa
```bash
# Instalar el módulo completo
./modules/themes/install.sh

# O usar el instalador principal
./install.sh themes
```

### Instalación Manual
```bash
# Solo dependencias
./modules/themes/install.sh 2

# Solo temas GTK
./modules/themes/install.sh 3

# Solo configuración del sistema
./modules/themes/install.sh 6
```

## 🎮 Uso

### Comandos Principales

#### Aplicar Tema
```bash
# Aplicar tema específico
theme-switcher apply nord

# Aplicar sin preview
theme-switcher apply dracula --no-preview

# Aplicar sin sincronizar wallpaper
theme-switcher apply catppuccin --no-wallpaper
```

#### Gestión de Temas
```bash
# Listar temas disponibles
theme-switcher list

# Mostrar tema actual
theme-switcher current

# Preview de tema
theme-switcher preview tokyo-night
```

#### Backup y Restore
```bash
# Crear backup
theme-switcher backup

# Restaurar backup
theme-switcher restore /path/to/backup
```

#### Programación Automática
```bash
# Programar cambio día/noche
theme-switcher schedule catppuccin tokyo-night

# Verificar estado del servicio
systemctl --user status auto-theme-switcher.timer
```

#### Temas Personalizados
```bash
# Crear tema personalizado
theme-switcher create mi-tema

# Editar colores del tema
nano ~/.config/hyprdream/themes/mi-tema/colors.conf
```

### Modo Interactivo
```bash
# Ejecutar sin argumentos para modo interactivo
theme-switcher
```

## 🎨 Personalización

### Crear Tema Personalizado

1. **Crear estructura del tema**
```bash
theme-switcher create mi-tema
```

2. **Editar colores**
```bash
nano ~/.config/hyprdream/themes/mi-tema/colors.conf
```

3. **Agregar wallpapers**
```bash
cp mis-wallpapers/* ~/.config/hyprdream/themes/mi-tema/wallpapers/
```

4. **Aplicar tema**
```bash
theme-switcher apply mi-tema
```

### Configuración Avanzada

#### Archivo de Configuración
```bash
# Editar configuración global
nano ~/.config/hyprdream/theme-config.conf
```

#### Variables Disponibles
```bash
# Tema por defecto
DEFAULT_THEME="catppuccin"

# Nivel de blur
DEFAULT_BLUR_LEVEL="medium"

# Transparencia
DEFAULT_TRANSPARENCY="0.85"

# Sincronización de wallpapers
SYNC_WALLPAPERS=true

# Preview automático
AUTO_PREVIEW=false

# Cambio automático día/noche
AUTO_SWITCH_ENABLED=false
DAY_THEME="catppuccin"
NIGHT_THEME="tokyo-night"
```

## 🔧 Integración con Componentes

### Hyprland
- Colores de ventana y bordes
- Configuración de blur y transparencia
- Decoración automática
- Reglas de ventana con tema

### Waybar
- Variables CSS por tema
- Colores de módulos
- Estados de batería, red, etc.
- Estilos específicos por tema

### Rofi
- Temas RASI automáticos
- Transparencias y blur
- Colores de elementos
- Configuración de fuentes

### Kitty
- Color schemes automáticos
- Configuración de transparencia
- Fuentes Nerd Fonts
- Estilos de cursor

### Notificaciones (Dunst/Mako)
- Colores de fondo y texto
- Bordes y transparencias
- Estados de urgencia
- Configuración de fuentes

## 🎯 Niveles de Blur

| Nivel | Transparencia | Blur | Uso Recomendado |
|-------|---------------|------|-----------------|
| **Subtle** | 85% | 0.3 | Trabajo profesional |
| **Medium** | 75% | 0.5 | Experiencia balanceada |
| **Strong** | 65% | 0.7 | Estética moderna |
| **Glass** | 50% | 0.8 | Máxima transparencia |

## 🔄 Sincronización de Wallpapers

### Configuración Automática
```bash
# Habilitar sincronización
echo "SYNC_WALLPAPERS=true" >> ~/.config/hyprdream/theme-config.conf

# Aplicar tema con wallpaper
theme-switcher apply nord
```

### Wallpapers por Tema
```bash
# Agregar wallpapers al tema
cp mis-imagenes/* ~/.config/hyprdream/themes/nord/wallpapers/

# Ver wallpapers disponibles
ls ~/.config/hyprdream/themes/nord/wallpapers/
```

## ⏰ Programación Automática

### Configurar Cambio Día/Noche
```bash
# Programar cambio automático
theme-switcher schedule catppuccin tokyo-night

# Verificar servicio
systemctl --user list-timers | grep theme
```

### Configuración Manual
```bash
# Editar horarios
nano ~/.config/hyprdream/theme-config.conf

# Reiniciar servicio
systemctl --user restart auto-theme-switcher.timer
```

## 🛠️ Solución de Problemas

### Problemas Comunes

#### Blur No Funciona
```bash
# Verificar hardware acceleration
glxinfo | grep "OpenGL renderer"

# Habilitar blur en Hyprland
echo "decoration { blur = true }" >> ~/.config/hypr/hyprland.conf
```

#### Fuentes No Cargadas
```bash
# Refrescar cache de fuentes
fc-cache -fv

# Verificar instalación
fc-list | grep "Nerd Font"
```

#### Wallpapers No Cambian
```bash
# Verificar swww
swww --version

# Verificar directorio de wallpapers
ls ~/.config/hyprdream/themes/*/wallpapers/
```

#### Servicio No Funciona
```bash
# Verificar estado
systemctl --user status auto-theme-switcher.service

# Habilitar servicio
systemctl --user enable auto-theme-switcher.timer
```

### Debug Mode
```bash
# Habilitar debug
export THEME_DEBUG=true
theme-switcher apply nord

# Ver logs
journalctl --user -u auto-theme-switcher.service
```

## 📊 Rendimiento

### Optimizaciones
- **Alto rendimiento**: Blur máximo y efectos completos
- **Bajo rendimiento**: Blur sutil y efectos mínimos
- **Ahorro de batería**: Transparencias reducidas

### Uso de Memoria
- **Rofi**: ~15MB
- **Waybar**: ~25MB
- **Hyprland**: ~50MB
- **Cache de temas**: ~10MB

## 🤝 Contribuir

### Agregar Nuevos Temas

1. **Crear estructura del tema**
```bash
mkdir -p modules/themes/themes/nuevo-tema/{wallpapers,configs}
```

2. **Definir colores**
```bash
# Crear colors.conf
nano modules/themes/themes/nuevo-tema/colors.conf
```

3. **Agregar CSS específico**
```bash
# Crear waybar.css
nano modules/themes/themes/nuevo-tema/configs/waybar.css
```

4. **Probar tema**
```bash
theme-switcher apply nuevo-tema
```

### Reportar Problemas

Incluir en el reporte:
- Nombre del tema y nivel de blur
- Especificaciones del sistema
- Mensajes de error
- Pasos para reproducir

## 📄 Licencia

Este módulo es parte de Hyprland Dream y sigue los mismos términos de licencia.

## 🆘 Soporte

Para soporte y preguntas:
- Revisar la sección de solución de problemas
- Verificar ejemplos de configuración
- Abrir un issue en GitHub
- Unirse a las discusiones de la comunidad

---

**¡Disfruta de tu experiencia visual coherente y personalizable con Hyprland Dream! 🎨✨** 