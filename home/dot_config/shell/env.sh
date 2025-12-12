#!/bin/sh

export EDITOR="nvim"
export VISUAL="code --wait"
export SUDO_EDITOR=$EDITOR
export SYSTEMD_EDITOR=$EDITOR
export MANPAGER="$EDITOR +Man!"
export PAGER="bat"
export GIT_PAGER="delta"
export LESS="-cgiRF"

export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
export XDG_BIN_HOME="${XDG_BIN_HOME:-$HOME/.local/bin}"
export XDG_PROJECTS_DIR="${XDG_PROJECTS_DIR:-$HOME/Projects}"

export DOTS="$XDG_DATA_HOME/chezmoi/home"
export DOTFILES="$XDG_DATA_HOME/chezmoi/home"
export GITHUB_USERNAME="cwelsys"
export CARGO_HOME="$XDG_DATA_HOME/cargo"
export RUSTUP_HOME="$XDG_DATA_HOME/rustup"
export GOPATH="$XDG_DATA_HOME/go"
export GOBIN="$XDG_DATA_HOME/go/bin"
export DOTNET_CLI_HOME="$XDG_DATA_HOME/dotnet"
export GRADLE_USER_HOME="$XDG_DATA_HOME/gradle"
export NPM_CONFIG_PREFIX="$XDG_DATA_HOME/npm"
export NPM_CONFIG_CACHE="$XDG_CACHE_HOME/npm"
export NPM_CONFIG_INIT_MODULE="$XDG_CONFIG_HOME/npm/config/npm-init.js"
export NPM_CONFIG_USERCONFIG="$XDG_CONFIG_HOME/npm/config"
export NODE_REPL_HISTORY="$XDG_STATE_HOME/node_repl_history"
export PNPM_HOME="$XDG_DATA_HOME/pnpm"
export PYTHONSTARTUP="$XDG_CONFIG_HOME/python/pythonrc"
export PYTHON_HISTORY="$XDG_DATA_HOME/python/history"
export PIPX_HOME="$XDG_DATA_HOME/pipx"
export PIPX_GLOBAL_HOME="$XDG_DATA_HOME/pipx"
export GNUPGHOME="$XDG_DATA_HOME/gnupg"
export PASSWORD_STORE_DIR="$XDG_DATA_HOME/pass"
export DOCKER_CONFIG="$XDG_CONFIG_HOME/docker"
export VAGRANT_HOME="$XDG_DATA_HOME/vagrant"
export ANDROID_HOME="$XDG_DATA_HOME/android"
export ADB_VENDOR_KEYS="$XDG_DATA_HOME/android"
export CUDA_CACHE_PATH="$XDG_CACHE_HOME/nv"
export XAUTHORITY="$XDG_STATE_HOME/.Xauthority"
export XCOMPOSEFILE="$XDG_CONFIG_HOME/X11/xcompose"
export GTK2_RC_FILES="$XDG_CONFIG_HOME/gtk-2.0/gtkrc"
export TERMINFO="$XDG_DATA_HOME/terminfo"
export TERMINFO_DIRS="$XDG_DATA_HOME/terminfo:/usr/share/terminfo"
export RIPGREP_CONFIG_PATH="$XDG_CONFIG_HOME/ripgrep/config"
export LESSHISTFILE="$XDG_CACHE_HOME/lesshsts"
export AWS_CONFIG_FILE="$XDG_DATA_HOME/aws/config"
export AWS_DATA_PATH="$XDG_DATA_HOME/aws"
export AWS_SHARED_CREDENTIALS_FILE="$XDG_DATA_HOME/aws/credentials"
export CLAUDE_CONFIG_DIR="$XDG_CONFIG_HOME/claude"
export PARALLEL_HOME="$XDG_CONFIG_HOME/parallel"
export WAKATIME_HOME="$XDG_CONFIG_HOME/wakatime"
export VCPKG_ROOT="$XDG_DATA_HOME/vcpkg"
export BUNDLE_USER_CONFIG="$XDG_CONFIG_HOME"/bundle
export BUNDLE_USER_CACHE="$XDG_CACHE_HOME"/bundle
export BUNDLE_USER_PLUGIN="$XDG_DATA_HOME"/bundle
export WGETRC="$XDG_CONFIG_HOME/wget/wgetrc"
export INPUTRC="$XDG_CONFIG_HOME/bash/inputrc"
export SCREENRC="$XDG_CONFIG_HOME/screen/screenrc"
export WINEPREFIX="$XDG_DATA_HOME"/wine

export DO_NOT_TRACK=1
export DISABLE_TELEMETRY=1
export DOTNET_CLI_TELEMETRY_OPTOUT=1
export GLOW_STYLE="$XDG_CONFIG_HOME/glow/catppuccin-mocha.json"

if command -v tty >/dev/null 2>&1; then
    export GPG_TTY=$(tty)
fi

if [ -n "$ZSH_VERSION" ]; then
    export WORDCHARS='~!#$%^&*(){}[]<>?.+;'
    export PROMPT_EOL_MARK=''
fi

if command -v java >/dev/null 2>&1; then
    export _JAVA_OPTIONS="-Djava.util.prefs.userRoot=\"$XDG_CONFIG_HOME/java\""
fi

if command -v bat >/dev/null 2>&1; then
    export BAT_THEME="Catppuccin Mocha"
    export BATDIFF_USE_DELTA="true"
fi

export vivid_theme="catppuccin-mocha"

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

if command -v eza >/dev/null 2>&1; then
    export eza_params="--git --hyperlink --color=always --group-directories-first --icons -I \"NTUSER*|ntuser*|.DS_Store|.idea|.venv|.vs|__pycache__|cache|debug|.git|node_modules|venv\""
fi

if command -v brew >/dev/null 2>&1; then
    export HOMEBREW_NO_ENV_HINTS="true"
    export HOMEBREW_BAT=1
    export HOMEBREW_COLOR=1
    export HOMEBREW_CLEANUP_MAX_AGE_DAYS=7
    export HOMEBREW_CLEANUP_PERIODIC_FULL_DAYS=3
fi

case "$HOSTNAME" in
    pbox)
        export RUST="/mnt/media"
        export FLASH="/mnt/bool"
        export BRICK="/mnt/backup"
        ;;
esac

if [ -n "$WSLENV" ]; then
    export WIN_HOME="/mnt/c/users/cwel"
fi

if [ "$(uname)" = "Darwin" ]; then
    export OP_BIOMETRIC_UNLOCK_ENABLED="true"
fi
