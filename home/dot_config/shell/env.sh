#!/bin/sh
# Shell environment variables
# Source this file from your shell RC file (.zshrc, .bashrc, etc.)
# These variables require shell features or are shell-specific

# Chezmoi shortcuts
export DOTS="${XDG_DATA_HOME:-$HOME/.local/share}/chezmoi"
export DOTFILES="${XDG_DATA_HOME:-$HOME/.local/share}/chezmoi"

# Editor preferences
export EDITOR="nvim"
export VISUAL="code --wait"
export SUDO_EDITOR="nvim"
export MANPAGER="nvim +Man!"

# Pagers
export PAGER="bat"
export GIT_PAGER="delta"
export LESS="-cgiRF"

# GPG - requires command substitution
if command -v tty >/dev/null 2>&1; then
    export GPG_TTY=$(tty)
fi

# Shell-specific settings (ZSH)
if [ -n "$ZSH_VERSION" ]; then
    export WORDCHARS='~!#$%^&*(){}[]<>?.+;'
    export PROMPT_EOL_MARK=''
fi

# Java options
if command -v java >/dev/null 2>&1; then
    export _JAVA_OPTIONS="-Djava.util.prefs.userRoot=\"$XDG_CONFIG_HOME/java\""
fi

# Tool themes and colors
if command -v bat >/dev/null 2>&1; then
    export BAT_THEME="Catppuccin Mocha"
    export BATDIFF_USE_DELTA="true"
fi

export vivid_theme="catppuccin-mocha"

# FZF Configuration
if command -v fzf >/dev/null 2>&1; then
    export FZF_COLORS='--color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc --color=hl:#f38ba8,fg:#cdd6f4,header:#f38ba8 --color=info:#94e2d5,pointer:#f5e0dc,marker:#f5e0dc --color=fg+:#cdd6f4,prompt:#94e2d5,hl+:#f38ba8 --color=border:#585b70'
    export FZF_DEFAULT_OPTS="$FZF_COLORS --layout=reverse --cycle --height=70% --min-height=20 --border=rounded --info=right --bind=alt-w:toggle-preview-wrap --bind=ctrl-a:toggle-all --bind=?:toggle-preview"
    export FZF_DEFAULT_COMMAND="fd --one-file-system --strip-cwd-prefix --follow --hidden --exclude '.git' --exclude 'node_modules' --exclude '.var'"
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND --type f --type d"
    export FZF_ALT_C_COMMAND="$FZF_DEFAULT_COMMAND --type d"
    export FZF_CTRL_R_OPTS="$FZF_DEFAULT_OPTS --preview 'echo {}' --preview-window 'down:3:hidden:wrap'"
    export FZF_CTRL_T_OPTS="$FZF_DEFAULT_OPTS --preview 'less {}' --preview-window 'right:wrap'"
    export FZF_HISTDIR="$XDG_DATA_HOME/fzf/history"

    if command -v eza >/dev/null 2>&1; then
        export FZF_ALT_C_OPTS="$FZF_DEFAULT_OPTS --preview 'eza -al --color=always --group-directories-first --icons -I=\"*NTUSER.DAT*|*ntuser.dat*|.DS_Store|.idea|.venv|.vs|__pycache__|cache|debug|.git|node_modules|venv\" {}'"
        export _ZO_FZF_OPTS="$FZF_DEFAULT_OPTS --preview 'eza -al --color=always --group-directories-first --icons -I=\"*NTUSER.DAT*|*ntuser.dat*|.DS_Store|.idea|.venv|.vs|__pycache__|cache|debug|.git|node_modules|venv\" {2..}' --preview-window=down:wrap"
    fi
fi

# Eza parameters for ls aliases
if command -v eza >/dev/null 2>&1; then
    export eza_params="--git --hyperlink --color=always --group-directories-first --icons -I \"NTUSER*|ntuser*|.DS_Store|.idea|.venv|.vs|__pycache__|cache|debug|.git|node_modules|venv\""
fi

# Homebrew settings
if command -v brew >/dev/null 2>&1; then
    export HOMEBREW_NO_ENV_HINTS="true"
    export HOMEBREW_BAT=1
    export HOMEBREW_COLOR=1
    export HOMEBREW_CLEANUP_MAX_AGE_DAYS=7
    export HOMEBREW_CLEANUP_PERIODIC_FULL_DAYS=3
    export HOMEBREW_DOWNLOAD_CONCURRENCY="auto"
fi

# Hostname-specific variables
case "$HOSTNAME" in
    pbox)
        export RUST="/mnt/media"
        export FLASH="/mnt/bool"
        export BRICK="/mnt/backup"
        ;;
esac

# WSL-specific
if [ -n "$WSLENV" ]; then
    export WIN_HOME="/mnt/c/users/cwel"
fi

# 1Password biometric unlock (macOS)
if [ "$(uname)" = "Darwin" ]; then
    export OP_BIOMETRIC_UNLOCK_ENABLED="true"
fi
