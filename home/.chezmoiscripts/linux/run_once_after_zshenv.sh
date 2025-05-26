#!/bin/bash

sudo bash -e <<'EOF'
ZSHENV_FILE="/etc/zshenv"
BACKUP_FILE="/etc/zshenv.bak"
XDG_LINE='export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"'
ZDOTDIR_LINE='export ZDOTDIR="$XDG_CONFIG_HOME/zsh"'

[ -f "$ZSHENV_FILE" ] && cp "$ZSHENV_FILE" "$BACKUP_FILE" || touch "$ZSHENV_FILE"

grep -qxF "$XDG_LINE" "$ZSHENV_FILE" || echo "$XDG_LINE" >> "$ZSHENV_FILE"
grep -qxF "$ZDOTDIR_LINE" "$ZSHENV_FILE" || echo "$ZDOTDIR_LINE" >> "$ZSHENV_FILE"
EOF
