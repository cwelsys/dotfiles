#!/bin/bash
set -euo pipefail

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${YELLOW}Checking for Homebrew installation...${NC}"

# Check if Homebrew is already installed
if command -v brew &>/dev/null; then
	echo -e "${GREEN}Homebrew is already installed${NC}"
else
	echo -e "${YELLOW}Installing Homebrew...${NC}"

	# Install required dependencies for Homebrew
	if command -v apt-get &>/dev/null; then
		# Debian/Ubuntu
		sudo apt-get update
		sudo apt-get install -y build-essential procps curl file git
	elif command -v dnf &>/dev/null; then
		# Fedora/RHEL/CentOS
		sudo dnf groupinstall -y 'Development Tools'
		sudo dnf install -y procps-ng curl file git
	elif command -v pacman &>/dev/null; then
		# Arch Linux
		sudo pacman -Sy --noconfirm base-devel procps-ng curl file git
	elif command -v zypper &>/dev/null; then
		# openSUSE
		sudo zypper install -y curl file git
		sudo zypper install -y -t pattern devel_basis
	else
		echo -e "${YELLOW}Unable to automatically install dependencies. Please ensure build tools are installed.${NC}"
	fi

	# Run official Homebrew install script
	/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

	# Check if installation was successful
	if [ $? -ne 0 ]; then
		echo -e "${RED}Homebrew installation failed!${NC}"
		exit 1
	fi

	echo -e "${GREEN}Homebrew installation completed${NC}"
fi

# Configure Homebrew environment
echo -e "${YELLOW}Configuring Homebrew environment...${NC}"

# Set up Homebrew environment for the current session
if [[ -d /home/linuxbrew/.linuxbrew ]]; then
	eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
elif [[ -d "$HOME/.linuxbrew" ]]; then
	eval "$("$HOME/.linuxbrew/bin/brew" shellenv)"
else
	echo -e "${RED}Homebrew installation directory not found!${NC}"
	exit 1
fi

# Install packages from Brewfile if it exists
BREWFILE="$HOME/.config/shared/Brewfile"
if [[ -f "$BREWFILE" ]]; then
	echo -e "${YELLOW}Installing packages from Brewfile...${NC}"
	brew bundle install --file="$BREWFILE"
	echo -e "${GREEN}Brewfile installation completed${NC}"
else
	echo -e "${YELLOW}No Brewfile found at $BREWFILE. Skipping package installation.${NC}"
fi

echo -e "${GREEN}Homebrew setup completed successfully!${NC}"
