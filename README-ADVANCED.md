# Hyprdream - Sistema de Instalación Avanzado v2.0

## 🚀 Características Principales

### 1. **Detección Automática de Hardware**
- Detección inteligente de CPU, GPU, memoria y almacenamiento
- Identificación automática de laptops vs desktops
- Detección de sensores de temperatura y brillo
- Recomendaciones automáticas basadas en hardware
- Soporte para múltiples GPUs (NVIDIA, AMD, Intel)

### 2. **Progress Bars Visuales**
- Barras de progreso atractivas y informativas
- Múltiples estilos: block, arrow, dots
- Progress bars específicas para cada tipo de operación
- Información detallada de progreso en tiempo real
- Soporte para descargas con progress bar

### 3. **Sistema de Rollback Automático**
- Backup automático antes de cada cambio
- Rollback inteligente en caso de errores
- Stack de operaciones para deshacer cambios
- Puntos de backup con metadatos
- Restauración automática del sistema

### 4. **Gestión Avanzada de Dependencias**
- Verificación automática de repos AUR
- Instalación automática de yay/paru
- Resolución inteligente de conflictos de paquetes
- Cache de paquetes optimizado
- Soporte para múltiples helpers AUR

### 5. **Post-Instalación Automática**
- Configuración automática de servicios systemd
- Setup de variables de entorno
- Generación de shortcuts de desktop
- First-run wizard interactivo
- Configuración de permisos y seguridad

### 6. **Sistema de Mantenimiento**
- Auto-updates de configuraciones
- Health checks del sistema
- Backup automático antes de cambios
- Cleanup de archivos temporales
- Reportes detallados de estado

## 📋 Requisitos del Sistema

- **Sistema Operativo**: Arch Linux
- **Arquitectura**: x86_64, ARM64
- **Memoria**: Mínimo 4GB RAM
- **Almacenamiento**: Mínimo 5GB libre
- **Permisos**: Usuario con sudo

## 🛠️ Instalación

### Instalación Básica
```bash
# Clonar el repositorio
git clone https://github.com/tu-usuario/hyprland-dream.git
cd hyprland-dream

# Ejecutar instalador
./install.sh
```

### Modos de Instalación

#### 1. **Modo Interactivo** (Recomendado)
```bash
./install.sh menu
```
- Menú completo con todas las opciones
- Selección interactiva de módulos
- Configuración paso a paso

#### 2. **Modo Automático**
```bash
./install.sh auto
```
- Instalación automática basada en hardware
- Selección automática de módulos recomendados
- Configuración automática completa

#### 3. **Modo Mínimo**
```bash
./install.sh minimal
```
- Instalación solo de componentes básicos
- Módulos esenciales: hypr, waybar, dunst

### Instalación de Módulos Específicos
```bash
# Instalar módulos específicos
./install.sh install hypr waybar dunst

# Instalar módulo individual
./install.sh install hypr
```

## 🎯 Funcionalidades Avanzadas

### Detección de Hardware
```bash
# Detectar hardware del sistema
./install.sh hardware

# Ver información detallada
./core/hardware-detector.sh detect

# Exportar información a JSON
./core/hardware-detector.sh export /tmp/hardware.json
```

### Gestión de Dependencias
```bash
# Verificar dependencias
./core/dependency-manager.sh check

# Instalar helper AUR
./core/dependency-manager.sh install-helper paru

# Gestionar cache
./core/dependency-manager.sh cache status
./core/dependency-manager.sh cache clean
./core/dependency-manager.sh cache update
```

### Sistema de Rollback
```bash
# Inicializar sistema de rollback
./core/rollback.sh init

# Listar puntos de backup
./core/rollback.sh list

# Restaurar desde backup
./core/rollback.sh restore initial

# Verificar integridad
./core/rollback.sh verify backup_name
```

### Post-Instalación
```bash
# Ejecutar post-instalación completa
./core/post-install.sh run

# Configurar servicios systemd
./core/post-install.sh services

# Configurar variables de entorno
./core/post-install.sh env

# Generar shortcuts de desktop
./core/post-install.sh shortcuts

# Ejecutar first-run wizard
./core/post-install.sh wizard
```

### Sistema de Mantenimiento
```bash
# Ejecutar mantenimiento completo
./core/maintenance.sh run

# Health checks del sistema
./core/maintenance.sh health

# Auto-update de configuraciones
./core/maintenance.sh update

# Cleanup de archivos temporales
./core/maintenance.sh cleanup

# Crear backup manual
./core/maintenance.sh backup manual
```

### Progress Bars
```bash
# Ver demostración de progress bars
./core/progress.sh demo

# Test de progress bars
./core/progress.sh test
```

## 📊 Reportes y Logs

### Generación de Reportes
```bash
# Reporte de dependencias
./core/dependency-manager.sh report

# Reporte de hardware
./core/hardware-detector.sh export

# Reporte de health check
./core/maintenance.sh report

# Reporte de post-instalación
./core/post-install.sh report
```

### Logs del Sistema
- **Log principal**: `/tmp/hyprdream.log`
- **Log de rollback**: `/tmp/hyprdream_rollback.log`
- **Log de health**: `/var/lib/hyprdream/maintenance/health.log`
- **Log de updates**: `/var/lib/hyprdream/maintenance/updates.log`
- **Log de cleanup**: `/var/lib/hyprdream/maintenance/cleanup.log`

## 🎮 Demostración

### Script de Demostración
```bash
# Ejecutar demostración completa
./demo-advanced.sh

# Demostraciones individuales
./demo-advanced.sh  # Menú interactivo
```

### Funcionalidades Demostradas
1. **Detección de Hardware**: Análisis completo del sistema
2. **Progress Bars**: Barras de progreso visuales
3. **Sistema de Rollback**: Backup y restauración
4. **Gestor de Dependencias**: Manejo de paquetes y AUR
5. **Post-Instalación**: Configuración automática
6. **Mantenimiento**: Health checks y cleanup

## ⚙️ Configuración

### Variables de Entorno
```bash
# Modo de instalación
export INSTALL_MODE="interactive"  # interactive, automated, minimal

# Nivel de logging
export LOG_LEVEL="INFO"  # DEBUG, INFO, WARN, ERROR, FATAL

# Backup automático
export BACKUP_BEFORE_INSTALL="true"

# Rollback automático
export AUTO_ROLLBACK="true"
```

### Configuración de Directorios
```bash
# Directorio de cache
export CACHE_DIR="/var/cache/hyprdream"

# Directorio de backup
export BACKUP_DIR="/tmp/hyprdream_backup"

# Directorio de mantenimiento
export MAINTENANCE_DIR="/var/lib/hyprdream/maintenance"
```

## 🔧 Módulos Disponibles

### Módulos Principales
- **hypr**: Configuración principal de Hyprland
- **waybar**: Barra de estado personalizable
- **dunst**: Sistema de notificaciones
- **kitty**: Terminal emulator
- **rofi**: Launcher de aplicaciones
- **swww**: Gestor de wallpapers
- **wlogout**: Menú de logout
- **swaylock**: Bloqueo de pantalla

### Módulos Opcionales
- **themes**: Temas y personalización
- **power-management**: Gestión de energía
- **media**: Control multimedia
- **fonts**: Fuentes personalizadas
- **zsh**: Configuración de shell

## 🚨 Solución de Problemas

### Errores Comunes

#### 1. **Error de Dependencias**
```bash
# Verificar dependencias del sistema
./core/dependency-manager.sh check

# Instalar dependencias faltantes
./core/dependency-manager.sh install base-devel git
```

#### 2. **Error de Permisos**
```bash
# Verificar permisos de usuario
sudo usermod -aG wheel $USER

# Configurar sudoers
echo "$USER ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/$USER
```

#### 3. **Error de Rollback**
```bash
# Listar puntos de backup disponibles
./core/rollback.sh list

# Restaurar desde backup específico
./core/rollback.sh restore backup_name
```

#### 4. **Error de Hardware**
```bash
# Verificar detección de hardware
./core/hardware-detector.sh detect

# Exportar información para debugging
./core/hardware-detector.sh export /tmp/debug_hardware.json
```

### Logs de Debug
```bash
# Habilitar logging detallado
export LOG_LEVEL="DEBUG"

# Ver logs en tiempo real
tail -f /tmp/hyprdream.log

# Ver logs de health check
cat /var/lib/hyprdream/maintenance/health.log
```

## 📈 Rendimiento y Optimización

### Optimización de Cache
```bash
# Limpiar cache de paquetes
./core/dependency-manager.sh cache clean

# Optimizar cache
./core/dependency-manager.sh cache optimize

# Actualizar cache
./core/dependency-manager.sh cache update
```

### Health Checks Regulares
```bash
# Ejecutar health check manual
./core/maintenance.sh health

# Programar health checks automáticos
# Agregar al crontab:
# 0 2 * * * /ruta/a/hyprland-dream/core/maintenance.sh health
```

## 🤝 Contribución

### Estructura del Proyecto
```
hyprland-dream/
├── core/                    # Componentes principales
│   ├── hardware-detector.sh # Detección de hardware
│   ├── progress.sh          # Progress bars
│   ├── rollback.sh          # Sistema de rollback
│   ├── dependency-manager.sh # Gestión de dependencias
│   ├── post-install.sh      # Post-instalación
│   └── maintenance.sh       # Sistema de mantenimiento
├── modules/                 # Módulos de instalación
├── lib/                     # Bibliotecas de utilidades
├── config/                  # Configuraciones
├── install.sh               # Instalador principal
└── demo-advanced.sh         # Script de demostración
```

### Agregar Nuevos Módulos
1. Crear directorio en `modules/nuevo-modulo/`
2. Implementar `install.sh` con funciones estándar
3. Agregar `README.md` con documentación
4. Actualizar dependencias en `config/dependencies.conf`

## 📄 Licencia

Este proyecto está bajo la licencia MIT. Ver el archivo `LICENSE` para más detalles.

## 🙏 Agradecimientos

- Comunidad de Arch Linux
- Desarrolladores de Hyprland
- Contribuidores del proyecto

---

**¡Disfruta de tu entorno Hyprland personalizado y optimizado! 🎉** 