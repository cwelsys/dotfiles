#!/bin/bash

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
GRAY='\033[0;90m'
MAGENTA='\033[0;35m'
NC='\033[0m'

install_yazi_plugin() {
	local plugin="$1"
	local description="$2"

	echo -e "${CYAN}Installing ${plugin}...${NC}"
	if [ -n "$description" ]; then
		echo -e "${GRAY}  Description: ${description}${NC}"
	fi

	if ya pack -a "$plugin"; then
		echo -e "${GREEN}  Success!${NC}"
	else
		echo -e "${RED}  Failed to install ${plugin}${NC}"
		echo -e "${RED}  Error: $?${NC}"
	fi
}

echo -e "${MAGENTA}=== Installing Yazi Plugins ===${NC}"

# Core functionality plugins
echo -e "\n${YELLOW}Core Functionality Plugins:${NC}"
install_yazi_plugin "AnirudhG07/custom-shell" "Custom shell execution"
install_yazi_plugin "lpnh/fr" "Enhanced file renaming"
install_yazi_plugin "dawsers/toggle-view" "Toggle between different view modes"
install_yazi_plugin "yazi-rs/plugins:hide-preview" "Hide preview panel"
install_yazi_plugin "yazi-rs/plugins:max-preview" "Maximize preview panel"
install_yazi_plugin "yazi-rs/plugins:smart-filter" "Smart filtering capabilities"

# File preview plugins
echo -e "\n${YELLOW}Preview Plugins:${NC}"
install_yazi_plugin "AnirudhG07/rich-preview" "Enhanced preview capabilities"
install_yazi_plugin "Reledia/glow" "Markdown preview with Glow"
install_yazi_plugin "yazi-rs/plugins:diff" "Show file differences"

# Git-related plugins
echo -e "\n${YELLOW}Git Plugins:${NC}"
install_yazi_plugin "yazi-rs/plugins:git" "Git integration"
install_yazi_plugin "imsi32/yatline-githead" "Git HEAD integration"

# UI enhancements
echo -e "\n${YELLOW}UI Enhancement Plugins:${NC}"
install_yazi_plugin "yazi-rs/plugins:full-border" "Full border UI"
install_yazi_plugin "Rolv-Apneseth/starship" "Starship prompt integration"
install_yazi_plugin "imsi32/yatline" "Custom status line"
install_yazi_plugin "yazi-rs/plugins:chmod" "File permission management"

# Themes
echo -e "\n${YELLOW}Themes:${NC}"
install_yazi_plugin "yazi-rs/flavors:catppuccin-mocha" "Catppuccin Mocha theme"

echo -e "\n${MAGENTA}=== Yazi Plugin Installation Complete ===${NC}"
