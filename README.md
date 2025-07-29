# Hyprland Dream - Dotfiles Modulares

Un sistema modular de dotfiles para Hyprland en Arch Linux, diseñado con buenas prácticas de bash scripting y manejo de errores robusto.

## 🚀 Características

- **Sistema modular**: Cada componente tiene su propio módulo independiente
- **Logging avanzado**: Sistema de logging con rotación y diferentes niveles
- **Validación de dependencias**: Verificación robusta de paquetes y comandos
- **Scripts utilitarios**: Herramientas para gestión de sistema, media y workspaces
- **Configuraciones base**: Plantillas listas para usar
- **Soporte AUR**: Compatible con paru y yay

## 📁 Estructura del Proyecto

```
hyprland-dream/
├── bin/                    # Scripts ejecutables
│   ├── dream-setup        # Instalador principal
│   ├── dream-deps         # Gestor de dependencias
│   └── dream-uninstall    # Desinstalador
├── core/                   # Funciones core del sistema
│   ├── logger.sh          # Sistema de logging
│   ├── check-deps.sh      # Validación de dependencias
│   ├── colors.sh          # Colores para terminal
│   └── helpers.sh         # Funciones auxiliares
├── modules/               # Módulos de instalación
│   ├── hypr/             # Hyprland
│   ├── waybar/           # Barra de estado
│   ├── dunst/            # Notificaciones
│   ├── kitty/            # Terminal
│   ├── swww/             # Wallpaper
│   ├── rofi/             # Launcher
│   ├── mako/             # Notificaciones (alternativo)
│   ├── wlogout/          # Menú de logout
│   ├── swaylock/         # Bloqueo de pantalla
│   ├── fonts/            # Fuentes
│   └── themes/           # Temas
├── scripts/              # Scripts utilitarios
│   ├── system/           # Información del sistema
│   ├── media/            # Controles de media
│   └── workspace/        # Gestión de workspaces
├── config/               # Configuraciones
│   ├── templates/        # Plantillas base
│   └── dependencies.conf # Lista de dependencias
├── lib/                  # Bibliotecas
│   └── utils.sh          # Funciones utilitarias
└── docs/                 # Documentación
```

## 🛠️ Instalación

### Requisitos Previos

- Arch Linux (o derivados)
- Bash 4.0+
- sudo configurado

### Instalación Rápida

```bash
# Clonar el repositorio
git clone https://github.com/tu-usuario/hyprland-dream.git
cd hyprland-dream

# Ejecutar instalador
./install.sh
```

### Instalación Manual

```bash
# Verificar dependencias
./bin/dream-deps check

# Instalar dependencias faltantes
./bin/dream-deps install

# Instalar módulos específicos
./modules/hypr/install.sh
./modules/waybar/install.sh
```

## 📦 Módulos Disponibles

### Core
- **hypr**: Hyprland window manager
- **waybar**: Barra de estado
- **dunst**: Sistema de notificaciones
- **kitty**: Terminal emulator

### Utilidades
- **rofi**: Launcher y menús
- **mako**: Notificaciones (alternativo a dunst)
- **wlogout**: Menú de logout
- **swaylock**: Bloqueo de pantalla
- **swww**: Gestor de wallpapers

### Personalización
- **fonts**: Fuentes del sistema
- **themes**: Temas GTK e iconos

## 🔧 Uso

### Gestor de Dependencias

```bash
# Verificar dependencias
./bin/dream-deps check

# Instalar dependencias faltantes
./bin/dream-deps install

# Generar reporte
./bin/dream-deps report

# Limpiar cache
./bin/dream-deps clean
```

### Scripts Utilitarios

```bash
# Información del sistema
./scripts/system/system-info.sh

# Controles de media
./scripts/media/media-controls.sh

# Gestión de workspaces
./scripts/workspace/workspace-manager.sh
```

### Instalación de Módulos

```bash
# Instalar módulo completo
./modules/rofi/install.sh

# Solo configuración
./modules/waybar/install.sh
```

## ⚙️ Configuración

### Archivo de Dependencias

Edita `config/dependencies.conf` para personalizar las dependencias:

```ini
# Dependencias requeridas
REQUIRED=hyprland,waybar,dunst,kitty

# Dependencias opcionales
OPTIONAL=rofi,mako,wlogout,swaylock
```

### Variables de Entorno

```bash
# Nivel de logging (DEBUG, INFO, WARN, ERROR, FATAL)
export LOG_LEVEL=INFO

# Archivo de log personalizado
export LOG_FILE=/tmp/mi_hyprland.log

# Archivo de dependencias personalizado
export DEPS_FILE=/ruta/a/dependencias.conf
```

## 🐛 Solución de Problemas

### Logs

Los logs se guardan en `/tmp/hyprdream.log` por defecto:

```bash
# Ver logs en tiempo real
tail -f /tmp/hyprdream.log

# Ver estadísticas de logs
./core/logger.sh stats

# Limpiar logs antiguos
./core/logger.sh cleanup
```

### Dependencias

```bash
# Verificar estado de dependencias
./core/check-deps.sh check

# Generar reporte detallado
./core/check-deps.sh report > reporte.txt
```

### Problemas Comunes

1. **Error de permisos**: Asegúrate de que los scripts sean ejecutables
2. **Dependencias faltantes**: Usa `./bin/dream-deps install`
3. **Configuración corrupta**: Restaura desde `config/templates/`

## 🤝 Contribuir

1. Fork el proyecto
2. Crea una rama para tu feature (`git checkout -b feature/AmazingFeature`)
3. Commit tus cambios (`git commit -m 'Add some AmazingFeature'`)
4. Push a la rama (`git push origin feature/AmazingFeature`)
5. Abre un Pull Request

### Guías de Contribución

- Usa el sistema de logging para mensajes
- Sigue las convenciones de bash scripting
- Documenta nuevas funciones
- Incluye tests cuando sea posible

## 📄 Licencia

Este proyecto está bajo la Licencia MIT. Ver el archivo `LICENSE` para más detalles.

## 🙏 Agradecimientos

- Comunidad de Hyprland
- Desarrolladores de Arch Linux
- Contribuidores de los paquetes utilizados

## 📞 Soporte

- **Issues**: [GitHub Issues](https://github.com/tu-usuario/hyprland-dream/issues)
- **Discusiones**: [GitHub Discussions](https://github.com/tu-usuario/hyprland-dream/discussions)
- **Wiki**: [Documentación detallada](https://github.com/tu-usuario/hyprland-dream/wiki)

---

**¡Disfruta tu experiencia de Hyprland!** 🎉
