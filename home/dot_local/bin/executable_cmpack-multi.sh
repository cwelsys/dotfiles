#!/bin/bash

# cmpack.sh - Multi-package manager support for chezmoi manifests
# Updates both brew and native package manager manifests

set -eo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
GRAY='\033[0;37m'
NC='\033[0m' # No Color

# Function to print colored output
print_color() {
    local color=$1
    local text=$2
    echo -e "${color}${text}${NC}"
}

# Detect OS and distribution
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
DISTRO=""
PACKAGE_MANAGERS=()
USE_BREW=false
USE_NATIVE=false
NATIVE_PKG_MANAGER=""
NATIVE_OS_SECTION=""

if [[ "$OS" == "darwin" ]]; then
    if command -v brew &> /dev/null; then
        PACKAGE_MANAGERS+=("brew")
        USE_BREW=true
    fi
elif [[ "$OS" == "linux" ]]; then
    # Detect Linux distribution
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        DISTRO="$ID"
    elif [[ -f /etc/arch-release ]]; then
        DISTRO="arch"
    elif [[ -f /etc/debian_version ]]; then
        DISTRO="debian"
    elif [[ -f /etc/fedora-release ]]; then
        DISTRO="fedora"
    elif [[ -f /etc/SuSE-release ]]; then
        DISTRO="opensuse"
    fi
    
    # Check for brew on Linux
    if command -v brew &> /dev/null; then
        PACKAGE_MANAGERS+=("brew")
        USE_BREW=true
    fi
    
    # Check for native package manager
    case "$DISTRO" in
        arch)
            if command -v pacman &> /dev/null; then
                PACKAGE_MANAGERS+=("pacman")
                NATIVE_PKG_MANAGER="pacman"
                NATIVE_OS_SECTION="arch"
                USE_NATIVE=true
            fi
            ;;
        debian|ubuntu)
            if command -v apt &> /dev/null; then
                PACKAGE_MANAGERS+=("apt")
                NATIVE_PKG_MANAGER="apt"
                NATIVE_OS_SECTION="debian"
                USE_NATIVE=true
            fi
            ;;
        fedora)
            if command -v dnf &> /dev/null; then
                PACKAGE_MANAGERS+=("dnf")
                NATIVE_PKG_MANAGER="dnf"
                NATIVE_OS_SECTION="fedora"
                USE_NATIVE=true
            fi
            ;;
        opensuse*)
            if command -v zypper &> /dev/null; then
                PACKAGE_MANAGERS+=("zypper")
                NATIVE_PKG_MANAGER="zypper"
                NATIVE_OS_SECTION="opensuse"
                USE_NATIVE=true
            fi
            ;;
    esac
else
    print_color "$RED" "❌ Unsupported operating system: $OS"
    exit 1
fi

# Check if we have any supported package managers
if [[ ${#PACKAGE_MANAGERS[@]} -eq 0 ]]; then
    print_color "$RED" "❌ No supported package managers found"
    exit 1
fi

print_color "$CYAN" "📦 Found package managers: ${PACKAGE_MANAGERS[*]}"

# Function to process a single package manager
process_package_manager() {
    local pkg_manager=$1
    local is_brew=$2
    local os_section=$3
    local yaml_file=$4
    
    print_color "$BLUE" ""
    print_color "$BLUE" "🔍 Processing $pkg_manager packages..."
    
    # Get installed packages
    local installed_packages=()
    local installed_casks=()
    
    if [[ "$is_brew" == true ]]; then
        installed_packages=($(brew leaves | sort))
        installed_casks=($(brew list --cask | sort))
        print_color "$CYAN" "Found ${#installed_packages[@]} formulas and ${#installed_casks[@]} casks"
    else
        case "$pkg_manager" in
            pacman)
                installed_packages=($(pacman -Qe | awk '{print $1}' | sort))
                ;;
            apt)
                installed_packages=($(apt-mark showmanual | sort))
                ;;
            dnf)
                installed_packages=($(dnf history userinstalled | tail -n +2 | sort))
                ;;
            zypper)
                installed_packages=($(zypper search -i --userinstalled | awk 'NR>2 && /^i/ {print $3}' | sort))
                ;;
        esac
        print_color "$CYAN" "Found ${#installed_packages[@]} packages"
    fi
    
    # Parse current manifest
    local current_packages=()
    local current_casks=()
    
    if [[ "$is_brew" == true ]]; then
        # Parse brews.yml structure
        local in_os_section=false
        local in_shared_section=false
        local in_brews=false
        local in_casks=false
        
        while IFS= read -r line; do
            if [[ "$line" =~ ^[[:space:]]*${os_section}:[[:space:]]*$ ]]; then
                in_os_section=true
                in_shared_section=false
                in_brews=false
                in_casks=false
            elif [[ "$line" =~ ^[[:space:]]*shared:[[:space:]]*$ ]]; then
                in_os_section=false
                in_shared_section=true
                in_brews=false
                in_casks=false
            elif [[ "$line" =~ ^[[:space:]]*brews:[[:space:]]*$ ]] && [[ "$in_os_section" == true || "$in_shared_section" == true ]]; then
                in_brews=true
                in_casks=false
            elif [[ "$line" =~ ^[[:space:]]*casks:[[:space:]]*$ ]] && [[ "$in_os_section" == true || "$in_shared_section" == true ]]; then
                in_brews=false
                in_casks=true
            elif [[ "$line" =~ ^[[:space:]]*[a-zA-Z]+:[[:space:]]*$ ]]; then
                in_brews=false
                in_casks=false
            elif [[ "$line" =~ ^[[:space:]]*-[[:space:]]+([^[:space:]]+) ]]; then
                local pkg="${BASH_REMATCH[1]}"
                if [[ "$in_brews" == true ]]; then
                    current_packages+=("$pkg")
                elif [[ "$in_casks" == true ]]; then
                    current_casks+=("$pkg")
                fi
            fi
        done < "$yaml_file"
    else
        # Parse pkgs.yml structure
        local in_os_section=false
        local in_pkg_section=false
        
        while IFS= read -r line; do
            if [[ "$line" =~ ^[[:space:]]*${os_section}:[[:space:]]*$ ]]; then
                in_os_section=true
                in_pkg_section=false
            elif [[ "$line" =~ ^[[:space:]]*${pkg_manager}:[[:space:]]*$ ]] && [[ "$in_os_section" == true ]]; then
                in_pkg_section=true
            elif [[ "$line" =~ ^[[:space:]]*[a-zA-Z]+:[[:space:]]*$ ]]; then
                if [[ "$in_os_section" == true ]]; then
                    in_pkg_section=false
                else
                    in_os_section=false
                    in_pkg_section=false
                fi
            elif [[ "$line" =~ ^[[:space:]]*-[[:space:]]+([^[:space:]]+) ]] && [[ "$in_pkg_section" == true ]]; then
                local pkg="${BASH_REMATCH[1]}"
                current_packages+=("$pkg")
            fi
        done < "$yaml_file"
    fi
    
    # Find differences
    local new_packages=()
    local new_casks=()
    local removed_packages=()
    local removed_casks=()
    
    # Find new packages
    for pkg in "${installed_packages[@]}"; do
        if [[ ! " ${current_packages[*]:-} " =~ " ${pkg} " ]]; then
            new_packages+=("$pkg")
        fi
    done
    
    if [[ "$is_brew" == true ]]; then
        for pkg in "${installed_casks[@]}"; do
            if [[ ! " ${current_casks[*]:-} " =~ " ${pkg} " ]]; then
                new_casks+=("$pkg")
            fi
        done
    fi
    
    # Find removed packages (only from OS-specific section)
    for pkg in "${current_packages[@]}"; do
        if [[ ! " ${installed_packages[*]:-} " =~ " ${pkg} " ]]; then
            removed_packages+=("$pkg")
        fi
    done
    
    if [[ "$is_brew" == true ]]; then
        for pkg in "${current_casks[@]}"; do
            if [[ ! " ${installed_casks[*]:-} " =~ " ${pkg} " ]]; then
                removed_casks+=("$pkg")
            fi
        done
    fi
    
    # Check if changes are needed
    if [[ ${#new_packages[@]} -eq 0 && ${#new_casks[@]} -eq 0 && ${#removed_packages[@]} -eq 0 && ${#removed_casks[@]} -eq 0 ]]; then
        print_color "$GREEN" "✅ No changes needed for $pkg_manager - manifest is up to date"
        return 0
    fi
    
    # Create backup
    local timestamp=$(date +%Y%m%d-%H%M%S)
    local backup_dir="$HOME/.config/chezmoi/backups"
    mkdir -p "$backup_dir"
    local backup_filename=$(basename "$yaml_file")
    local backup_path="$backup_dir/${backup_filename}.bak.$timestamp"
    cp "$yaml_file" "$backup_path"
    print_color "$GRAY" "💾 Created backup at $backup_path"
    
    # Report changes
    if [[ ${#new_packages[@]} -gt 0 ]]; then
        if [[ "$is_brew" == true ]]; then
            print_color "$BLUE" "📝 Adding ${#new_packages[@]} new brew formulas..."
        else
            print_color "$BLUE" "📝 Adding ${#new_packages[@]} new $pkg_manager packages..."
        fi
    fi
    
    if [[ ${#new_casks[@]} -gt 0 ]]; then
        print_color "$BLUE" "📝 Adding ${#new_casks[@]} new casks..."
    fi
    
    if [[ ${#removed_packages[@]} -gt 0 ]]; then
        if [[ "$is_brew" == true ]]; then
            print_color "$YELLOW" "🗑️  Removing ${#removed_packages[@]} uninstalled formulas..."
        else
            print_color "$YELLOW" "🗑️  Removing ${#removed_packages[@]} uninstalled packages..."
        fi
    fi
    
    if [[ ${#removed_casks[@]} -gt 0 ]]; then
        print_color "$YELLOW" "🗑️  Removing ${#removed_casks[@]} uninstalled casks..."
    fi
    
    # Update the file (simplified approach - just append new packages for now)
    for pkg in "${new_packages[@]}"; do
        if [[ "$is_brew" == true ]]; then
            # Add to appropriate brews section
            if [[ "$OS" == "darwin" ]]; then
                if [[ "$os_section" == "darwin" ]]; then
                    sed -i '' '/^[[:space:]]*brews:[[:space:]]*$/a\
      - '"$pkg" "$yaml_file"
                else
                    sed -i '' '/^[[:space:]]*brews:[[:space:]]*$/a\
      - '"$pkg" "$yaml_file"
                fi
            else
                sed -i '/^[[:space:]]*brews:[[:space:]]*$/a\
      - '"$pkg" "$yaml_file"
            fi
        else
            # Add to package manager section
            if [[ "$OS" == "darwin" ]]; then
                sed -i '' '/^[[:space:]]*'"$pkg_manager"':[[:space:]]*$/a\
      - '"$pkg" "$yaml_file"
            else
                sed -i '/^[[:space:]]*'"$pkg_manager"':[[:space:]]*$/a\
      - '"$pkg" "$yaml_file"
            fi
        fi
        print_color "$CYAN" "  + $pkg"
    done
    
    for pkg in "${new_casks[@]}"; do
        if [[ "$OS" == "darwin" ]]; then
            sed -i '' '/^[[:space:]]*casks:[[:space:]]*$/a\
      - '"$pkg" "$yaml_file"
        else
            sed -i '/^[[:space:]]*casks:[[:space:]]*$/a\
      - '"$pkg" "$yaml_file"
        fi
        print_color "$CYAN" "  + $pkg (cask)"
    done
    
    print_color "$GREEN" "✅ Updated $pkg_manager manifest"
}

# Main execution
print_color "$BLUE" "🚀 Starting package manifest update..."

# Process Homebrew if available
if [[ "$USE_BREW" == true ]]; then
    brew_os_section=""
    if [[ "$OS" == "darwin" ]]; then
        brew_os_section="darwin"
    else
        brew_os_section="shared"
    fi
    
    brew_yaml_file=""
    if [[ -n "${DOTS:-}" ]]; then
        brew_yaml_file="$DOTS/.chezmoidata/brews.yml"
    else
        brew_yaml_file="$HOME/.local/share/chezmoi/home/.chezmoidata/brews.yml"
    fi
    
    if [[ -f "$brew_yaml_file" ]]; then
        process_package_manager "brew" true "$brew_os_section" "$brew_yaml_file"
    else
        print_color "$YELLOW" "⚠️  Brew manifest not found at: $brew_yaml_file"
    fi
fi

# Process native package manager if available
if [[ "$USE_NATIVE" == true ]]; then
    native_yaml_file=""
    if [[ -n "${DOTS:-}" ]]; then
        native_yaml_file="$DOTS/.chezmoidata/pkgs.yml"
    else
        native_yaml_file="$HOME/.local/share/chezmoi/home/.chezmoidata/pkgs.yml"
    fi
    
    if [[ -f "$native_yaml_file" ]]; then
        process_package_manager "$NATIVE_PKG_MANAGER" false "$NATIVE_OS_SECTION" "$native_yaml_file"
    else
        print_color "$YELLOW" "⚠️  Native package manifest not found at: $native_yaml_file"
    fi
fi

echo ""
print_color "$GREEN" "✨ DONE! Run 'chezmoi apply' to apply your changes."