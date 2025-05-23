#!/bin/bash

# Make sure dos2unix is installed
if ! command -v dos2unix &>/dev/null; then
	echo "dos2unix not found, attempting to install..."
	if command -v apt-get &>/dev/null; then
		sudo apt-get update && sudo apt-get install -y dos2unix
	elif command -v dnf &>/dev/null; then
		sudo dnf install -y dos2unix
	elif command -v pacman &>/dev/null; then
		sudo pacman -S --noconfirm dos2unix
	else
		echo "Could not install dos2unix. Please install it manually."
		exit 1
	fi
fi

# Fix line endings in zsh config files
dos2unix "$HOME/.config/zsh/.zshenv" 2>/dev/null || true
dos2unix "$HOME/.config/zsh/.zshrc" 2>/dev/null || true

# Optionally fix other shell files
find "$HOME/.config/zsh" -type f -name "*.zsh" -exec dos2unix {} \; 2>/dev/null || true
find "$HOME/.config/bash" -type f -exec dos2unix {} \; 2>/dev/null || true

echo "Line endings fixed successfully"
