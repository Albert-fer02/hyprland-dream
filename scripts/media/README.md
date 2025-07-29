# Sistema de Gestión Multimedia - Hyprland Dream

Sistema completo de gestión multimedia para Hyprland con soporte para múltiples reproductores, dispositivos de audio, notificaciones ricas y control avanzado.

## 🎵 Características Principales

### Control Universal de Multimedia
- **Soporte completo** para Spotify, YouTube Music, VLC, mpv, Firefox, Chromium
- **Notificaciones ricas** con covers de álbum y metadatos
- **Control unificado** con playerctl
- **Interfaz interactiva** con Rofi para selección de reproductores

### Gestión Avanzada de Audio
- **Múltiples dispositivos** de audio (Bluetooth, USB, HDMI, Jack 3.5mm)
- **Cambio automático** entre dispositivos
- **Normalización** de volumen entre dispositivos
- **Perfiles de audio** personalizables
- **Detección inteligente** de auriculares

### Auto-Pausa Inteligente
- **Detección automática** de desconexión de auriculares
- **Pausa automática** de reproducción
- **Reanudación opcional** al reconectar
- **Soporte múltiple** de tipos de auriculares

### Indicadores Visuales
- **OSD avanzado** con barras de progreso
- **Notificaciones contextuales** con información detallada
- **Integración Waybar** con módulos actualizados
- **Hotkeys multimedia** configurables

## 📁 Estructura de Archivos

```
scripts/media/
├── media-control.sh          # Control universal de multimedia
├── audio-device-switcher.sh  # Gestión de dispositivos de audio
├── volume-osd.sh            # Indicador visual de volumen
├── auto-pause-headphones.sh # Auto-pausa de auriculares
├── media-daemon.sh          # Daemon de monitoreo
├── multimedia-hotkeys.sh    # Sistema de hotkeys
└── README.md               # Esta documentación
```

## 🚀 Instalación y Configuración

### Dependencias Requeridas

```bash
# Dependencias principales
sudo pacman -S playerctl pamixer pulseaudio-alsa

# Dependencias opcionales
sudo pacman -S rofi jq wget

# Para notificaciones
sudo pacman -S mako  # o dunst
```

### Configuración Inicial

1. **Hacer ejecutables los scripts:**
```bash
chmod +x scripts/media/*.sh
```

2. **Crear directorios de configuración:**
```bash
mkdir -p ~/.config/hyprland-dream/media
mkdir -p ~/.cache/hyprland-dream/media
```

3. **Configurar hotkeys en Hyprland:**
```bash
# Agregar al archivo ~/.config/hyprland/hyprland.conf
```

## 🎮 Uso de los Scripts

### media-control.sh - Control Universal

```bash
# Control básico
./media-control.sh play-pause
./media-control.sh next
./media-control.sh previous
./media-control.sh stop

# Control de volumen
./media-control.sh volume-up
./media-control.sh volume-down
./media-control.sh volume-set 75

# Información y gestión
./media-control.sh info
./media-control.sh list-players
./media-control.sh switch-player

# Opciones avanzadas
./media-control.sh play-pause --player=spotify
./media-control.sh volume-up --step=10
./media-control.sh info --quiet
```

### audio-device-switcher.sh - Gestión de Dispositivos

```bash
# Listar dispositivos
./audio-device-switcher.sh list

# Cambiar dispositivo (interactivo)
./audio-device-switcher.sh switch

# Cambiar dispositivo específico
./audio-device-switcher.sh set-default --device=alsa_output.pci-0000_00_1f.3.analog-stereo

# Gestión Bluetooth
./audio-device-switcher.sh bluetooth list
./audio-device-switcher.sh bluetooth connect 00:11:22:33:44:55

# Perfiles de audio
./audio-device-switcher.sh profiles list
./audio-device-switcher.sh profiles set hdmi-stereo

# Normalización
./audio-device-switcher.sh normalize 50

# Monitoreo en tiempo real
./audio-device-switcher.sh monitor
```

### volume-osd.sh - Indicador Visual

```bash
# Control básico
./volume-osd.sh up
./volume-osd.sh down
./volume-osd.sh set 75
./volume-osd.sh toggle-mute

# Información
./volume-osd.sh get
./volume-osd.sh device-info

# Modo visual con barras
./volume-osd.sh up --visual
./volume-osd.sh set 50 --visual

# Perfiles
./volume-osd.sh profile save gaming
./volume-osd.sh profile load gaming
```

### auto-pause-headphones.sh - Auto-Pausa

```bash
# Monitoreo continuo
./auto-pause-headphones.sh monitor

# Verificar estado
./auto-pause-headphones.sh check

# Control manual
./auto-pause-headphones.sh pause
./auto-pause-headphones.sh resume

# Pruebas
./auto-pause-headphones.sh test

# Configuración
./auto-pause-headphones.sh config list-devices
./auto-pause-headphones.sh config save-config
```

### media-daemon.sh - Daemon de Monitoreo

```bash
# Control del daemon
./media-daemon.sh start
./media-daemon.sh stop
./media-daemon.sh restart
./media-daemon.sh status

# Modo monitor (sin daemon)
./media-daemon.sh monitor

# Configuración
./media-daemon.sh config show
./media-daemon.sh config create
```

### multimedia-hotkeys.sh - Hotkeys

```bash
# Control multimedia
./multimedia-hotkeys.sh play-pause
./multimedia-hotkeys.sh next
./multimedia-hotkeys.sh previous
./multimedia-hotkeys.sh stop

# Control de volumen
./multimedia-hotkeys.sh volume-up
./multimedia-hotkeys.sh volume-down
./multimedia-hotkeys.sh volume-mute

# Gestión de dispositivos
./multimedia-hotkeys.sh device-switch
./multimedia-hotkeys.sh player-switch

# Información
./multimedia-hotkeys.sh info
```

## ⌨️ Configuración de Hotkeys

### Hyprland (hyprland.conf)

```bash
# Control multimedia
bind = , XF86AudioPlay, exec, ~/scripts/media/multimedia-hotkeys.sh play-pause
bind = , XF86AudioNext, exec, ~/scripts/media/multimedia-hotkeys.sh next
bind = , XF86AudioPrev, exec, ~/scripts/media/multimedia-hotkeys.sh previous
bind = , XF86AudioStop, exec, ~/scripts/media/multimedia-hotkeys.sh stop

# Control de volumen
bind = , XF86AudioRaiseVolume, exec, ~/scripts/media/multimedia-hotkeys.sh volume-up
bind = , XF86AudioLowerVolume, exec, ~/scripts/media/multimedia-hotkeys.sh volume-down
bind = , XF86AudioMute, exec, ~/scripts/media/multimedia-hotkeys.sh volume-mute

# Gestión de dispositivos
bind = $mainMod, A, exec, ~/scripts/media/multimedia-hotkeys.sh device-switch
bind = $mainMod, P, exec, ~/scripts/media/multimedia-hotkeys.sh player-switch

# Hotkeys personalizadas
bind = $mainMod, M, exec, ~/scripts/media/media-control.sh info
bind = $mainMod SHIFT, M, exec, ~/scripts/media/media-daemon.sh status
```

### Sway/i3 (config)

```bash
# Control multimedia
bindsym XF86AudioPlay exec ~/scripts/media/multimedia-hotkeys.sh play-pause
bindsym XF86AudioNext exec ~/scripts/media/multimedia-hotkeys.sh next
bindsym XF86AudioPrev exec ~/scripts/media/multimedia-hotkeys.sh previous
bindsym XF86AudioStop exec ~/scripts/media/multimedia-hotkeys.sh stop

# Control de volumen
bindsym XF86AudioRaiseVolume exec ~/scripts/media/multimedia-hotkeys.sh volume-up
bindsym XF86AudioLowerVolume exec ~/scripts/media/multimedia-hotkeys.sh volume-down
bindsym XF86AudioMute exec ~/scripts/media/multimedia-hotkeys.sh volume-mute
```

## 🎨 Integración con Waybar

### Módulos Disponibles

1. **mpris** - Reproductor multimedia con metadatos
2. **pulseaudio** - Control de volumen y dispositivos
3. **multimedia-control** - Control rápido multimedia

### Configuración en config.json

```json
{
    "modules-right": [
        "custom/media-control",
        "pulseaudio",
        "mpris"
    ]
}
```

### Estilos CSS

```css
#custom-media-control {
    padding: 0 10px;
    margin: 0 5px;
    border-radius: 5px;
    background-color: rgba(0, 0, 0, 0.1);
}

#custom-media-control.playing {
    color: #98c379;
}

#custom-media-control.paused {
    color: #e5c07b;
}

#custom-media-control.stopped {
    color: #e06c75;
}

#custom-media-control.inactive {
    color: #5c6370;
}
```

## 🔧 Configuración Avanzada

### Variables de Entorno

```bash
# Configurar directorios personalizados
export HYPRLAND_DREAM_MEDIA_CACHE="$HOME/.cache/my-media"
export HYPRLAND_DREAM_MEDIA_CONFIG="$HOME/.config/my-media"

# Configurar reproductores preferidos
export PREFERRED_PLAYERS="spotify,vlc,mpv"

# Configurar dispositivos de audio preferidos
export PREFERRED_AUDIO_DEVICES="bluetooth,hdmi,analog"
```

### Archivos de Configuración

#### ~/.config/hyprland-dream/media/config.conf

```bash
# Configuración general
ENABLE_NOTIFICATIONS=true
NOTIFICATION_URGENCY=low
ENABLE_LOGGING=true
LOG_LEVEL=info

# Configuración de reproductores
MONITORED_PLAYERS=("spotify" "vlc" "mpv" "firefox" "chromium")
AUTO_SWITCH_PLAYERS=true

# Configuración de audio
AUTO_PAUSE_ON_HEADPHONE_DISCONNECT=true
AUTO_RESUME_ON_HEADPHONE_CONNECT=false
NORMALIZE_VOLUME_ON_DEVICE_SWITCH=true

# Configuración de notificaciones
SHOW_ALBUM_COVERS=true
NOTIFICATION_TIMEOUT=3000
```

#### ~/.config/hyprland-dream/audio/profiles.conf

```bash
# Perfiles de audio
[gaming]
volume=80
muted=false
devices=("hdmi-stereo" "analog-stereo")

[music]
volume=60
muted=false
devices=("bluetooth-headset" "analog-stereo")

[meeting]
volume=40
muted=false
devices=("usb-headset" "analog-stereo")
```

## 🐛 Solución de Problemas

### Problemas Comunes

1. **playerctl no encuentra reproductores**
   ```bash
   # Verificar que el reproductor esté ejecutándose
   playerctl -l
   
   # Verificar permisos D-Bus
   systemctl --user status dbus
   ```

2. **pamixer no funciona**
   ```bash
   # Verificar PulseAudio
   pactl info
   
   # Reiniciar PulseAudio
   pulseaudio --kill && pulseaudio --start
   ```

3. **Notificaciones no aparecen**
   ```bash
   # Verificar servidor de notificaciones
   systemctl --user status mako
   
   # Probar notificación manual
   notify-send "Test" "Mensaje de prueba"
   ```

4. **Auto-pausa no funciona**
   ```bash
   # Verificar detección de auriculares
   ./auto-pause-headphones.sh test
   
   # Verificar permisos de audio
   groups $USER | grep audio
   ```

### Logs y Debug

```bash
# Ver logs del sistema multimedia
tail -f ~/.cache/hyprland-dream/media/media-control.log
tail -f ~/.cache/hyprland-dream/audio/audio-switcher.log
tail -f ~/.cache/hyprland-dream/headphones/auto-pause.log

# Modo debug
./media-control.sh play-pause --debug
./audio-device-switcher.sh list --debug
```

## 📝 Ejemplos de Uso

### Script de Inicio Automático

```bash
#!/bin/bash
# ~/.config/hyprland/autostart.sh

# Iniciar daemon multimedia
~/scripts/media/media-daemon.sh start

# Iniciar monitoreo de auriculares
~/scripts/media/auto-pause-headphones.sh monitor &

# Configurar volumen inicial
~/scripts/media/volume-osd.sh set 50
```

### Script de Perfiles de Audio

```bash
#!/bin/bash
# ~/.local/bin/audio-profile

case "$1" in
    "gaming")
        ~/scripts/media/volume-osd.sh set 80
        ~/scripts/media/audio-device-switcher.sh set-default --device=hdmi-stereo
        ;;
    "music")
        ~/scripts/media/volume-osd.sh set 60
        ~/scripts/media/audio-device-switcher.sh set-default --device=bluetooth-headset
        ;;
    "meeting")
        ~/scripts/media/volume-osd.sh set 40
        ~/scripts/media/audio-device-switcher.sh set-default --device=usb-headset
        ;;
esac
```

## 🤝 Contribuciones

Para contribuir al sistema multimedia:

1. Fork del repositorio
2. Crear rama para tu feature
3. Implementar cambios
4. Probar exhaustivamente
5. Crear Pull Request

## 📄 Licencia

Este sistema multimedia es parte de Hyprland Dream y está bajo la misma licencia.

## 🙏 Agradecimientos

- **playerctl** - Control universal de multimedia
- **pamixer** - Control de volumen
- **pactl** - Control de PulseAudio
- **Rofi** - Interfaz de usuario
- **Waybar** - Barra de estado
- **Hyprland** - Compositor Wayland

---

**¡Disfruta de tu experiencia multimedia en Hyprland Dream!** 🎵 