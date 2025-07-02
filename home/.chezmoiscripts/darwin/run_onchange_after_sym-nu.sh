#!/bin/bash

NUSHELL_CONFIG_DIR="$HOME/.config/nushell"
NUSHELL_MACOS_DIR="$HOME/Library/Application Support/nushell"

if [ -d "$NUSHELL_CONFIG_DIR" ]; then
	if [ -e "$NUSHELL_MACOS_DIR" ] || [ -L "$NUSHELL_MACOS_DIR" ]; then
		echo "Removing existing nushell config at: $NUSHELL_MACOS_DIR"
		rm -rf "$NUSHELL_MACOS_DIR"
	fi

	mkdir -p "$(dirname "$NUSHELL_MACOS_DIR")"

	echo "Creating symlink: $NUSHELL_MACOS_DIR -> $NUSHELL_CONFIG_DIR"
	ln -s "$NUSHELL_CONFIG_DIR" "$NUSHELL_MACOS_DIR"
else
	echo "Warning: $NUSHELL_CONFIG_DIR does not exist. Skipping nushell symlink creation."
fi
