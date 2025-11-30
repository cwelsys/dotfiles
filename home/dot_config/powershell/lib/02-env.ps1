# ============================================================================
# XDG Base Directories
# ============================================================================
$env:XDG_CONFIG_HOME = "$HOME/.config"
$env:XDG_CACHE_HOME = "$HOME/.cache"
$env:XDG_DATA_HOME = "$HOME/.local/share"
$env:XDG_STATE_HOME = "$HOME/.local/state"
$env:XDG_BIN_HOME = "$HOME/.local/bin"
$env:XDG_PROJECTS_DIR = "$HOME/Projects"

# ============================================================================
# Chezmoi Shortcuts
# ============================================================================
$env:DOTS = "$env:XDG_DATA_HOME/chezmoi/home"
$env:DOTFILES = "$env:XDG_DATA_HOME/chezmoi/home"

# ============================================================================
# Development Tools
# ============================================================================
$env:CARGO_HOME = "$env:XDG_DATA_HOME/cargo"
$env:RUSTUP_HOME = "$env:XDG_DATA_HOME/rustup"
$env:GOPATH = "$env:XDG_DATA_HOME/go"
$env:GOBIN = "$env:XDG_DATA_HOME/go/bin"

# .NET
$env:DOTNET_CLI_HOME = "$env:XDG_DATA_HOME/dotnet"
$env:DOTNET_ROOT = "$env:XDG_DATA_HOME/dotnet"
$env:DOTNET_INSTALL_DIR = "$env:XDG_DATA_HOME/dotnet"
$env:DOTNET_CLI_TELEMETRY_OPTOUT = '1'

$env:GRADLE_USER_HOME = "$env:XDG_DATA_HOME/gradle"

# ============================================================================
# Node.js / NPM
# ============================================================================
$env:NPM_CONFIG_PREFIX = "$env:XDG_DATA_HOME/npm"
$env:NPM_CONFIG_CACHE = "$env:XDG_CACHE_HOME/npm"
$env:NPM_CONFIG_INIT_MODULE = "$env:XDG_CONFIG_HOME/npm/config/npm-init.js"
$env:NPM_CONFIG_USERCONFIG = "$env:XDG_CONFIG_HOME/npm/config"
$env:NODE_REPL_HISTORY = "$env:XDG_STATE_HOME/node_repl_history"
$env:PNPM_HOME = "$env:XDG_DATA_HOME/pnpm"
$env:YARN_CACHE_FOLDER = "$env:XDG_CACHE_HOME/npm"

# ============================================================================
# Python
# ============================================================================
$env:PYTHONSTARTUP = "$env:XDG_CONFIG_HOME/python/pythonrc"
$env:PYTHON_HISTORY = "$env:XDG_DATA_HOME/python/history"
$env:PIPX_HOME = "$env:XDG_DATA_HOME/pipx"
$env:PIPX_GLOBAL_HOME = "$env:XDG_DATA_HOME/pipx"

# ============================================================================
# Security & Crypto
# ============================================================================
$env:GNUPGHOME = "$env:XDG_DATA_HOME/gnupg"

# ============================================================================
# Docker & Containers
# ============================================================================
$env:DOCKER_CONFIG = "$env:XDG_CONFIG_HOME/docker"
$env:VAGRANT_HOME = "$env:XDG_DATA_HOME/vagrant"
$env:VBOX_USER_HOME = "$env:XDG_DATA_HOME/virtualbox"
$env:VAGRANT_DEFAULT_PROVIDER = 'virtualbox'

# ============================================================================
# Android / ADB
# ============================================================================
$env:ANDROID_USER_HOME = "$env:XDG_DATA_HOME/android"

# ============================================================================
# Terminal & Shell Tools
# ============================================================================
$env:RIPGREP_CONFIG_PATH = "$env:XDG_CONFIG_HOME/ripgrep/config"
$env:LESSHISTFILE = "$env:XDG_CACHE_HOME/lesshsts"

# ============================================================================
# AWS
# ============================================================================
$env:AWS_CONFIG_FILE = "$env:XDG_DATA_HOME/aws/config"
$env:AWS_DATA_PATH = "$env:XDG_DATA_HOME/aws"
$env:AWS_SHARED_CREDENTIALS_FILE = "$env:XDG_DATA_HOME/aws/credentials"

# ============================================================================
# Misc Tools
# ============================================================================
$env:CLAUDE_CONFIG_DIR = "$env:XDG_CONFIG_HOME/claude"
$env:GLOW_STYLE = "$env:XDG_CONFIG_HOME/glow/catppuccin-mocha.json"
$env:WAKATIME_HOME = "$env:XDG_CONFIG_HOME/wakatime"
$env:YAZI_CONFIG_HOME = "$env:XDG_CONFIG_HOME/yazi"
$env:EZA_CONFIG_DIR = "$env:XDG_CONFIG_HOME/eza"
$env:BAT_CONFIG_DIR = "$env:XDG_CONFIG_HOME/bat"
$env:BAT_CONFIG_PATH = "$env:XDG_CONFIG_HOME/bat/config"
$env:CLINK_PROFILE = "$env:XDG_CONFIG_HOME/clink"
$env:GH_DASH_CONFIG = "$env:XDG_CONFIG_HOME/gh-dash/config.yml"
$env:RCLONE_CONFIG_DIR = "$env:XDG_CONFIG_HOME/rclone"
$env:KOMOREBI_CONFIG_HOME = "$env:XDG_CONFIG_HOME/komorebi"

# ============================================================================
# Telemetry Opt-out
# ============================================================================
$env:DO_NOT_TRACK = 1
$env:DISABLE_TELEMETRY = 1

# ============================================================================
# Editor Preferences
# ============================================================================
$env:EDITOR = 'nvim'
$env:VISUAL = 'code --wait'

# ============================================================================
# Pagers
# ============================================================================
$env:PAGER = 'bat'
$env:GIT_PAGER = 'delta'
$env:LESS = '-cgiRF'

# ============================================================================
# Tool Themes and Colors
# ============================================================================
if (Get-Command bat -ErrorAction SilentlyContinue) {
    $env:BAT_THEME = 'Catppuccin Mocha'
    $env:BATDIFF_USE_DELTA = 'true'
}

$env:vivid_theme = 'catppuccin-mocha'

# ============================================================================
# FZF Configuration
# ============================================================================
if (Get-Command fzf -ErrorAction SilentlyContinue) {
    $env:FZF_COLORS = '--color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc --color=hl:#f38ba8,fg:#cdd6f4,header:#f38ba8 --color=info:#94e2d5,pointer:#f5e0dc,marker:#f5e0dc --color=fg+:#cdd6f4,prompt:#94e2d5,hl+:#f38ba8 --color=border:#585b70'
    $env:FZF_DEFAULT_OPTS = "$env:FZF_COLORS --layout=reverse --cycle --height=70% --min-height=20 --border=rounded --info=right --bind=alt-w:toggle-preview-wrap --bind=ctrl-a:toggle-all --bind=?:toggle-preview"
    $env:FZF_DEFAULT_COMMAND = "fd --one-file-system --strip-cwd-prefix --follow --hidden --exclude '.git' --exclude 'node_modules' --exclude '.var'"
    $env:FZF_CTRL_T_COMMAND = "$env:FZF_DEFAULT_COMMAND --type f --type d"
    $env:FZF_ALT_C_COMMAND = "$env:FZF_DEFAULT_COMMAND --type d"
    $env:FZF_CTRL_R_OPTS = "$env:FZF_DEFAULT_OPTS --preview 'echo {}' --preview-window 'down:3:hidden:wrap'"
    $env:FZF_CTRL_T_OPTS = "$env:FZF_DEFAULT_OPTS --preview 'less {}' --preview-window 'right:wrap'"
    $env:FZF_HISTDIR = "$env:XDG_DATA_HOME/fzf/history"

    if (Get-Command eza -ErrorAction SilentlyContinue) {
        $env:FZF_ALT_C_OPTS = "$env:FZF_DEFAULT_OPTS --preview 'eza -al --color=always --group-directories-first --icons -I=`"*NTUSER.DAT*|*ntuser.dat*|.DS_Store|.idea|.venv|.vs|__pycache__|cache|debug|.git|node_modules|venv`" {}'"
        $env:_ZO_FZF_OPTS = "$env:FZF_DEFAULT_OPTS --preview 'eza -al --color=always --group-directories-first --icons -I=`"*NTUSER.DAT*|*ntuser.dat*|.DS_Store|.idea|.venv|.vs|__pycache__|cache|debug|.git|node_modules|venv`" {2..}' --preview-window=down:wrap"
    }
}

# ============================================================================
# Personal / Domain
# ============================================================================
$env:GITHUB_USERNAME = 'cwelsys'
$env:DOMAIN = 'cwel.sh'
$env:CASA = 'cwel.casa'
$env:TZ = 'America/New_York'

# ============================================================================
# Windows-specific
# ============================================================================
if (Test-Path 'C:/Program Files/Git/usr/bin/file.exe') {
    $env:YAZI_FILE_ONE = 'C:/Program Files/Git/usr/bin/file.exe'
}

# ============================================================================
# Force Color Support
# ============================================================================
$env:FORCE_COLOR = 1
