#!/bin/sh

# common shared environment variables
# -------------------------------------------------------------
export DOTFILES="~/.local/share/chezmoi/home"

# xdg
export XDG_CONFIG_DIRS="/etc/xdg"
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state"
export XDG_BIN_HOME="$HOME/.local/bin"
export XDG_PROJECTS_DIR="$HOME/projects"
if [ ! -w ${XDG_RUNTIME_DIR:="/run/user/$UID"} ]; then
	XDG_RUNTIME_DIR=/tmp
fi
export XDG_RUNTIME_DIR

export CONFIGDIR="/home/cwel/stacks/config"
export DOCKERM="/opt/docker"
export TZ="America/New_York"
export DOMAIN="cwel.sh"
export RUST="/mnt/media"
export FLASH="/mnt/bool"
export BRICK="/mnt/backup"
export DOMAIN="cwel.sh"

# Homebrew
# Disable homebrew auto-update for faster homebrew loading
export HOMEBREW_NO_AUTO_UPDATE=1

# ripgrep
export RIPGREP_CONFIG_PATH="$XDG_CONFIG_HOME/ripgrep/config"

# less
export LESSHISTFILE="$XDG_CACHE_HOME/.lesshsts"

# wget
export WGETRC="$XDG_CONFIG_HOME/wget/wgetrc"

# fzf
export FZF_DEFAULT_OPTS="--color=bg+:#363a4f,spinner:#f4dbd6,hl:#ed8796 \
--color=fg:#cad3f5,header:#ed8796,info:#c6a0f6,pointer:#f4dbd6 \
--color=marker:#b7bdf8,fg+:#cad3f5,prompt:#c6a0f6,hl+:#ed8796 \
--color=selected-bg:#494d64 \
--color=border:#363a4f,label:#cad3f5"

# vagrant
if uname -r | grep -q microsoft; then
	export VAGRANT_WSL_ENABLE_WINDOWS_ACCESS="1"

	if command -v wslvar >/dev/null 2>&1; then
		vagrant_windows_path=$(wslpath "$(wslvar USERPROFILE)")
		export VAGRANT_WSL_WINDOWS_ACCESS_USER_HOME_PATH="${vagrant_windows_path}/"
	fi
fi

# pkg-config paths
export PKG_CONFIG_PATH="/usr/lib/x86_64-linux-gnu/pkgconfig/:/usr/share/pkgconfig/"
