#!/bin/bash

sudo bash -e <<'EOF'
BASHENV_FILE="/etc/bash.bashrc"
BACKUP_FILE="/etc/bash.bashrc.bak"
XDG_LINE='export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"'
SOURCE_LINE='source "$XDG_CONFIG_HOME/bash/.bashrc"'

[ -f "$BASHENV_FILE" ] && cp "$BASHENV_FILE" "$BACKUP_FILE" || touch "$BASHENV_FILE"

grep -qxF "$XDG_LINE" "$BASHENV_FILE" || echo "$XDG_LINE" >> "$BASHENV_FILE"
grep -qxF "$SOURCE_LINE" "$BASHENV_FILE" || echo "$SOURCE_LINE" >> "$BASHENV_FILE"
EOF
