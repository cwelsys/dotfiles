#!/bin/bash

# Script to update linux.yml with user-installed packages

CHEZMOI_DATA_DIR="$HOME/.local/share/chezmoi/home/.chezmoidata/pkgs"
LINUX_YML="$CHEZMOI_DATA_DIR/linux.yml"

# Ensure the directory exists
if [[ ! -d "$CHEZMOI_DATA_DIR" ]]; then
  echo "Chezmoi data directory not found at $CHEZMOI_DATA_DIR"
  exit 1
fi

# Check if linux.yml exists
if [[ ! -f "$LINUX_YML" ]]; then
  echo "linux.yml not found at $LINUX_YML"
  exit 1
fi

# Check if yq is available
if ! command -v yq &>/dev/null; then
  echo "yq is required for YAML processing. Please install it first."
  echo "You can install it with: brew install yq"
  exit 1
fi

# Detect Linux distribution
if command -v lsb_release &>/dev/null; then
  DISTRO=$(lsb_release -is | tr '[:upper:]' '[:lower:]')
elif [[ -f /etc/os-release ]]; then
  DISTRO=$(grep -oP '(?<=^ID=).+' /etc/os-release | tr -d '"' | tr '[:upper:]' '[:lower:]')
else
  echo "Could not determine Linux distribution"
  exit 1
fi

echo "Detected distribution: $DISTRO"

# Create temporary files
TEMP_YML=$(mktemp)
cp "$LINUX_YML" "$TEMP_YML"

# Function to merge package lists
merge_package_lists() {
  local yaml_path=$1
  local packages=("${@:2}")

  # Get existing packages
  local existing_pkgs=$(yq eval "$yaml_path[]" "$TEMP_YML" 2>/dev/null)

  # Combine existing and new packages
  local all_pkgs=$(printf "%s\n%s\n" "$existing_pkgs" "$(printf "%s\n" "${packages[@]}")" | grep -v '^$' | sort -u)

  # Update the YAML file
  local temp_updated=$(mktemp)
  yq eval "$yaml_path = []" "$TEMP_YML" >"$temp_updated"

  # Add each package to the YAML
  echo "$all_pkgs" | while IFS= read -r pkg; do
    if [[ -n "$pkg" ]]; then
      yq eval -i "$yaml_path += [\"$pkg\"]" "$temp_updated"
    fi
  done

  # Replace the temp file
  mv "$temp_updated" "$TEMP_YML"
}

# Handle different distributions
case $DISTRO in
debian | ubuntu | pop | mint | elementary)
  echo "Collecting packages for Debian-based system..."
  if command -v apt-mark &>/dev/null; then
    # Get manually installed packages, excluding some system packages
    PACKAGES=($(apt-mark showmanual | grep -v -E '^(apt|systemd|linux-image|grub|bash|coreutils)' | sort))

    # Merge with existing packages
    merge_package_lists ".packages.debian.apt" "${PACKAGES[@]}"
  else
    echo "apt-mark not found. Cannot determine manually installed packages."
  fi
  ;;

fedora | centos | rhel | rocky)
  echo "Collecting packages for Fedora/RHEL-based system..."
  if command -v dnf &>/dev/null; then
    # Get user-installed packages
    PACKAGES=($(dnf repoquery --userinstalled | grep -v '@System' | cut -d'-' -f1 | sort -u))

    # Merge with existing packages
    merge_package_lists ".packages.fedora.dnf" "${PACKAGES[@]}"
  else
    echo "dnf not found. Cannot determine user-installed packages."
  fi
  ;;

*)
  echo "Distribution $DISTRO not supported for automatic package detection."
  ;;
esac

# Handle Homebrew packages if installed
if command -v brew &>/dev/null; then
  echo "Collecting Homebrew packages..."

  # Get formulae (brews)
  FORMULAS=($(brew list --formula))
  merge_package_lists ".packages.brew.brews" "${FORMULAS[@]}"

  # Get casks
  CASKS=($(brew list --cask))
  merge_package_lists ".packages.brew.casks" "${CASKS[@]}"
fi

# Replace original file with the updated one
mv "$TEMP_YML" "$LINUX_YML"

echo "linux.yml has been updated with installed packages."
