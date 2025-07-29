# 📖 Guía de Instalación - Hyprland Dream v1.0

Esta guía te ayudará a instalar Hyprland Dream v1.0 en tu sistema Arch Linux.

## 📋 Requisitos Previos

### Sistema Operativo
- **Arch Linux** (recomendado)
- **Derivados de Arch**: Manjaro, EndeavourOS, ArcoLinux
- **Otras distribuciones**: Puede requerir ajustes manuales

### Hardware Mínimo
- **RAM**: 4GB (8GB recomendado)
- **Almacenamiento**: 10GB de espacio libre
- **GPU**: Compatible con Wayland
- **CPU**: Procesador de 64 bits

### Software Requerido
- **Bash 4.0+**
- **sudo** configurado
- **git** instalado
- **Conectividad a internet**

## 🚀 Instalación Rápida

### ⚡ Método Automático (Recomendado)

```bash
# 1. Clonar el repositorio
git clone https://github.com/tu-usuario/hyprland-dream.git
cd hyprland-dream

# 2. Dar permisos de ejecución
chmod +x install.sh

# 3. Ejecutar instalador automático
./install.sh
```

El instalador automático:
- ✅ Detecta tu hardware automáticamente
- ✅ Verifica dependencias requeridas
- ✅ Instala todos los módulos necesarios
- ✅ Configura temas y personalizaciones
- ✅ Proporciona feedback visual del progreso

### 🎯 Método Selectivo

Si prefieres instalar solo módulos específicos:

```bash
# 1. Clonar el repositorio
git clone https://github.com/tu-usuario/hyprland-dream.git
cd hyprland-dream

# 2. Verificar dependencias
./bin/dream-deps check

# 3. Instalar módulos específicos
./modules/hypr/install.sh      # Hyprland (requerido)
./modules/waybar/install.sh    # Waybar
./modules/rofi/install.sh      # Rofi
./modules/kitty/install.sh     # Kitty
./modules/themes/install.sh    # Temas
```

### 🔧 Método Manual

Para usuarios avanzados que prefieren control total:

```bash
# 1. Instalar dependencias base
sudo pacman -S hyprland waybar dunst kitty rofi swww

# 2. Clonar configuraciones
git clone https://github.com/tu-usuario/hyprland-dream.git ~/.config/hyprland-dream

# 3. Crear enlaces simbólicos
ln -sf ~/.config/hyprland-dream/modules/hypr/config ~/.config/hypr
ln -sf ~/.config/hyprland-dream/modules/waybar/config ~/.config/waybar
ln -sf ~/.config/hyprland-dream/modules/rofi/config ~/.config/rofi
ln -sf ~/.config/hyprland-dream/modules/kitty/config ~/.config/kitty
ln -sf ~/.config/hyprland-dream/modules/dunst/config ~/.config/dunst

# 4. Instalar temas
./modules/themes/install.sh
```

## 📦 Módulos Disponibles

### 🎯 Core (Esenciales)
| Módulo | Descripción | Instalación |
|--------|-------------|-------------|
| **hypr** | Hyprland window manager | `./modules/hypr/install.sh` |
| **waybar** | Barra de estado | `./modules/waybar/install.sh` |
| **dunst** | Notificaciones | `./modules/dunst/install.sh` |
| **kitty** | Terminal | `./modules/kitty/install.sh` |

### 🛠️ Utilidades
| Módulo | Descripción | Instalación |
|--------|-------------|-------------|
| **rofi** | Launcher y menús | `./modules/rofi/install.sh` |
| **mako** | Notificaciones (alt) | `./modules/mako/install.sh` |
| **wlogout** | Menú de logout | `./modules/wlogout/install.sh` |
| **swaylock** | Bloqueo de pantalla | `./modules/swaylock/install.sh` |
| **swww** | Gestor de wallpapers | `./modules/swww/install.sh` |

### 🎨 Personalización
| Módulo | Descripción | Instalación |
|--------|-------------|-------------|
| **fonts** | Fuentes del sistema | `./modules/fonts/install.sh` |
| **themes** | Temas GTK e iconos | `./modules/themes/install.sh` |
| **power-management** | Gestión de energía | `./modules/power-management/install.sh` |
| **media** | Controles multimedia | `./modules/media/install.sh` |

## 🎨 Configuración de Temas

### Cambio de Temas

```bash
# Listar temas disponibles
./modules/themes/theme-switcher.sh list

# Cambiar a tema específico
./modules/themes/theme-switcher.sh catppuccin
./modules/themes/theme-switcher.sh dracula
./modules/themes/theme-switcher.sh nord
./modules/themes/theme-switcher.sh tokyo-night

# Demo de temas
./modules/themes/demo.sh
```

### Temas Disponibles

#### 🌸 Catppuccin
- **Colores**: Paleta suave y elegante
- **Estilo**: Moderno y minimalista
- **Wallpapers**: Incluidos en el tema

#### 🌙 Dracula
- **Colores**: Oscuro y contrastante
- **Estilo**: Elegante y profesional
- **Wallpapers**: Temáticos oscuros

#### ❄️ Nord
- **Colores**: Paleta fría y relajante
- **Estilo**: Minimalista y limpio
- **Wallpapers**: Paisajes nórdicos

#### 🌃 Tokyo Night
- **Colores**: Inspirado en la noche de Tokio
- **Estilo**: Moderno y vibrante
- **Wallpapers**: Urbanos y nocturnos

## 🎮 Configuración Post-Instalación

### Iniciar Hyprland

```bash
# Desde terminal
hyprland

# O configurar para iniciar automáticamente
echo "exec hyprland" >> ~/.xinitrc
```

### Atajos de Teclado Principales

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

### Configuración de Audio

```bash
# Verificar dispositivos de audio
pactl list short sinks

# Cambiar dispositivo de audio
./scripts/media/audio-device-switcher.sh

# Configurar volumen
./scripts/media/volume.sh up
./scripts/media/volume.sh down
./scripts/media/volume.sh mute
```

## 🛠️ Herramientas de Gestión

### Información del Sistema

```bash
# Información general
./scripts/system/system-info.sh

# Diagnóstico completo
./diagnostico-sistema.sh

# Verificación del sistema
./verify-system.sh
```

### Mantenimiento

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

### Logs y Debugging

```bash
# Ver logs en tiempo real
tail -f /tmp/hyprdream.log

# Estadísticas de logs
./core/logger.sh stats

# Limpiar logs antiguos
./core/logger.sh cleanup
```

## 🐛 Solución de Problemas

### Problemas Comunes

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

### Checklist de Verificación

- [ ] Espacio en disco suficiente (>5GB)
- [ ] Permisos de escritura en /tmp
- [ ] Conectividad a internet
- [ ] Repositorios de Arch actualizados
- [ ] Dependencias críticas instaladas
- [ ] Scripts con permisos de ejecución
- [ ] Todas las pruebas pasan en verify-system.sh

## 📚 Recursos Adicionales

### Documentación
- **[README.md](../README.md)**: Guía principal
- **[README-ADVANCED.md](../README-ADVANCED.md)**: Documentación avanzada
- **[CONFIGURATION.md](CONFIGURATION.md)**: Guía de configuración
- **[CHANGELOG.md](CHANGELOG.md)**: Historial de cambios

### Comunidad
- **GitHub Issues**: [Reportar problemas](https://github.com/tu-usuario/hyprland-dream/issues)
- **GitHub Discussions**: [Discusiones](https://github.com/tu-usuario/hyprland-dream/discussions)
- **Wiki**: [Documentación detallada](https://github.com/tu-usuario/hyprland-dream/wiki)

### Enlaces Útiles
- **Hyprland**: [Documentación oficial](https://wiki.hyprland.org/)
- **Arch Linux**: [Wiki oficial](https://wiki.archlinux.org/)
- **Wayland**: [Documentación](https://wayland.freedesktop.org/)

## 🎉 ¡Listo!

¡Felicidades! Has instalado exitosamente Hyprland Dream v1.0. 

### Próximos Pasos
1. **Reinicia tu sistema** o inicia sesión en Hyprland
2. **Explora los temas** disponibles
3. **Personaliza** tu configuración según tus preferencias
4. **Únete a la comunidad** para obtener ayuda y compartir experiencias

### Soporte
Si encuentras algún problema:
1. Revisa la sección de [Solución de Problemas](#-solución-de-problemas)
2. Consulta la [documentación](../README.md)
3. Busca en [GitHub Issues](https://github.com/tu-usuario/hyprland-dream/issues)
4. Únete a las [discusiones](https://github.com/tu-usuario/hyprland-dream/discussions)

---

**¡Disfruta tu nueva experiencia de Hyprland!** 🎉

*Hyprland Dream v1.0 - Lanzamiento Inicial*
