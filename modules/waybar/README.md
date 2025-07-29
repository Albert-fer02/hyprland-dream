# Waybar - Barra de Estado Modular

Una configuración modular y avanzada de Waybar para Hyprland con múltiples temas, scripts interactivos y diseño moderno.

## 🚀 Características

- **Configuración modular**: Estructura organizada y fácil de personalizar
- **Múltiples temas**: 4 temas predefinidos (Tokyo Night, Nord, Dracula, Catppuccin)
- **Scripts interactivos**: Menús para gestión de sistema, red, audio y más
- **Diseño moderno**: Animaciones suaves, efectos hover y responsive design
- **Módulos avanzados**: Workspaces, sistema, red, audio, batería, reloj y bandeja
- **Cambio dinámico de temas**: Script para cambiar temas sin reiniciar

## 📁 Estructura

```
modules/waybar/
├── config/
│   ├── config.json          # Configuración principal de Waybar
│   ├── style.css            # Estilos por defecto (Tokyo Night)
│   ├── scripts/             # Scripts interactivos
│   │   ├── system-info.sh   # Información del sistema
│   │   ├── network-menu.sh  # Gestión de red
│   │   ├── volume-menu.sh   # Control de audio
│   │   ├── battery-menu.sh  # Información de batería
│   │   ├── calendar-menu.sh # Calendario y fecha
│   │   └── theme-switcher.sh # Cambio de temas
│   └── themes/              # Temas disponibles
│       ├── nord.css         # Tema Nord
│       ├── dracula.css      # Tema Dracula
│       ├── catppuccin.css   # Tema Catppuccin
│       └── tokyo-night.css  # Tema Tokyo Night
├── install.sh               # Script de instalación
└── README.md               # Este archivo
```

## 🎨 Temas Disponibles

### Tokyo Night (Por defecto)
- Colores nocturnos y elegantes
- Paleta azul-gris con acentos vibrantes
- Perfecto para uso nocturno

### Nord
- Paleta fría y minimalista
- Colores azules y grises suaves
- Inspirado en el tema Nord

### Dracula
- Colores vibrantes y contrastantes
- Paleta púrpura, verde y naranja
- Ideal para desarrolladores

### Catppuccin Mocha
- Colores suaves y cálidos
- Paleta beige, rosa y azul
- Diseño moderno y elegante

## 🔧 Módulos Incluidos

### Workspaces
- Indicadores visuales para workspaces activos
- Iconos personalizados y animaciones
- Navegación con scroll y click

### Sistema
- CPU, RAM y temperatura en tiempo real
- Indicadores de color según el uso
- Tooltips con información detallada

### Red
- WiFi y Ethernet con indicadores de señal
- Menú interactivo para cambiar redes
- Información de IP y estado de conexión

### Audio
- Control de volumen con click
- Cambio de dispositivos de audio
- Indicadores de mute y Bluetooth

### Batería
- Nivel de batería con alertas
- Información de tiempo restante
- Estados de carga y advertencia

### Reloj
- Fecha y hora personalizables
- Calendario interactivo
- Configuración de zona horaria

### Bandeja del Sistema
- Iconos de aplicaciones en segundo plano
- Indicadores de estado y notificaciones

## 📦 Instalación

### Instalación Completa
```bash
./modules/waybar/install.sh
# Selecciona opción 1 para instalación completa
```

### Solo Configuración
```bash
./modules/waybar/install.sh
# Selecciona opción 2 para solo configuración
```

### Dependencias Adicionales
```bash
./modules/waybar/install.sh
# Selecciona opción 3 para instalar dependencias
```

## 🎯 Uso

### Iniciar Waybar
```bash
waybar
```

### Cambiar Tema
```bash
~/.config/waybar/scripts/theme-switcher.sh
```

### Scripts Individuales
```bash
# Información del sistema
~/.config/waybar/scripts/system-info.sh

# Menú de red
~/.config/waybar/scripts/network-menu.sh

# Control de volumen
~/.config/waybar/scripts/volume-menu.sh

# Información de batería
~/.config/waybar/scripts/battery-menu.sh

# Calendario
~/.config/waybar/scripts/calendar-menu.sh
```

## ⚙️ Configuración

### Personalizar Módulos
Edita `~/.config/waybar/config.json` para:
- Agregar/quitar módulos
- Cambiar posiciones
- Modificar intervalos de actualización
- Personalizar formatos

### Personalizar Estilos
Edita `~/.config/waybar/style.css` para:
- Cambiar colores
- Modificar animaciones
- Ajustar tamaños
- Personalizar fuentes

### Crear Temas Personalizados
1. Copia un tema existente en `~/.config/waybar/themes/`
2. Modifica los colores y estilos
3. Usa el theme-switcher para aplicar

## 🔧 Dependencias

### Requeridas
- `waybar` - Barra de estado
- `rofi` - Menús interactivos
- `pulseaudio` - Control de audio
- `networkmanager` - Gestión de red

### Opcionales
- `bc` - Cálculos en scripts
- `lm_sensors` - Información de temperatura
- `pavucontrol` - Control avanzado de audio

## 🎨 Personalización Avanzada

### Agregar Nuevos Módulos
1. Crea el script en `~/.config/waybar/scripts/`
2. Agrega la configuración en `config.json`
3. Define los estilos en `style.css`

### Crear Temas Personalizados
1. Define variables CSS con colores
2. Aplica estilos a cada módulo
3. Incluye animaciones y efectos hover

### Scripts Personalizados
Los scripts siguen el patrón:
- Verificación de dependencias
- Funciones modulares
- Menús interactivos con rofi
- Notificaciones informativas

## 🐛 Solución de Problemas

### Waybar no inicia
```bash
# Verificar configuración
waybar --check-config

# Ver logs
waybar --log-level=debug
```

### Scripts no funcionan
```bash
# Verificar permisos
chmod +x ~/.config/waybar/scripts/*.sh

# Verificar dependencias
which rofi pulseaudio nmcli
```

### Temas no se aplican
```bash
# Verificar enlaces simbólicos
ls -la ~/.config/waybar/style.css

# Recrear enlace
ln -sf ~/.config/waybar/themes/tokyo-night.css ~/.config/waybar/style.css
```

## 🤝 Contribuir

1. Crea un tema personalizado
2. Agrega nuevos módulos
3. Mejora scripts existentes
4. Reporta bugs o sugerencias

## 📄 Licencia

Este módulo está bajo la Licencia MIT. Ver el archivo `LICENSE` para más detalles.

---

**¡Disfruta tu barra de estado personalizada!** 🎉 