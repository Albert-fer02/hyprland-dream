# 🎉 Hyprland Dream v1.0

<div align="center">

![Hyprland Dream](https://img.shields.io/badge/Hyprland-Dream-9cf?style=for-the-badge&logo=archlinux)
![Version](https://img.shields.io/badge/Version-1.0.0-blue?style=for-the-badge)
![Arch Linux](https://img.shields.io/badge/Arch_Linux-1793D1?style=for-the-badge&logo=arch-linux&logoColor=white)
![Wayland](https://img.shields.io/badge/Wayland-000000?style=for-the-badge&logo=wayland&logoColor=white)

**Un sistema modular de dotfiles para Hyprland en Arch Linux, diseñado con buenas prácticas de bash scripting y manejo de errores robusto.**

[🚀 Instalación Rápida](#-instalación-rápida) • [📸 Screenshots](#-screenshots) • [🎨 Temas](#-temas) • [📚 Documentación](#-documentación) • [🐛 Issues](https://github.com/Albert-fer02/hyprland-dream/issues)

</div>

---

## 📸 Screenshots

<div align="center">

### 🎨 Tema Catppuccin
![Catppuccin Theme](assets/screenshots/catppuccin-desktop.png)
*Desktop con tema Catppuccin - Colores suaves y elegantes*

### 🌙 Tema Dracula
![Dracula Theme](assets/screenshots/dracula-desktop.png)
*Desktop con tema Dracula - Estilo oscuro y moderno*

### ❄️ Tema Nord
![Nord Theme](assets/screenshots/nord-desktop.png)
*Desktop con tema Nord - Paleta fría y minimalista*

### 🌃 Tema Tokyo Night
![Tokyo Night Theme](assets/screenshots/tokyo-night-desktop.png)
*Desktop con tema Tokyo Night - Inspirado en la noche de Tokio*

### 🎮 Rofi Launcher
![Rofi Launcher](assets/screenshots/rofi-launcher.png)
*Launcher personalizado con búsqueda fuzzy*

### 📊 Waybar
![Waybar](assets/screenshots/waybar.png)
*Barra de estado con múltiples módulos*

### 🔒 Swaylock
![Swaylock](assets/screenshots/swaylock.png)
*Bloqueo de pantalla elegante*

</div>

---

## 🚀 Instalación Rápida

### ⚡ Instalación Automática (Recomendada)

```bash
# Clonar el repositorio
git clone https://github.com/Albert-fer02/hyprland-dream.git
cd hyprland-dream

# Dar permisos de ejecución
chmod +x install.sh

# Ejecutar instalador automático
./install.sh
```

### 🎯 Instalación Selectiva

```bash
# Verificar dependencias primero
./bin/dream-deps check

# Instalar módulos específicos
./modules/hypr/install.sh      # Hyprland
./modules/waybar/install.sh    # Waybar
./modules/rofi/install.sh      # Rofi
./modules/kitty/install.sh     # Kitty
```

### 🔧 Instalación Manual

```bash
# 1. Instalar dependencias base
sudo pacman -S hyprland waybar dunst kitty rofi swww

# 2. Clonar configuraciones
git clone https://github.com/Albert-fer02/hyprland-dream.git ~/.config/hyprland-dream

# 3. Crear enlaces simbólicos
ln -sf ~/.config/hyprland-dream/modules/hypr/config ~/.config/hypr
ln -sf ~/.config/hyprland-dream/modules/waybar/config ~/.config/waybar
ln -sf ~/.config/hyprland-dream/modules/rofi/config ~/.config/rofi
```

---

## ✨ Características Principales

### 🏗️ Sistema Modular Avanzado
- **15+ módulos independientes** - Cada componente es completamente modular
- **Sistema de logging avanzado** - Con rotación y múltiples niveles
- **Gestión inteligente de dependencias** - Verificación automática y resolución
- **Detección de hardware** - Optimización automática según el hardware detectado
- **Sistema de rollback** - Recuperación automática en caso de errores

### 🎨 Interfaz y Personalización
- **4 temas predefinidos** - Catppuccin, Dracula, Nord, Tokyo Night
- **Sistema de temas dinámico** - Cambio en tiempo real sin reinicio
- **Configuraciones optimizadas** - Para Hyprland, Waybar, Rofi, Kitty
- **Animaciones fluidas** - Configuraciones de Hyprland optimizadas
- **Gestión de wallpapers** - Integración con swww

### 🛠️ Herramientas y Utilidades
- **Scripts de sistema** - Información, monitoreo, mantenimiento
- **Controles multimedia** - Gestión de audio, volumen, media controls
- **Gestión de workspaces** - Organización y navegación avanzada
- **Menús personalizados** - Power menu, wifi menu, app launcher
- **Notificaciones** - Sistema integrado con dunst/mako

### 🔧 Gestión Avanzada
- **Verificación de espacio en disco** - Prevención de errores de instalación
- **Sistema de backup** - Respaldo automático antes de cambios
- **Mantenimiento automático** - Limpieza y optimización del sistema
- **Monitoreo en tiempo real** - Progress bars y feedback visual
- **Validación robusta** - Verificación de dependencias y permisos

---

## 🎨 Temas

### 🌸 Catppuccin
```bash
# Activar tema Catppuccin
./modules/themes/theme-switcher.sh catppuccin
```
- **Colores**: Paleta suave y elegante
- **Estilo**: Moderno y minimalista
- **Wallpapers**: Incluidos en el tema

### 🌙 Dracula
```bash
# Activar tema Dracula
./modules/themes/theme-switcher.sh dracula
```
- **Colores**: Oscuro y contrastante
- **Estilo**: Elegante y profesional
- **Wallpapers**: Temáticos oscuros

### ❄️ Nord
```bash
# Activar tema Nord
./modules/themes/theme-switcher.sh nord
```
- **Colores**: Paleta fría y relajante
- **Estilo**: Minimalista y limpio
- **Wallpapers**: Paisajes nórdicos

### 🌃 Tokyo Night
```bash
# Activar tema Tokyo Night
./modules/themes/theme-switcher.sh tokyo-night
```
- **Colores**: Inspirado en la noche de Tokio
- **Estilo**: Moderno y vibrante
- **Wallpapers**: Urbanos y nocturnos

---

## 📦 Módulos Disponibles

### 🎯 Core (Esenciales)
| Módulo | Descripción | Estado |
|--------|-------------|--------|
| **hypr** | Hyprland window manager | ✅ Completo |
| **waybar** | Barra de estado | ✅ Completo |
| **dunst** | Sistema de notificaciones | ✅ Completo |
| **kitty** | Terminal emulator | ✅ Completo |

### 🛠️ Utilidades
| Módulo | Descripción | Estado |
|--------|-------------|--------|
| **rofi** | Launcher y menús | ✅ Completo |
| **mako** | Notificaciones (alternativo) | ✅ Completo |
| **wlogout** | Menú de logout | ✅ Completo |
| **swaylock** | Bloqueo de pantalla | ✅ Completo |
| **swww** | Gestor de wallpapers | ✅ Completo |

### 🎨 Personalización
| Módulo | Descripción | Estado |
|--------|-------------|--------|
| **fonts** | Fuentes del sistema | ✅ Completo |
| **themes** | Temas GTK e iconos | ✅ Completo |
| **power-management** | Gestión de energía | ✅ Completo |
| **media** | Controles multimedia | ✅ Completo |

---

## 🎮 Uso y Configuración

### ⌨️ Atajos de Teclado Principales

| Función | Atajo | Descripción |
|---------|-------|-------------|
| **Launcher** | `Super + D` | Abrir Rofi launcher |
| **Terminal** | `Super + Enter` | Abrir Kitty |
| **Power Menu** | `Super + X` | Menú de energía |
| **Screenshot** | `Super + S` | Captura de pantalla |
| **Volume** | `Super + F1/F2` | Control de volumen |
| **Brightness** | `Super + F3/F4` | Control de brillo |
| **Workspace** | `Super + 1-9` | Cambiar workspace |
| **Window** | `Super + Q` | Cerrar ventana |

### 🎛️ Controles Multimedia

```bash
# Control de volumen
./scripts/media/volume.sh up    # Subir volumen
./scripts/media/volume.sh down  # Bajar volumen
./scripts/media/volume.sh mute  # Silenciar

# Control de brillo
./scripts/system/brightness.sh up    # Subir brillo
./scripts/system/brightness.sh down  # Bajar brillo

# Screenshot
./scripts/system/screenshot.sh       # Captura completa
./scripts/system/screenshot.sh area  # Captura de área
```

### 🎨 Cambio de Temas

```bash
# Listar temas disponibles
./modules/themes/theme-switcher.sh list

# Cambiar tema
./modules/themes/theme-switcher.sh catppuccin
./modules/themes/theme-switcher.sh dracula
./modules/themes/theme-switcher.sh nord
./modules/themes/theme-switcher.sh tokyo-night

# Demo de temas
./modules/themes/demo.sh
```

---

## 🔧 Gestión del Sistema

### 📊 Información del Sistema

```bash
# Información general
./scripts/system/system-info.sh

# Diagnóstico completo
./diagnostico-sistema.sh

# Verificación del sistema
./verify-system.sh
```

### 🛠️ Mantenimiento

```bash
# Limpiar cache
./core/maintenance.sh cleanup

# Verificar dependencias
./bin/dream-deps check

# Actualizar módulos
./bin/dream-update

# Backup del sistema
./core/intelligent-backup.sh create
```

### 🔍 Logs y Debugging

```bash
# Ver logs en tiempo real
tail -f /tmp/hyprdream.log

# Estadísticas de logs
./core/logger.sh stats

# Limpiar logs antiguos
./core/logger.sh cleanup
```

---

## 🐛 Solución de Problemas

### ❗ Problemas Comunes

#### Error de Permisos
```bash
# Verificar permisos
ls -la install.sh
chmod +x install.sh

# Verificar usuario
whoami
groups
```

#### Dependencias Faltantes
```bash
# Verificar dependencias
./bin/dream-deps check

# Instalar dependencias faltantes
./bin/dream-deps install

# Actualizar repositorios
sudo pacman -Sy
```

#### Espacio Insuficiente
```bash
# Verificar espacio
./core/disk-checker.sh check

# Limpiar automáticamente
./core/disk-checker.sh cleanup

# Limpiar cache de pacman
sudo pacman -Sc
```

#### Problemas de Configuración
```bash
# Restaurar configuración base
./core/smart-config-manager.sh restore

# Verificar configuraciones
./verify-system.sh

# Backup antes de cambios
./core/intelligent-backup.sh create
```

### 📋 Checklist de Verificación

- [ ] Espacio en disco suficiente (>5GB)
- [ ] Permisos de escritura en /tmp
- [ ] Conectividad a internet
- [ ] Repositorios de Arch actualizados
- [ ] Dependencias críticas instaladas
- [ ] Scripts con permisos de ejecución
- [ ] Todas las pruebas pasan en verify-system.sh

---

## 📚 Documentación

### 📖 Guías Principales
- **[docs/INDEX.md](docs/INDEX.md)** - Índice completo de documentación
- **[README-ADVANCED.md](README-ADVANCED.md)** - Documentación avanzada
- **[docs/MODULES.md](docs/MODULES.md)** - Guía completa de módulos
- **[docs/INSTALL.md](docs/INSTALL.md)** - Instrucciones de instalación detalladas

### 🔧 Documentación Técnica
- **[docs/CHANGELOG.md](docs/CHANGELOG.md)** - Historial de cambios
- **[CORRECCIONES-IMPLEMENTADAS.md](CORRECCIONES-IMPLEMENTADAS.md)** - Registro de correcciones
- **README** de cada módulo - Documentación específica

### 🎯 Scripts de Verificación
- **[verify-system.sh](verify-system.sh)** - 15 pruebas automatizadas
- **[test-system.sh](test-system.sh)** - Tests de funcionalidad
- **[diagnostico-sistema.sh](diagnostico-sistema.sh)** - Diagnóstico completo
- **[check-basic.sh](check-basic.sh)** - Verificación básica

---

## 🤝 Contribuir

### 🚀 Cómo Contribuir

1. **Fork** el proyecto
2. **Crea** una rama para tu feature (`git checkout -b feature/AmazingFeature`)
3. **Commit** tus cambios (`git commit -m 'Add some AmazingFeature'`)
4. **Push** a la rama (`git push origin feature/AmazingFeature`)
5. **Abre** un Pull Request

### 📋 Guías de Contribución

- Usa el sistema de logging para mensajes
- Sigue las convenciones de bash scripting
- Documenta nuevas funciones
- Incluye tests cuando sea posible
- Verifica que `verify-system.sh` pase todas las pruebas

### 🐛 Reportar Bugs

- Usa el [sistema de Issues](https://github.com/Albert-fer02/hyprland-dream/issues)
- Incluye información del sistema (`./scripts/system/system-info.sh`)
- Adjunta logs relevantes (`/tmp/hyprdream.log`)
- Describe los pasos para reproducir el problema

---

## 📄 Licencia

Este proyecto está bajo la **Licencia MIT**. Ver el archivo `LICENSE` para más detalles.

```
MIT License

Copyright (c) 2024 Hyprland Dream

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.
```

---

## 🙏 Agradecimientos

### 🏗️ Desarrolladores
- **Comunidad de Hyprland** - Por el increíble window manager
- **Desarrolladores de Arch Linux** - Por la distribución base
- **Contribuidores de los paquetes** - Por las herramientas utilizadas

### 🎨 Temas y Diseño
- **Catppuccin** - Paleta de colores suave y elegante
- **Dracula** - Tema oscuro y moderno
- **Nord** - Paleta fría y minimalista
- **Tokyo Night** - Inspiración urbana y nocturna

### 🛠️ Herramientas
- **Waybar** - Barra de estado personalizable
- **Rofi** - Launcher y menús
- **Kitty** - Terminal emulator
- **Dunst/Mako** - Sistema de notificaciones

---

## 📞 Soporte

### 🌐 Enlaces Útiles
- **Issues**: [GitHub Issues](https://github.com/Albert-fer02/hyprland-dream/issues)
- **Discusiones**: [GitHub Discussions](https://github.com/Albert-fer02/hyprland-dream/discussions)
- **Wiki**: [Documentación detallada](https://github.com/Albert-fer02/hyprland-dream/wiki)

### 💬 Comunidad
- **Discord**: [Servidor de la comunidad](https://discord.gg/hyprland-dream)
- **Reddit**: [r/hyprland](https://reddit.com/r/hyprland)
- **Telegram**: [Canal de Hyprland](https://t.me/hyprland)

### 📧 Contacto
- **Email**: support@hyprland-dream.com
- **Twitter**: [@hyprland_dream](https://twitter.com/hyprland_dream)

---

<div align="center">

**¡Disfruta tu experiencia de Hyprland!** 🎉

[⬆️ Volver arriba](#-hyprland-dream-v10)

</div>
