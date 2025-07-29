# Ejemplo de .zshrc para hyprdream
#            _
#    _______| |__  _ __ ___
#   |_  / __| '_ \| '__/ __|
#  _ / /\__ \ | | | | | (__
# (_)___|___/_| |_|_|  \___|
#
# =====================================================
# 🚀 ZSH Configuration - Arch Linux Optimized
# =====================================================
# DON'T CHANGE THIS FILE
# 
# Custom configuration goes in:
# - ~/.config/zshrc/*.zsh
# - ~/.config/zshrc/custom/*.zsh (overrides)
# - ~/.zshrc_custom (single file override)
# =====================================================

# =====================================================
# 🔧 PERFORMANCE & OPTIMIZATION
# =====================================================

# Disable Oh My Zsh automatic updates (handle manually)
zstyle ':omz:update' mode disabled

# Skip the verification of insecure directories
ZSH_DISABLE_COMPFIX=true

# Compilation flags for performance
export ARCHFLAGS="-arch x86_64"

# Enable completion caching
zstyle ':completion::complete:*' use-cache on
zstyle ':completion::complete:*' cache-path ~/.zsh/cache

# =====================================================
# 📂 MODULAR CONFIGURATION LOADER
# =====================================================

setopt NULL_GLOB  # Allow globs with no matches to expand to null
setopt EXTENDED_GLOB  # Enable extended globbing

# Load configuration files with error handling
load_config() {
    local config_dir="$1"
    if [[ -d "$config_dir" ]]; then
        for config_file in "$config_dir"/**/*.zsh(N); do
            if [[ -r "$config_file" ]]; then
                source "$config_file" 2>/dev/null || {
                    echo "⚠️  Error loading: $config_file" >&2
                }
            fi
        done
    fi
}

# Load base configuration
load_config ~/.config/zshrc

# Load custom overrides (if they exist)
load_config ~/.config/zshrc/custom

# Load single customization file
[[ -f ~/.zshrc_custom ]] && source ~/.zshrc_custom

# =====================================================
# 🧠 ZSH FRAMEWORK - Oh My Zsh + Powerlevel10k
# =====================================================

export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"

# Oh My Zsh Configuration
DISABLE_AUTO_TITLE="true"           # Disable auto-setting terminal title
ENABLE_CORRECTION="true"            # Enable command auto-correction
COMPLETION_WAITING_DOTS="true"      # Display red dots whilst waiting for completion
DISABLE_UNTRACKED_FILES_DIRTY="true" # Don't mark untracked files as dirty (faster)
HIST_STAMPS="yyyy-mm-dd"            # History timestamp format

# Optimized plugin list
plugins=(
    # Core functionality
    git
    archlinux
    sudo
    history-substring-search
    
    # Enhanced completions
    npm
    pip
    systemd
    
    # Productivity
    z
    extract
    colored-man-pages
    command-not-found
)

# Load Oh My Zsh
if [[ -f $ZSH/oh-my-zsh.sh ]]; then
    source $ZSH/oh-my-zsh.sh
else
    echo "⚠️  Oh My Zsh not found. Install with:"
    echo "sh -c \"\$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)\""
fi

# Load Powerlevel10k configuration
[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh

# =====================================================
# ⚙️ SHELL CONFIGURATION & ENVIRONMENT
# =====================================================

# History Configuration
HISTFILE=~/.zsh_history
HISTSIZE=50000              # Increased from 10000
SAVEHIST=50000             # Increased from 10000
setopt HIST_EXPIRE_DUPS_FIRST    # Expire duplicates first
setopt HIST_IGNORE_ALL_DUPS      # No consecutive duplicates
setopt HIST_IGNORE_SPACE         # No commands starting with space
setopt HIST_FIND_NO_DUPS         # No duplicates in search
setopt HIST_SAVE_NO_DUPS         # No duplicates in save
setopt INC_APPEND_HISTORY        # Append immediately
setopt SHARE_HISTORY             # Share between terminals
setopt HIST_VERIFY               # Verify history expansions
setopt HIST_REDUCE_BLANKS        # Remove unnecessary blanks

# Shell Options
setopt CORRECT                   # Auto-correct commands
setopt CORRECT_ALL              # Auto-correct all arguments
setopt NOCLOBBER                # Don't overwrite existing files with >
setopt AUTO_CD                  # Change directory without cd
setopt AUTO_PUSHD               # Push directories to stack
setopt PUSHD_IGNORE_DUPS        # No duplicate directories in stack
setopt PUSHD_SILENT             # Don't print directory stack
setopt GLOB_DOTS                # Include dotfiles in globbing
setopt EXTENDED_GLOB            # Extended globbing
setopt NUMERIC_GLOB_SORT        # Sort numerically when possible

# Editor Configuration
export EDITOR='nvim'
export VISUAL='nvim'
export BROWSER='firefox'
export TERMINAL='alacritty'

# Locale Configuration (Peru)
export LANG=es_PE.UTF-8
export LC_ALL=es_PE.UTF-8
export LC_COLLATE=C             # Use C collation for consistent sorting

# PATH Configuration
typeset -U path                 # Keep PATH entries unique
path=(
    ~/.local/bin
    ~/.cargo/bin
    ~/.bun/bin
    ~/.npm-global/bin
    /usr/local/bin
    $path
)

# XDG Base Directory Specification
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_STATE_HOME="$HOME/.local/state"

# Less/Man Pages Colorization
export LESS_TERMCAP_mb=$'\e[1;31m'     # begin bold
export LESS_TERMCAP_md=$'\e[1;36m'     # begin blink
export LESS_TERMCAP_me=$'\e[0m'        # reset bold/blink
export LESS_TERMCAP_se=$'\e[0m'        # reset reverse video
export LESS_TERMCAP_so=$'\e[01;44;33m' # reverse video
export LESS_TERMCAP_ue=$'\e[0m'        # reset underline
export LESS_TERMCAP_us=$'\e[1;32m'     # begin underline

# Less Options
export LESS='-R -i -w -M -z-4'  # Raw colors, case-insensitive, highlight first match, long prompt, scroll 4 lines

# FZF Configuration
export FZF_DEFAULT_OPTS="
    --color=bg+:#363a4f,bg:#24273a,spinner:#f4dbd6,hl:#ed8796
    --color=fg:#cad3f5,header:#ed8796,info:#c6a0f6,pointer:#f4dbd6
    --color=marker:#f4dbd6,fg+:#cad3f5,prompt:#c6a0f6,hl+:#ed8796
    --height=60% --layout=reverse --border --margin=1 --padding=1
"
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"

# =====================================================
# 🛠️ MODERN COMMAND REPLACEMENTS
# =====================================================

# File Operations
if command -v bat &> /dev/null; then
    alias cat='bat --style=plain --paging=never'
    alias ccat='bat --style=full'  # Full bat with line numbers
    export BAT_THEME="Catppuccin Frappe"
fi

if command -v eza &> /dev/null; then
    alias ls='eza --icons --group-directories-first --git'
    alias ll='eza -l --icons --group-directories-first --git --time-style=long-iso --smart-group'
    alias la='eza -la --icons --group-directories-first --git --time-style=long-iso'
    alias tree='eza --tree --level=3 --icons --git-ignore'
    alias ltree='eza --tree --level=4 --icons --long --git-ignore'
else
    alias ll='ls -alF --color=auto --group-directories-first'
    alias la='ls -A --color=auto --group-directories-first'
fi

if command -v rg &> /dev/null; then
    alias grep='rg --smart-case --hidden --glob "!**/.git/*" --glob "!**/node_modules/*"'
    alias rga='rg --no-ignore --hidden'  # Search in all files
fi

if command -v fd &> /dev/null; then
    alias find='fd'
    alias fda='fd --no-ignore --hidden'  # Find all files
fi

# System Monitoring
command -v duf &> /dev/null && alias df='duf'
command -v dust &> /dev/null && alias du='dust'
command -v btop &> /dev/null && alias top='btop' || alias top='htop'
command -v delta &> /dev/null && alias diff='delta'
command -v xh &> /dev/null && alias http='xh'

# =====================================================
# 📁 NAVIGATION & FILE MANAGEMENT
# =====================================================

# Navigation
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
alias ~='cd ~'
alias -- -='cd -'

# Directory shortcuts
alias dl='cd ~/Downloads'
alias dt='cd ~/Desktop'
alias dc='cd ~/Documents'
alias dev='cd ~/Development'
alias proj='cd ~/Projects'

# File operations with safety
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'
alias mkdir='mkdir -p'

# Enhanced file operations
alias usage='du -h --max-depth=1 | sort -hr'
alias largest='find . -type f -printf "%s %p\n" | sort -rn | head -20'
alias newest='find . -type f -printf "%T+ %p\n" | sort -r | head -20'


# =====================================================
# 🌐 NETWORK & CONNECTIVITY
# =====================================================

alias myip='curl -s ifconfig.me && echo'
alias localip="ip route get 8.8.8.8 | awk '{print \$7}'"
alias ports='sudo lsof -i -P -n | grep LISTEN'
alias netstat='ss -tuln'
alias ping='ping -c 5'
alias wget='wget -c'  # Continue partial downloads

# Network testing
alias speedtest='curl -s https://raw.githubusercontent.com/sivel/speedtest-cli/master/speedtest.py | python -'
alias pingtest='ping -c 10 8.8.8.8'


# =====================================================
# 💻 SYSTEM SHORTCUTS & UTILITIES
# =====================================================

# Process management
alias psg='ps aux | grep -v grep | grep -i'
alias killall='killall -i'  # Interactive mode
alias j='jobs'
alias h='history'

# File opening
alias open='xdg-open'
alias edit='$EDITOR'
alias code='code'  # VSCode

# Safety aliases
alias reboot='echo "🔄 Use: systemctl reboot"'
alias shutdown='echo "🔌 Use: systemctl poweroff"'
alias poweroff='echo "🔌 Use: systemctl poweroff"'
alias halt='echo "⛔ Use: systemctl halt"'

# =====================================================
# 🎯 PRODUCTIVITY & MOTIVATION
# =====================================================

# Health reminders
alias salud='echo "💪 Respira profundo, toma agua y mantén una buena postura."'
alias pomodoro='echo "🍅 25 min de trabajo enfocado, 5 min de descanso."'
alias stretch='echo "🤸 Hora de estirarse - cuello, espalda y muñecas."'

# Motivation
alias coffee='echo "☕ Tómate un cafecito y sigue adelante."'
alias focus='echo "🎯 Elimina distracciones y concéntrate en una tarea."'

# Random motivation quote
if command -v curl &> /dev/null && command -v jq &> /dev/null; then
    alias motivacion='curl -s "https://zenquotes.io/api/random" | jq -r ".[0].q + \" —\" + .[0].a"'
fi

# Weather
alias clima='curl -s "wttr.in/Lima?format=3"'
alias weather='curl -s "wttr.in/Lima"'

# =====================================================
# 🚀 FUNCTIONS
# =====================================================

# Extract function for various archive types
extract() {
    if [ -f "$1" ]; then
        case "$1" in
            *.tar.bz2)   tar xjf "$1"     ;;
            *.tar.gz)    tar xzf "$1"     ;;
            *.bz2)       bunzip2 "$1"     ;;
            *.rar)       unrar x "$1"     ;;
            *.gz)        gunzip "$1"      ;;
            *.tar)       tar xf "$1"      ;;
            *.tbz2)      tar xjf "$1"     ;;
            *.tgz)       tar xzf "$1"     ;;
            *.zip)       unzip "$1"       ;;
            *.Z)         uncompress "$1"  ;;
            *.7z)        7z x "$1"        ;;
            *.xz)        unxz "$1"        ;;
            *.exe)       cabextract "$1"  ;;
            *)           echo "'$1': unrecognized file compression" ;;
        esac
    else
        echo "'$1' is not a valid file"
    fi
}

# Create directory and cd into it
mkcd() {
    mkdir -p "$1" && cd "$1"
}

# Find and replace in files
findreplace() {
    if [ $# -ne 2 ]; then
        echo "Usage: findreplace <search> <replace>"
        return 1
    fi
    find . -type f -exec sed -i "s/$1/$2/g" {} +
}

# Quick backup of a file
backup() {
    cp "$1" "$1.backup.$(date +%Y%m%d_%H%M%S)"
}

# System information function
sysstat() {
    echo "=== System Information ==="
    echo "Hostname: $(hostname)"
    echo "Kernel: $(uname -r)"
    echo "Uptime: $(uptime -p)"
    echo "Load Average: $(uptime | awk -F'load average:' '{print $2}')"
    echo "Memory Usage: $(free -h | awk '/^Mem:/ {printf "%s/%s (%.1f%%)", $3, $2, $3/$2*100}')"
    echo "Disk Usage: $(df -h / | awk 'NR==2 {printf "%s/%s (%s)", $3, $2, $5}')"
    echo "CPU Temperature: $(sensors 2>/dev/null | grep 'Core 0' | awk '{print $3}' || echo 'N/A')"
}

# =====================================================
# 🎨 COMPLETION ENHANCEMENTS
# =====================================================

# Case-insensitive completion
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'

# Colored completion
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}

# Better completion for kill command
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#)*=0=01;31'
zstyle ':completion:*:kill:*' command 'ps -u $USER -o pid,%cpu,tty,cputime,cmd'

# SSH completion
zstyle ':completion:*:ssh:*' hosts off
zstyle ':completion:*:scp:*' hosts off

# =====================================================
# 🔌 PLUGIN CONFIGURATIONS
# =====================================================

# Autosuggestions
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#666666,bold"
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20

# Syntax highlighting
typeset -A ZSH_HIGHLIGHT_STYLES
ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets pattern)
ZSH_HIGHLIGHT_STYLES[command]='fg=green,bold'
ZSH_HIGHLIGHT_STYLES[alias]='fg=cyan,bold'
ZSH_HIGHLIGHT_STYLES[builtin]='fg=yellow,bold'
ZSH_HIGHLIGHT_STYLES[function]='fg=blue,bold'

# =====================================================
# 🏁 INITIALIZATION
# =====================================================

# Load completions
autoload -Uz compinit
compinit -d ~/.zsh/compdump

# Load zsh-autosuggestions and zsh-syntax-highlighting from system paths
[ -f /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh ] && source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
[ -f /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ] && source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# Load Node Version Manager (if exists)
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# Bun completions
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

# Rust environment
[ -f "$HOME/.cargo/env" ] && source "$HOME/.cargo/env"

# FZF key bindings
[ -f /usr/share/fzf/key-bindings.zsh ] && source /usr/share/fzf/key-bindings.zsh
[ -f /usr/share/fzf/completion.zsh ] && source /usr/share/fzf/completion.zsh

# Initialize fastfetch (system info display)
command -v fastfetch &> /dev/null && fastfetch



# Load any additional custom configurations
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local