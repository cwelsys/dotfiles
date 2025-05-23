#!bin/bash
set -euo pipefail

echo "Checking for Homebrew installation..."

# Check if Homebrew is already installed
if command -v brew &>/dev/null; then
  echo "Homebrew is already installed"
else
  echo "Installing Homebrew..."

  # Install required dependencies
  if command -v apt-get &>/dev/null; then
    sudo apt-get update
    sudo apt-get install -y build-essential procps curl file git
  elif command -v dnf &>/dev/null; then
    sudo dnf groupinstall -y 'Development Tools'
    sudo dnf install -y procps-ng curl file git
  elif command -v pacman &>/dev/null; then
    sudo pacman -Sy --noconfirm base-devel procps-ng curl file git
  fi

  # Run official Homebrew install script
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  # Check if installation was successful
  if [ $? -ne 0 ]; then
    echo "Homebrew installation failed!"
    exit 1
  fi
fi

# Set up Homebrew in current session
if [[ -d /home/linuxbrew/.linuxbrew ]]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
elif [[ -d "$HOME/.linuxbrew" ]]; then
  eval "$("$HOME/.linuxbrew/bin/brew" shellenv)"
fi

echo "Homebrew setup completed"
