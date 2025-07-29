#!/usr/bin/env bash
# Theme Switcher para Hyprland Dream
# Sistema de temas coherente e intercambiable

set -e

SCRIPT_DIR="$(dirname "$0")"
ROOT_DIR="$SCRIPT_DIR/../.."
source "$ROOT_DIR/lib/utils.sh"
source "$ROOT_DIR/core/logger.sh"

init_logger

# Configuración
THEMES_DIR="$SCRIPT_DIR/themes"
CONFIG_DIR="$HOME/.config"
BACKUP_DIR="$HOME/.config/hyprdream-themes-backup"
CACHE_DIR="$HOME/.cache/hyprdream-themes"
CURRENT_THEME_FILE="$CONFIG_DIR/hyprdream/current-theme.conf"

# Temas disponibles
AVAILABLE_THEMES=("nord" "dracula" "catppuccin" "tokyo-night" "custom")

# Función para cargar configuración de tema
load_theme_config() {
    local theme_name="$1"
    local theme_file="$THEMES_DIR/$theme_name/colors.conf"
    
    if [[ ! -f "$theme_file" ]]; then
        log_error "Tema '$theme_name' no encontrado en $theme_file"
        return 1
    fi
    
    # Cargar variables del archivo de configuración
    source "$theme_file"
    log_info "Configuración del tema '$theme_name' cargada"
}

# Función para crear backup de configuración actual
create_backup() {
    log_info "Creando backup de configuración actual..."
    
    mkdir -p "$BACKUP_DIR"
    local timestamp=$(date +"%Y%m%d_%H%M%S")
    local backup_path="$BACKUP_DIR/backup_$timestamp"
    
    mkdir -p "$backup_path"
    
    # Backup de archivos de configuración
    local config_files=(
        "$CONFIG_DIR/hypr/hyprland.conf"
        "$CONFIG_DIR/waybar/style.css"
        "$CONFIG_DIR/rofi/colors.rasi"
        "$CONFIG_DIR/kitty/kitty.conf"
        "$CONFIG_DIR/dunst/dunstrc"
        "$CONFIG_DIR/mako/config"
    )
    
    for file in "${config_files[@]}"; do
        if [[ -f "$file" ]]; then
            cp "$file" "$backup_path/"
            log_debug "Backup creado: $file"
        fi
    done
    
    log_ok "Backup creado en: $backup_path"
    echo "$backup_path"
}

# Función para restaurar backup
restore_backup() {
    local backup_path="$1"
    
    if [[ ! -d "$backup_path" ]]; then
        log_error "Backup no encontrado: $backup_path"
        return 1
    fi
    
    log_info "Restaurando backup desde: $backup_path"
    
    # Restaurar archivos
    for file in "$backup_path"/*; do
        if [[ -f "$file" ]]; then
            local filename=$(basename "$file")
            local target_file=""
            
            case "$filename" in
                "hyprland.conf") target_file="$CONFIG_DIR/hypr/hyprland.conf" ;;
                "style.css") target_file="$CONFIG_DIR/waybar/style.css" ;;
                "colors.rasi") target_file="$CONFIG_DIR/rofi/colors.rasi" ;;
                "kitty.conf") target_file="$CONFIG_DIR/kitty/kitty.conf" ;;
                "dunstrc") target_file="$CONFIG_DIR/dunst/dunstrc" ;;
                "config") target_file="$CONFIG_DIR/mako/config" ;;
            esac
            
            if [[ -n "$target_file" ]]; then
                cp "$file" "$target_file"
                log_debug "Restaurado: $target_file"
            fi
        fi
    done
    
    log_ok "Backup restaurado exitosamente"
}

# Función para aplicar tema a Hyprland
apply_hyprland_theme() {
    local theme_name="$1"
    log_info "Aplicando tema '$theme_name' a Hyprland..."
    
    # Crear archivo de configuración de tema para Hyprland
    local hypr_theme_file="$CONFIG_DIR/hypr/theme.conf"
    
    cat > "$hypr_theme_file" << EOF
# Tema: $theme_name
# Generado automáticamente por Hyprland Dream Theme Switcher

# Colores de ventana
\$background = $BACKGROUND
\$background-alt = $BACKGROUND_ALT
\$foreground = $FOREGROUND
\$accent = $ACCENT_PRIMARY
\$border = $BORDER
\$border-focus = $BORDER_FOCUS

# Configuración de decoración
decoration {
    # Blur
    blur = true
    blur-size = 8
    blur-passes = $BLUR_PASSES
    blur-strength = $BLUR_STRENGTH
    
    # Sombras
    drop-shadow = true
    shadow-color = $SHADOW_HEAVY
    shadow-range = 4
    shadow-render-power = 3
}

# Colores de ventana
windowrulev2 = opacity $TRANSPARENCY_LEVEL,class:^(.*)$

# Colores de borde
general {
    border_size = 2
    col.active_border = $BORDER_FOCUS
    col.inactive_border = $BORDER
}

# Colores de fondo
misc {
    background_color = $BACKGROUND
    force_default_wallpaper = 0
}
EOF
    
    log_ok "Tema aplicado a Hyprland"
}

# Función para aplicar tema a Waybar
apply_waybar_theme() {
    local theme_name="$1"
    log_info "Aplicando tema '$theme_name' a Waybar..."
    
    local waybar_style="$CONFIG_DIR/waybar/style.css"
    
    # Crear CSS con variables del tema
    cat > "$waybar_style" << EOF
/* Tema: $theme_name */
/* Generado automáticamente por Hyprland Dream Theme Switcher */

@import 'themes/$theme_name.css';

* {
    border: none;
    border-radius: 0;
    font-family: "JetBrainsMono Nerd Font", "Font Awesome 6 Free", sans-serif;
    font-size: 12px;
    min-height: 0;
}

window#waybar {
    background-color: $BACKGROUND_TRANSPARENT;
    border-bottom: 2px solid $BORDER;
    color: $TEXT_PRIMARY;
    transition-property: background-color;
    transition-duration: .5s;
}

window#waybar.hidden {
    opacity: 0.2;
}

#workspaces button {
    padding: 0 5px;
    background-color: transparent;
    color: $TEXT_SECONDARY;
    border-bottom: 3px solid transparent;
}

#workspaces button:hover {
    background: $BACKGROUND_ALT;
    box-shadow: inherit;
    text-shadow: inherit;
}

#workspaces button.active {
    background-color: $ACCENT_PRIMARY;
    color: $BACKGROUND;
    border-bottom: 3px solid $TEXT_PRIMARY;
}

#workspaces button.urgent {
    background-color: $ERROR;
    color: $BACKGROUND;
}

#mode {
    background-color: $ACCENT_SECONDARY;
    border-bottom: 3px solid $TEXT_PRIMARY;
}

#clock,
#battery,
#cpu,
#memory,
#disk,
#temperature,
#backlight,
#network,
#pulseaudio,
#wireplumber,
#custom-media,
#tray,
#mode,
#idle_inhibitor,
#scratchpad,
#mpd {
    padding: 0 10px;
    margin: 0 4px;
    color: $TEXT_PRIMARY;
}

#window,
#workspaces {
    margin: 0 4px;
}

.modules-left > widget:first-child > #workspaces {
    margin-left: 0;
}

.modules-right > widget:last-child > #workspaces {
    margin-right: 0;
}

#battery.charging, #battery.plugged {
    color: $SUCCESS;
    background-color: $BACKGROUND_ALT;
}

@keyframes blink {
    to {
        background-color: $ERROR;
        color: $BACKGROUND;
    }
}

#battery.critical:not(.charging) {
    background-color: $ERROR;
    color: $BACKGROUND;
    animation-name: blink;
    animation-duration: 0.5s;
    animation-timing-function: linear;
    animation-iteration-count: infinite;
    animation-direction: alternate;
}

label:focus {
    background-color: $BACKGROUND;
}

#network.disconnected {
    background-color: $ERROR;
}

#pulseaudio.muted {
    background-color: $WARNING;
}

#wireplumber {
    background-color: $BACKGROUND_ALT;
}

#wireplumber.muted {
    background-color: $ERROR;
}

#custom-media {
    background-color: $ACCENT_TERTIARY;
    color: $BACKGROUND;
    min-width: 100px;
}

#custom-media.custom-spotify {
    background-color: $SUCCESS;
}

#custom-media.custom-vlc {
    background-color: $ACCENT_PRIMARY;
}

#temperature.critical {
    background-color: $ERROR;
}

#tray > .passive {
    -gtk-icon-effect: dim;
}

#tray > .needs-attention {
    -gtk-icon-effect: highlight;
    background-color: $WARNING;
}

#idle_inhibitor.activated {
    background-color: $TEXT_PRIMARY;
    color: $BACKGROUND;
}

#scratchpad {
    background: $BACKGROUND_ALT;
}

#scratchpad.empty {
    background-color: transparent;
}
EOF
    
    log_ok "Tema aplicado a Waybar"
}

# Función para aplicar tema a Rofi
apply_rofi_theme() {
    local theme_name="$1"
    log_info "Aplicando tema '$theme_name' a Rofi..."
    
    local rofi_colors="$CONFIG_DIR/rofi/colors.rasi"
    
    cat > "$rofi_colors" << EOF
/* Tema: $theme_name */
/* Generado automáticamente por Hyprland Dream Theme Switcher */

* {
    bg: $BACKGROUND_TRANSPARENT;
    bg-alt: $BACKGROUND_ALT;
    fg: $TEXT_PRIMARY;
    fg-alt: $TEXT_SECONDARY;
    
    border: 0;
    margin: 0;
    padding: 0;
    spacing: 0;
}

window {
    width: 800px;
    background-color: @bg;
    border: 2px solid $BORDER_FOCUS;
    border-radius: 8px;
}

element {
    padding: 8px 16px;
    background-color: transparent;
    text-color: @fg;
}

element.normal.normal {
    background-color: transparent;
    text-color: @fg;
}

element.normal.urgent {
    background-color: $ERROR;
    text-color: $BACKGROUND;
}

element.normal.active {
    background-color: $ACCENT_PRIMARY;
    text-color: $BACKGROUND;
}

element.selected.normal {
    background-color: $ACCENT_PRIMARY;
    text-color: $BACKGROUND;
}

element.selected.urgent {
    background-color: $ERROR;
    text-color: $BACKGROUND;
}

element.selected.active {
    background-color: $ACCENT_SECONDARY;
    text-color: $BACKGROUND;
}

element.alternate.normal {
    background-color: transparent;
    text-color: @fg-alt;
}

element.alternate.urgent {
    background-color: $ERROR;
    text-color: $BACKGROUND;
}

element.alternate.active {
    background-color: $ACCENT_TERTIARY;
    text-color: $BACKGROUND;
}

listview {
    background-color: transparent;
    columns: 2;
    lines: 8;
    spacing: 2px;
    scrollbar: false;
}

textbox {
    padding: 8px 16px;
    background-color: transparent;
    text-color: @fg;
    vertical-align: 0.5;
}

textbox-prompt-colon {
    expand: false;
    str: ":";
    margin-right: 8px;
    text-color: @fg-alt;
}

entry {
    padding: 8px 16px;
    background-color: $BACKGROUND_ALT;
    text-color: @fg;
    placeholder-color: @fg-alt;
}

inputbar {
    children: [prompt, textbox-prompt-colon, entry, case-indicator];
    background-color: transparent;
}

case-indicator {
    padding: 8px 16px;
    background-color: transparent;
    text-color: @fg-alt;
}

listview {
    background-color: transparent;
    spacing: 2px;
    scrollbar: true;
    scrollbar-width: 4px;
    scrollbar-color: $ACCENT_PRIMARY;
}

scrollbar {
    handle-color: $ACCENT_PRIMARY;
    handle-width: 4px;
    border-radius: 2px;
}

mode-switcher {
    background-color: transparent;
}

button {
    padding: 8px 16px;
    background-color: transparent;
    text-color: @fg;
    vertical-align: 0.5;
}

button selected {
    background-color: $ACCENT_PRIMARY;
    text-color: $BACKGROUND;
}

message {
    background-color: transparent;
    margin: 8px;
    padding: 8px;
    border-radius: 4px;
    text-color: @fg;
}

textbox {
    background-color: transparent;
    text-color: @fg;
    vertical-align: 0.5;
}

error-message {
    background-color: $ERROR;
    text-color: $BACKGROUND;
    margin: 8px;
    padding: 8px;
    border-radius: 4px;
}
EOF
    
    log_ok "Tema aplicado a Rofi"
}

# Función para aplicar tema a Kitty
apply_kitty_theme() {
    local theme_name="$1"
    log_info "Aplicando tema '$theme_name' a Kitty..."
    
    local kitty_conf="$CONFIG_DIR/kitty/kitty.conf"
    
    # Crear archivo de configuración de tema para Kitty
    cat > "$kitty_conf" << EOF
# Tema: $theme_name
# Generado automáticamente por Hyprland Dream Theme Switcher

# Configuración básica
font_family JetBrainsMono Nerd Font
font_size 12
bold_font auto
italic_font auto
bold_italic_font auto

# Colores del tema
background $BACKGROUND
foreground $FOREGROUND
selection_background $ACCENT_PRIMARY
selection_foreground $BACKGROUND
url_color $ACCENT_SECONDARY
cursor $ACCENT_PRIMARY

# Colores de la terminal
color0 $BACKGROUND_ALT
color1 $ERROR
color2 $SUCCESS
color3 $WARNING
color4 $ACCENT_PRIMARY
color5 $ACCENT_SECONDARY
color6 $ACCENT_TERTIARY
color7 $FOREGROUND_ALT
color8 $BACKGROUND_DIM
color9 $ERROR
color10 $SUCCESS
color11 $WARNING
color12 $ACCENT_PRIMARY
color13 $ACCENT_SECONDARY
color14 $ACCENT_TERTIARY
color15 $FOREGROUND

# Configuración de ventana
window_padding_width 8
window_margin_width 0
background_opacity 0.9
background_blur 1

# Configuración de pestañas
tab_bar_style powerline
tab_bar_min_tabs 2
tab_bar_edge bottom
tab_bar_align left
tab_powerline_style slanted
tab_title_template "{index}: {title}"

# Configuración de teclas
map ctrl+shift+equal change_font_size all +1.0
map ctrl+shift+minus change_font_size all -1.0
map ctrl+shift+0 change_font_size all 0

# Configuración de scrollback
scrollback_lines 10000
scrollback_pager_history_size 10000

# Configuración de copia/pega
copy_on_select yes
strip_trailing_spaces smart

# Configuración de cursor
cursor_shape beam
cursor_blink_interval 0.5
cursor_stop_blinking_after 15.0

# Configuración de enlaces
detect_urls yes
url_style double
open_url_with default
copy_on_select yes

# Configuración de shell
shell_integration enabled
EOF
    
    log_ok "Tema aplicado a Kitty"
}

# Función para aplicar tema a Dunst/Mako
apply_notification_theme() {
    local theme_name="$1"
    log_info "Aplicando tema '$theme_name' a notificaciones..."
    
    # Configurar Dunst
    if [[ -d "$CONFIG_DIR/dunst" ]]; then
        local dunst_conf="$CONFIG_DIR/dunst/dunstrc"
        
        cat > "$dunst_conf" << EOF
# Tema: $theme_name
# Generado automáticamente por Hyprland Dream Theme Switcher

[global]
    # Configuración básica
    monitor = 0
    follow = mouse
    geometry = "300x5-30+20"
    indicate_hidden = yes
    shrink = no
    transparency = 20
    notification_height = 0
    separator_height = 2
    padding = 8
    horizontal_padding = 8
    frame_width = 3
    frame_color = "$BORDER_FOCUS"
    separator_color = frame
    sort = yes
    idle_threshold = 120
    font = JetBrainsMono Nerd Font 10
    line_height = 0
    markup = full
    format = "<b>%s</b>\n%b"
    alignment = left
    show_age_threshold = 60
    word_wrap = yes
    ellipsize = middle
    ignore_newline = no
    stack_duplicates = true
    hide_duplicate_count = false
    show_indicators = yes
    icon_position = left
    max_icon_size = 80
    icon_path = /usr/share/icons/gnome/16x16/status/:/usr/share/icons/gnome/16x16/devices/
    sticky_history = yes
    history_length = 20
    always_run_script = true
    title = Dunst
    class = Dunst
    startup_notification = false
    verbosity = mesg
    corner_radius = 8

[shortcuts]
    close = ctrl+space
    close_all = ctrl+shift+space
    history = ctrl+grave
    context = ctrl+shift+period

[urgency_low]
    background = "$BACKGROUND_TRANSPARENT"
    foreground = "$TEXT_PRIMARY"
    frame_color = "$BORDER"
    timeout = 4

[urgency_normal]
    background = "$BACKGROUND_TRANSPARENT"
    foreground = "$TEXT_PRIMARY"
    frame_color = "$BORDER_FOCUS"
    timeout = 6

[urgency_critical]
    background = "$ERROR"
    foreground = "$BACKGROUND"
    frame_color = "$ERROR"
    timeout = 0
EOF
    fi
    
    # Configurar Mako
    if [[ -d "$CONFIG_DIR/mako" ]]; then
        local mako_conf="$CONFIG_DIR/mako/config"
        
        cat > "$mako_conf" << EOF
# Tema: $theme_name
# Generado automáticamente por Hyprland Dream Theme Switcher

# Configuración básica
default-timeout=5000
sort=-time
output=HDMI-A-1

# Colores del tema
background-color=$BACKGROUND_TRANSPARENT
text-color=$TEXT_PRIMARY
border-color=$BORDER_FOCUS
progress-color=$ACCENT_PRIMARY

# Configuración de notificaciones
group-by=app-name
max-visible=5
layer=overlay
anchor=top-right
margin=10,10
padding=8
border-width=2
border-radius=8
font=JetBrainsMono Nerd Font 10
EOF
    fi
    
    log_ok "Tema aplicado a notificaciones"
}

# Función para sincronizar con wallpapers usando swww
sync_wallpapers() {
    local theme_name="$1"
    log_info "Sincronizando wallpapers para el tema '$theme_name'..."
    
    local wallpaper_dir="$THEMES_DIR/$theme_name/wallpapers"
    
    if [[ -d "$wallpaper_dir" ]]; then
        # Obtener lista de wallpapers
        local wallpapers=($(find "$wallpaper_dir" -type f \( -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" -o -name "*.webp" \)))
        
        if [[ ${#wallpapers[@]} -gt 0 ]]; then
            # Seleccionar wallpaper aleatorio
            local random_wallpaper="${wallpapers[$RANDOM % ${#wallpapers[@]}]}"
            
            # Aplicar wallpaper con swww
            if command -v swww >/dev/null 2>&1; then
                swww img "$random_wallpaper" --transition-type wipe --transition-duration 1
                log_ok "Wallpaper aplicado: $(basename "$random_wallpaper")"
            else
                log_warn "swww no está instalado, no se puede aplicar wallpaper"
            fi
        else
            log_warn "No se encontraron wallpapers en $wallpaper_dir"
        fi
    else
        log_warn "Directorio de wallpapers no encontrado: $wallpaper_dir"
    fi
}

# Función para mostrar preview del tema
show_theme_preview() {
    local theme_name="$1"
    log_info "Mostrando preview del tema '$theme_name'..."
    
    # Crear preview temporal
    local preview_dir="$CACHE_DIR/preview"
    mkdir -p "$preview_dir"
    
    # Generar imagen de preview
    local preview_file="$preview_dir/${theme_name}_preview.png"
    
    # Usar feh o similar para mostrar preview
    if command -v feh >/dev/null 2>&1; then
        # Crear preview simple con los colores del tema
        load_theme_config "$theme_name"
        
        # Crear imagen de preview usando ImageMagick si está disponible
        if command -v convert >/dev/null 2>&1; then
            convert -size 800x600 xc:"$BACKGROUND" \
                    -fill "$ACCENT_PRIMARY" -draw "rectangle 50,50 750,100" \
                    -fill "$TEXT_PRIMARY" -pointsize 24 -annotate +60+80 "Tema: $theme_name" \
                    -fill "$TEXT_SECONDARY" -pointsize 16 -annotate +60+120 "Colores principales: $BACKGROUND, $ACCENT_PRIMARY, $TEXT_PRIMARY" \
                    "$preview_file"
            
            feh "$preview_file" &
            log_ok "Preview mostrado"
        else
            log_warn "ImageMagick no está instalado, no se puede generar preview"
        fi
    else
        log_warn "feh no está instalado, no se puede mostrar preview"
    fi
}

# Función para programar cambio automático de temas
schedule_theme_change() {
    local day_theme="$1"
    local night_theme="$2"
    
    log_info "Programando cambio automático de temas..."
    
    # Crear script de cambio automático
    local auto_script="$CONFIG_DIR/hyprdream/auto-theme-switcher.sh"
    
    cat > "$auto_script" << EOF
#!/usr/bin/env bash
# Cambio automático de temas día/noche

DAY_THEME="$day_theme"
NIGHT_THEME="$night_theme"
SCRIPT_DIR="$SCRIPT_DIR"

# Función para obtener hora actual
get_current_hour() {
    date +%H
}

# Función para cambiar tema
change_theme() {
    local theme="\$1"
    "$SCRIPT_DIR/theme-switcher.sh" apply "\$theme" --no-preview
}

# Obtener hora actual
current_hour=\$(get_current_hour)

# Determinar tema basado en la hora
if [[ \$current_hour -ge 6 && \$current_hour -lt 18 ]]; then
    # Día (6:00 - 17:59)
    change_theme "\$DAY_THEME"
else
    # Noche (18:00 - 5:59)
    change_theme "\$NIGHT_THEME"
fi
EOF
    
    chmod +x "$auto_script"
    
    # Crear servicio systemd para ejecutar cada hora
    local service_file="$HOME/.config/systemd/user/auto-theme-switcher.service"
    local timer_file="$HOME/.config/systemd/user/auto-theme-switcher.timer"
    
    mkdir -p "$(dirname "$service_file")"
    
    cat > "$service_file" << EOF
[Unit]
Description=Auto Theme Switcher
After=graphical-session.target

[Service]
Type=oneshot
ExecStart=$auto_script
Environment=DISPLAY=:0

[Install]
WantedBy=graphical-session.target
EOF
    
    cat > "$timer_file" << EOF
[Unit]
Description=Auto Theme Switcher Timer
Requires=auto-theme-switcher.service

[Timer]
OnCalendar=hourly
Persistent=true

[Install]
WantedBy=timers.target
EOF
    
    # Habilitar y iniciar el timer
    systemctl --user enable auto-theme-switcher.timer
    systemctl --user start auto-theme-switcher.timer
    
    log_ok "Cambio automático de temas programado (día: $day_theme, noche: $night_theme)"
}

# Función para aplicar tema completo
apply_theme() {
    local theme_name="$1"
    local show_preview="${2:-true}"
    local sync_wallpaper="${3:-true}"
    
    log_info "Aplicando tema: $theme_name"
    
    # Crear backup antes de aplicar
    local backup_path=$(create_backup)
    
    # Cargar configuración del tema
    if ! load_theme_config "$theme_name"; then
        return 1
    fi
    
    # Aplicar tema a todos los componentes
    apply_hyprland_theme "$theme_name"
    apply_waybar_theme "$theme_name"
    apply_rofi_theme "$theme_name"
    apply_kitty_theme "$theme_name"
    apply_notification_theme "$theme_name"
    
    # Sincronizar wallpapers si se solicita
    if [[ "$sync_wallpaper" == "true" ]]; then
        sync_wallpapers "$theme_name"
    fi
    
    # Mostrar preview si se solicita
    if [[ "$show_preview" == "true" ]]; then
        show_theme_preview "$theme_name"
    fi
    
    # Guardar tema actual
    echo "CURRENT_THEME=$theme_name" > "$CURRENT_THEME_FILE"
    echo "APPLIED_AT=$(date)" >> "$CURRENT_THEME_FILE"
    
    # Recargar componentes
    log_info "Recargando componentes..."
    
    # Recargar Hyprland
    if command -v hyprctl >/dev/null 2>&1; then
        hyprctl reload
    fi
    
    # Recargar Waybar
    if pgrep waybar >/dev/null; then
        waybar-msg cmd reload
    fi
    
    # Recargar Dunst
    if pgrep dunst >/dev/null; then
        pkill dunst && dunst &
    fi
    
    log_ok "Tema '$theme_name' aplicado exitosamente"
    log_info "Backup guardado en: $backup_path"
}

# Función para listar temas disponibles
list_themes() {
    echo -e "\n${CYAN}Temas disponibles:${RESET}"
    for theme in "${AVAILABLE_THEMES[@]}"; do
        local theme_file="$THEMES_DIR/$theme/colors.conf"
        if [[ -f "$theme_file" ]]; then
            echo "  ✓ $theme"
        else
            echo "  ✗ $theme (no configurado)"
        fi
    done
    echo
}

# Función para mostrar tema actual
show_current_theme() {
    if [[ -f "$CURRENT_THEME_FILE" ]]; then
        source "$CURRENT_THEME_FILE"
        echo -e "\n${CYAN}Tema actual:${RESET} $CURRENT_THEME"
        echo -e "${CYAN}Aplicado:${RESET} $APPLIED_AT"
    else
        echo -e "\n${YELLOW}No hay tema aplicado actualmente${RESET}"
    fi
    echo
}

# Función para crear tema personalizado
create_custom_theme() {
    local theme_name="$1"
    log_info "Creando tema personalizado: $theme_name"
    
    local theme_dir="$THEMES_DIR/$theme_name"
    mkdir -p "$theme_dir"
    
    # Crear archivo de configuración de colores
    local colors_file="$theme_dir/colors.conf"
    
    cat > "$colors_file" << 'EOF'
# Custom Theme - Tema personalizado
# Edita estos colores según tus preferencias

# Colores base
BACKGROUND="#1E1E2E"
BACKGROUND_ALT="#181825"
BACKGROUND_DIM="#313244"
FOREGROUND="#CDD6F4"
FOREGROUND_ALT="#A6ADC8"
FOREGROUND_DIM="#6C7086"

# Colores de acento
ACCENT_PRIMARY="#89B4FA"
ACCENT_SECONDARY="#B4BEFE"
ACCENT_TERTIARY="#F5C2E7"

# Colores de estado
SUCCESS="#A6E3A1"
WARNING="#FAB387"
ERROR="#F38BA8"
INFO="#89B4FA"

# Colores de borde
BORDER="#6C7086"
BORDER_FOCUS="#89B4FA"
BORDER_URGENT="#F38BA8"

# Colores de texto
TEXT_PRIMARY="#CDD6F4"
TEXT_SECONDARY="#A6ADC8"
TEXT_DIM="#6C7086"
TEXT_MUTED="#585B70"

# Colores de fondo con transparencia
BACKGROUND_TRANSPARENT="rgba(30, 30, 46, 0.85)"
BACKGROUND_GLASS="rgba(30, 30, 46, 0.75)"
BACKGROUND_BLUR="rgba(30, 30, 46, 0.65)"

# Colores de sombra
SHADOW_LIGHT="rgba(0, 0, 0, 0.1)"
SHADOW_MEDIUM="rgba(0, 0, 0, 0.2)"
SHADOW_HEAVY="rgba(0, 0, 0, 0.3)"

# Configuración de blur
BLUR_STRENGTH="0.5"
BLUR_PASSES="5"
TRANSPARENCY_LEVEL="0.85"
EOF
    
    # Crear directorio para wallpapers
    mkdir -p "$theme_dir/wallpapers"
    
    # Crear directorio para configuraciones adicionales
    mkdir -p "$theme_dir/configs"
    
    log_ok "Tema personalizado '$theme_name' creado en $theme_dir"
    log_info "Edita $colors_file para personalizar los colores"
}

# Función para mostrar ayuda
show_help() {
    cat << EOF
${CYAN}Theme Switcher para Hyprland Dream${RESET}

${GREEN}Uso:${RESET}
  $0 [comando] [opciones]

${GREEN}Comandos:${RESET}
  apply <tema>              Aplicar tema específico
  list                      Listar temas disponibles
  current                   Mostrar tema actual
  preview <tema>            Mostrar preview del tema
  backup                    Crear backup de configuración actual
  restore <backup_path>     Restaurar backup
  schedule <día> <noche>    Programar cambio automático día/noche
  create <nombre>           Crear tema personalizado
  help                      Mostrar esta ayuda

${GREEN}Opciones:${RESET}
  --no-preview              No mostrar preview al aplicar tema
  --no-wallpaper            No sincronizar wallpapers
  --backup-only             Solo crear backup sin aplicar tema

${GREEN}Ejemplos:${RESET}
  $0 apply nord
  $0 apply dracula --no-preview
  $0 schedule catppuccin tokyo-night
  $0 create mi-tema
  $0 preview tokyo-night

${GREEN}Temas disponibles:${RESET}
  nord, dracula, catppuccin, tokyo-night, custom

EOF
}

# Función principal
main() {
    # Crear directorios necesarios
    mkdir -p "$CONFIG_DIR/hyprdream" "$CACHE_DIR"
    
    case "${1:-}" in
        "apply")
            local theme_name="$2"
            local no_preview="${3:-false}"
            local no_wallpaper="${4:-false}"
            
            if [[ -z "$theme_name" ]]; then
                log_error "Debes especificar un tema"
                show_help
                exit 1
            fi
            
            apply_theme "$theme_name" "$no_preview" "$no_wallpaper"
            ;;
        "list")
            list_themes
            ;;
        "current")
            show_current_theme
            ;;
        "preview")
            local theme_name="$2"
            if [[ -z "$theme_name" ]]; then
                log_error "Debes especificar un tema para preview"
                exit 1
            fi
            show_theme_preview "$theme_name"
            ;;
        "backup")
            create_backup
            ;;
        "restore")
            local backup_path="$2"
            if [[ -z "$backup_path" ]]; then
                log_error "Debes especificar la ruta del backup"
                exit 1
            fi
            restore_backup "$backup_path"
            ;;
        "schedule")
            local day_theme="$2"
            local night_theme="$3"
            if [[ -z "$day_theme" || -z "$night_theme" ]]; then
                log_error "Debes especificar temas para día y noche"
                exit 1
            fi
            schedule_theme_change "$day_theme" "$night_theme"
            ;;
        "create")
            local theme_name="$2"
            if [[ -z "$theme_name" ]]; then
                log_error "Debes especificar un nombre para el tema"
                exit 1
            fi
            create_custom_theme "$theme_name"
            ;;
        "help"|"-h"|"--help")
            show_help
            ;;
        "")
            # Modo interactivo
            echo -e "\n${CYAN}=== Theme Switcher para Hyprland Dream ===${RESET}"
            echo " 1) Aplicar tema"
            echo " 2) Listar temas disponibles"
            echo " 3) Mostrar tema actual"
            echo " 4) Preview de tema"
            echo " 5) Crear backup"
            echo " 6) Restaurar backup"
            echo " 7) Programar cambio automático"
            echo " 8) Crear tema personalizado"
            echo " 0) Salir"
            echo -n "Opción: "
            read -r opt
            
            case $opt in
                1)
                    list_themes
                    echo -n "Tema a aplicar: "
                    read -r theme
                    apply_theme "$theme"
                    ;;
                2) list_themes ;;
                3) show_current_theme ;;
                4)
                    list_themes
                    echo -n "Tema para preview: "
                    read -r theme
                    show_theme_preview "$theme"
                    ;;
                5) create_backup ;;
                6)
                    echo -n "Ruta del backup: "
                    read -r backup_path
                    restore_backup "$backup_path"
                    ;;
                7)
                    echo -n "Tema para día: "
                    read -r day_theme
                    echo -n "Tema para noche: "
                    read -r night_theme
                    schedule_theme_change "$day_theme" "$night_theme"
                    ;;
                8)
                    echo -n "Nombre del tema personalizado: "
                    read -r theme_name
                    create_custom_theme "$theme_name"
                    ;;
                0) log_info "Saliendo..."; exit 0 ;;
                *) log_warn "Opción inválida." ;;
            esac
            ;;
        *)
            log_error "Comando desconocido: $1"
            show_help
            exit 1
            ;;
    esac
}

# Ejecutar función principal
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main "$@"
fi 