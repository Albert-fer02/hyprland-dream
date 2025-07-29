# 📦 Guía de Módulos - Hyprland Dream v1.0

Esta guía proporciona información detallada sobre todos los módulos disponibles en Hyprland Dream, reemplazando los README.md individuales de cada módulo.

## 🎯 Módulos Core (Esenciales)

### 🏗️ Hyprland
**Ubicación**: `modules/hypr/`

**Descripción**: Window manager principal con configuraciones optimizadas.

**Características**:
- Configuración modular con animaciones fluidas
- Keybinds optimizados y personalizables
- Integración con Wayland
- Gestión avanzada de workspaces
- Configuraciones de ventanas y decoraciones

**Instalación**:
```bash
./modules/hypr/install.sh
```

**Archivos de Configuración**:
- `config/hyprland.conf` - Configuración principal
- `config/animations.conf` - Animaciones y transiciones
- `config/keybinds.conf` - Atajos de teclado
- `config/monitors.conf` - Configuración de monitores
- `config/windowrules.conf` - Reglas de ventanas
- `config/workspace.conf` - Gestión de workspaces

---

### 🎨 Waybar
**Ubicación**: `modules/waybar/`

**Descripción**: Barra de estado modular con múltiples temas y scripts interactivos.

**Características**:
- 4 temas predefinidos (Tokyo Night, Nord, Dracula, Catppuccin)
- Scripts interactivos para gestión de sistema
- Módulos avanzados (CPU, RAM, red, audio, batería)
- Cambio dinámico de temas
- Diseño moderno y responsive

**Instalación**:
```bash
./modules/waybar/install.sh
```

**Temas Disponibles**:
- **Tokyo Night**: Colores nocturnos y elegantes
- **Nord**: Paleta fría y minimalista
- **Dracula**: Colores vibrantes y contrastantes
- **Catppuccin**: Colores suaves y cálidos

**Scripts Interactivos**:
- `system-info.sh` - Información del sistema
- `network-menu.sh` - Gestión de red
- `volume-menu.sh` - Control de audio
- `battery-menu.sh` - Información de batería
- `calendar-menu.sh` - Calendario y fecha
- `theme-switcher.sh` - Cambio de temas

---

### 🔔 Dunst
**Ubicación**: `modules/dunst/`

**Descripción**: Sistema de notificaciones configurado y optimizado.

**Características**:
- Configuración integrada con temas del sistema
- Notificaciones elegantes y personalizables
- Integración con Hyprland
- Gestión de prioridades y timeouts

**Instalación**:
```bash
./modules/dunst/install.sh
```

---

### 🖥️ Kitty
**Ubicación**: `modules/kitty/`

**Descripción**: Terminal emulator con configuraciones optimizadas.

**Características**:
- Temas integrados con el sistema
- Configuración de fuentes y colores
- Atajos personalizados
- Soporte para múltiples sesiones

**Instalación**:
```bash
./modules/kitty/install.sh
```

---

## 🛠️ Módulos de Utilidades

### 🎮 Rofi
**Ubicación**: `modules/rofi/`

**Descripción**: Launcher y menús personalizados.

**Características**:
- App launcher con búsqueda fuzzy
- Power menu elegante
- WiFi menu interactivo
- Window switcher
- Emoji picker
- Calculadora integrada

**Instalación**:
```bash
./modules/rofi/install.sh
```

**Menús Disponibles**:
- **App Launcher**: `Super + D`
- **Power Menu**: `Super + X`
- **WiFi Menu**: Acceso desde waybar
- **Window Switcher**: `Super + Tab`

---

### 🔒 Swaylock
**Ubicación**: `modules/swaylock/`

**Descripción**: Bloqueo de pantalla personalizado.

**Características**:
- Diseño elegante y minimalista
- Integración con temas del sistema
- Configuración de efectos visuales
- Gestión de eventos de seguridad

**Instalación**:
```bash
./modules/swaylock/install.sh
```

---

### 🖼️ Swww
**Ubicación**: `modules/swww/`

**Descripción**: Gestor de wallpapers para Wayland.

**Características**:
- Cambio dinámico de wallpapers
- Transiciones suaves
- Integración con temas
- Soporte para múltiples formatos

**Instalación**:
```bash
./modules/swww/install.sh
```

---

### 🚪 Wlogout
**Ubicación**: `modules/wlogout/`

**Descripción**: Menú de logout elegante.

**Características**:
- Interfaz moderna y responsive
- Opciones de logout, reboot, shutdown
- Integración con temas del sistema
- Animaciones suaves

**Instalación**:
```bash
./modules/wlogout/install.sh
```

---

### 🔔 Mako
**Ubicación**: `modules/mako/`

**Descripción**: Sistema de notificaciones alternativo.

**Características**:
- Notificaciones minimalistas
- Configuración simple
- Integración con Wayland
- Gestión de prioridades

**Instalación**:
```bash
./modules/mako/install.sh
```

---

## 🎨 Módulos de Personalización

### 🎨 Temas
**Ubicación**: `modules/themes/`

**Descripción**: Sistema completo de gestión de temas.

**Características**:
- 4 temas predefinidos completos
- Cambio instantáneo de temas
- Sincronización automática de wallpapers
- Programación día/noche
- Aplicación universal en todos los componentes

**Temas Disponibles**:
- **Nord**: Azules fríos y minimalismo nórdico
- **Dracula**: Morados vibrantes y elegancia oscura
- **Catppuccin**: Pasteles suaves y colores cálidos
- **Tokyo Night**: Neones urbanos y estética cyberpunk

**Instalación**:
```bash
./modules/themes/install.sh
```

**Uso**:
```bash
# Cambiar tema
./modules/themes/theme-switcher.sh nord

# Listar temas
./modules/themes/theme-switcher.sh list

# Demo de temas
./modules/themes/demo.sh
```

---

### 🔤 Fuentes
**Ubicación**: `modules/fonts/`

**Descripción**: Instalación y configuración de fuentes del sistema.

**Características**:
- Fuentes optimizadas para desarrollo
- Configuración automática de fuentes
- Soporte para iconos y símbolos
- Integración con temas

**Instalación**:
```bash
./modules/fonts/install.sh
```

---

### ⚡ Power Management
**Ubicación**: `modules/power-management/`

**Descripción**: Gestión avanzada de energía y seguridad.

**Características**:
- Gestión de batería y energía
- Configuración de suspensión
- Gestión de eventos de tapa (laptop)
- Servicios systemd automáticos
- Configuración de seguridad

**Instalación**:
```bash
./modules/power-management/install.sh
```

**Servicios Incluidos**:
- `lid-close-handler.service` - Gestión de tapa
- `power-management.service` - Gestión de energía
- `media-daemon.service` - Control multimedia
- `auto-pause-headphones.service` - Auto-pause

---

### 🎵 Media
**Ubicación**: `modules/media/`

**Descripción**: Controles multimedia avanzados.

**Características**:
- Gestión de dispositivos de audio
- Control de volumen con OSD
- Media controls para reproductores
- Auto-pause para auriculares
- Integración con waybar

**Instalación**:
```bash
./modules/media/install.sh
```

---

## 🔧 Módulos Opcionales

### 📝 Nano
**Ubicación**: `modules/nano/`

**Descripción**: Editor de texto con configuración avanzada.

**Características**:
- Tema Catppuccin Mocha
- Atajos personalizados (F5-F12)
- Resaltado de sintaxis completo
- Funciones de productividad
- Sistema de respaldos automáticos

**Instalación**:
```bash
./modules/nano/install.sh
```

**Atajos Personalizados**:
- **F5**: Ejecutar archivo según extensión
- **F6**: Git diff mejorado
- **F7**: Git workflow completo
- **F8**: Información del archivo
- **F9**: Buscar comentarios
- **F10**: Análisis de código
- **F11**: Formatear código
- **F12**: Búsqueda de funciones

---

### 🐚 Zsh
**Ubicación**: `modules/zsh/`

**Descripción**: Shell avanzado con configuración optimizada.

**Características**:
- Configuración de Oh My Zsh
- Plugins útiles preconfigurados
- Temas integrados
- Aliases y funciones personalizadas

**Instalación**:
```bash
./modules/zsh/install.sh
```

---

### 📊 Fastfetch
**Ubicación**: `modules/Fastfetch/`

**Descripción**: Información del sistema con tema personalizado.

**Características**:
- Tema Catppuccin Mocha
- Logo personalizado rotativo
- Información detallada del sistema
- Diseño minimalista y elegante

**Instalación**:
```bash
./modules/Fastfetch/install.sh
```

**Uso**:
```bash
fastfetch
```

---

## 🚀 Instalación de Módulos

### Instalación Individual
```bash
# Instalar módulo específico
./modules/[nombre-modulo]/install.sh

# Ejemplos
./modules/hypr/install.sh
./modules/waybar/install.sh
./modules/themes/install.sh
```

### Instalación Selectiva
```bash
# Usar el instalador principal
./install.sh

# Seleccionar módulos específicos
./install.sh --select hypr,waybar,rofi
```

### Instalación Completa
```bash
# Instalar todos los módulos
./install.sh --all
```

---

## 🔧 Configuración de Módulos

### Estructura Común
Cada módulo sigue una estructura estándar:
```
modules/[nombre-modulo]/
├── install.sh          # Script de instalación
├── config/            # Archivos de configuración
│   ├── archivo1.conf
│   └── archivo2.conf
└── scripts/           # Scripts adicionales (opcional)
    └── script.sh
```

### Personalización
1. **Editar configuraciones**: Modifica archivos en `config/`
2. **Agregar scripts**: Coloca scripts personalizados en `scripts/`
3. **Temas**: Usa el sistema de temas para cambios globales
4. **Keybinds**: Personaliza en `modules/hypr/config/keybinds.conf`

---

## 🐛 Solución de Problemas

### Problemas Comunes

#### Módulo no se instala
```bash
# Verificar dependencias
./bin/dream-deps check

# Verificar permisos
chmod +x modules/[nombre-modulo]/install.sh

# Verificar espacio en disco
./core/disk-checker.sh check
```

#### Configuración no se aplica
```bash
# Verificar enlaces simbólicos
ls -la ~/.config/

# Reinstalar configuración
./modules/[nombre-modulo]/install.sh 2

# Verificar logs
tail -f /tmp/hyprdream.log
```

#### Tema no cambia
```bash
# Verificar tema actual
./modules/themes/theme-switcher.sh current

# Aplicar tema manualmente
./modules/themes/theme-switcher.sh [tema]

# Reiniciar componentes
hyprctl reload
```

---

## 📚 Recursos Adicionales

### Documentación
- **[README.md](../README.md)**: Guía principal
- **[INSTALL.md](INSTALL.md)**: Guía de instalación
- **[CHANGELOG.md](CHANGELOG.md)**: Historial de cambios

### Scripts de Verificación
- `verify-system.sh`: Verificación completa del sistema
- `test-system.sh`: Tests de funcionalidad
- `diagnostico-sistema.sh`: Diagnóstico del sistema

### Comunidad
- **GitHub Issues**: [Reportar problemas](https://github.com/tu-usuario/hyprland-dream/issues)
- **GitHub Discussions**: [Discusiones](https://github.com/tu-usuario/hyprland-dream/discussions)

---

**Nota**: Esta guía reemplaza los README.md individuales de cada módulo para proporcionar una documentación más organizada y fácil de mantener. 