#!/bin/bash

# cmpack.sh - macOS equivalent of cmpack.ps1 for brew package management
# Updates chezmoi manifest with currently installed brew packages

set -euo pipefail

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

# Check if brew is installed
if ! command -v brew &> /dev/null; then
    print_color "$RED" "❌ Homebrew not found. Please install Homebrew first."
    exit 1
fi

# Determine the manifest file path
if [[ -n "${DOTS:-}" ]]; then
    YAML_FILE="$DOTS/.chezmoidata/brews.yml"
else
    YAML_FILE="$HOME/.local/share/chezmoi/home/.chezmoidata/brews.yml"
fi

if [[ ! -f "$YAML_FILE" ]]; then
    print_color "$RED" "❌ Manifest file not found at: $YAML_FILE"
    exit 1
fi

# Create backup
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
BACKUP_DIR="$HOME/.config/chezmoi/backups"
mkdir -p "$BACKUP_DIR"
BACKUP_PATH="$BACKUP_DIR/brews.yml.bak.$TIMESTAMP"
cp "$YAML_FILE" "$BACKUP_PATH"
print_color "$GRAY" "💾 Created backup at $BACKUP_PATH"

# Get currently installed packages
print_color "$BLUE" "🔍 Getting installed brew packages..."
INSTALLED_BREWS=($(brew list --formula | sort))
INSTALLED_CASKS=($(brew list --cask | sort))

print_color "$CYAN" "Found ${#INSTALLED_BREWS[@]} installed formulas and ${#INSTALLED_CASKS[@]} casks"

# Parse current manifest to get existing packages
CURRENT_BREWS=()
CURRENT_CASKS=()
IN_DARWIN_BREWS=false
IN_DARWIN_CASKS=false
IN_SHARED_BREWS=false
IN_SHARED_CASKS=false

while IFS= read -r line; do
    # Check section headers
    if [[ "$line" =~ ^[[:space:]]*darwin:[[:space:]]*$ ]]; then
        IN_DARWIN_BREWS=false
        IN_DARWIN_CASKS=false
        IN_SHARED_BREWS=false
        IN_SHARED_CASKS=false
    elif [[ "$line" =~ ^[[:space:]]*shared:[[:space:]]*$ ]]; then
        IN_DARWIN_BREWS=false
        IN_DARWIN_CASKS=false
        IN_SHARED_BREWS=false
        IN_SHARED_CASKS=false
    elif [[ "$line" =~ ^[[:space:]]*brews:[[:space:]]*$ ]]; then
        if [[ "$IN_DARWIN_BREWS" == false && "$IN_SHARED_BREWS" == false ]]; then
            # Determine if we're in darwin or shared section
            if grep -B10 "brews:" "$YAML_FILE" | tail -10 | grep -q "darwin:"; then
                IN_DARWIN_BREWS=true
            else
                IN_SHARED_BREWS=true
            fi
        fi
    elif [[ "$line" =~ ^[[:space:]]*casks:[[:space:]]*$ ]]; then
        if [[ "$IN_DARWIN_CASKS" == false && "$IN_SHARED_CASKS" == false ]]; then
            # Determine if we're in darwin or shared section
            if grep -B10 "casks:" "$YAML_FILE" | tail -10 | grep -q "darwin:"; then
                IN_DARWIN_CASKS=true
            else
                IN_SHARED_CASKS=true
            fi
        fi
    # Parse package entries
    elif [[ "$line" =~ ^[[:space:]]*-[[:space:]]+([^[:space:]]+) ]]; then
        PKG="${BASH_REMATCH[1]}"
        if [[ "$IN_DARWIN_BREWS" == true || "$IN_SHARED_BREWS" == true ]]; then
            CURRENT_BREWS+=("$PKG")
        elif [[ "$IN_DARWIN_CASKS" == true || "$IN_SHARED_CASKS" == true ]]; then
            CURRENT_CASKS+=("$PKG")
        fi
    fi
done < "$YAML_FILE"

# Find differences
NEW_BREWS=()
NEW_CASKS=()
REMOVED_BREWS=()
REMOVED_CASKS=()

# Find new packages
for pkg in "${INSTALLED_BREWS[@]}"; do
    if [[ ! " ${CURRENT_BREWS[*]} " =~ " ${pkg} " ]]; then
        NEW_BREWS+=("$pkg")
    fi
done

for pkg in "${INSTALLED_CASKS[@]}"; do
    if [[ ! " ${CURRENT_CASKS[*]} " =~ " ${pkg} " ]]; then
        NEW_CASKS+=("$pkg")
    fi
done

# Find removed packages (only check darwin section, not shared)
CURRENT_DARWIN_BREWS=()
CURRENT_DARWIN_CASKS=()
IN_DARWIN_SECTION=false

while IFS= read -r line; do
    if [[ "$line" =~ ^[[:space:]]*darwin:[[:space:]]*$ ]]; then
        IN_DARWIN_SECTION=true
    elif [[ "$line" =~ ^[[:space:]]*shared:[[:space:]]*$ ]]; then
        IN_DARWIN_SECTION=false
    elif [[ "$IN_DARWIN_SECTION" == true ]]; then
        if [[ "$line" =~ ^[[:space:]]*brews:[[:space:]]*$ ]]; then
            IN_DARWIN_BREWS=true
            IN_DARWIN_CASKS=false
        elif [[ "$line" =~ ^[[:space:]]*casks:[[:space:]]*$ ]]; then
            IN_DARWIN_BREWS=false
            IN_DARWIN_CASKS=true
        elif [[ "$line" =~ ^[[:space:]]*-[[:space:]]+([^[:space:]]+) ]]; then
            PKG="${BASH_REMATCH[1]}"
            if [[ "$IN_DARWIN_BREWS" == true ]]; then
                CURRENT_DARWIN_BREWS+=("$PKG")
            elif [[ "$IN_DARWIN_CASKS" == true ]]; then
                CURRENT_DARWIN_CASKS+=("$PKG")
            fi
        fi
    fi
done < "$YAML_FILE"

for pkg in "${CURRENT_DARWIN_BREWS[@]}"; do
    if [[ ! " ${INSTALLED_BREWS[*]} " =~ " ${pkg} " ]]; then
        REMOVED_BREWS+=("$pkg")
    fi
done

for pkg in "${CURRENT_DARWIN_CASKS[@]}"; do
    if [[ ! " ${INSTALLED_CASKS[*]} " =~ " ${pkg} " ]]; then
        REMOVED_CASKS+=("$pkg")
    fi
done

# Check if any changes are needed
if [[ ${#NEW_BREWS[@]} -eq 0 && ${#NEW_CASKS[@]} -eq 0 && ${#REMOVED_BREWS[@]} -eq 0 && ${#REMOVED_CASKS[@]} -eq 0 ]]; then
    print_color "$GREEN" "✅ No changes needed - manifest is up to date"
    exit 0
fi

# Report changes
if [[ ${#NEW_BREWS[@]} -gt 0 ]]; then
    print_color "$BLUE" "📝 Adding ${#NEW_BREWS[@]} new brew formulas to manifest..."
fi
if [[ ${#NEW_CASKS[@]} -gt 0 ]]; then
    print_color "$BLUE" "📝 Adding ${#NEW_CASKS[@]} new casks to manifest..."
fi
if [[ ${#REMOVED_BREWS[@]} -gt 0 ]]; then
    print_color "$YELLOW" "🗑️  Removing ${#REMOVED_BREWS[@]} uninstalled formulas from manifest..."
fi
if [[ ${#REMOVED_CASKS[@]} -gt 0 ]]; then
    print_color "$YELLOW" "🗑️  Removing ${#REMOVED_CASKS[@]} uninstalled casks from manifest..."
fi

# Create updated content
TEMP_FILE=$(mktemp)
IN_DARWIN_SECTION=false
IN_DARWIN_BREWS=false
IN_DARWIN_CASKS=false

while IFS= read -r line; do
    # Track sections
    if [[ "$line" =~ ^[[:space:]]*darwin:[[:space:]]*$ ]]; then
        IN_DARWIN_SECTION=true
        IN_DARWIN_BREWS=false
        IN_DARWIN_CASKS=false
    elif [[ "$line" =~ ^[[:space:]]*shared:[[:space:]]*$ ]]; then
        IN_DARWIN_SECTION=false
        IN_DARWIN_BREWS=false
        IN_DARWIN_CASKS=false
    elif [[ "$IN_DARWIN_SECTION" == true ]]; then
        if [[ "$line" =~ ^[[:space:]]*brews:[[:space:]]*$ ]]; then
            IN_DARWIN_BREWS=true
            IN_DARWIN_CASKS=false
        elif [[ "$line" =~ ^[[:space:]]*casks:[[:space:]]*$ ]]; then
            IN_DARWIN_BREWS=false
            IN_DARWIN_CASKS=true
        fi
    fi

    # Skip removed packages
    SKIP_LINE=false
    if [[ "$line" =~ ^[[:space:]]*-[[:space:]]+([^[:space:]]+) ]]; then
        PKG="${BASH_REMATCH[1]}"
        if [[ "$IN_DARWIN_BREWS" == true && " ${REMOVED_BREWS[*]} " =~ " ${PKG} " ]]; then
            SKIP_LINE=true
        elif [[ "$IN_DARWIN_CASKS" == true && " ${REMOVED_CASKS[*]} " =~ " ${PKG} " ]]; then
            SKIP_LINE=true
        fi
    fi

    if [[ "$SKIP_LINE" == false ]]; then
        echo "$line" >> "$TEMP_FILE"
    fi

    # Add new packages at the end of each section
    if [[ "$IN_DARWIN_BREWS" == true && "$line" =~ ^[[:space:]]*-[[:space:]]+ ]]; then
        # Check if this is the last brew in the section
        NEXT_LINE=$(sed -n "$((NR+1))p" "$YAML_FILE" 2>/dev/null || echo "")
        if [[ ! "$NEXT_LINE" =~ ^[[:space:]]*-[[:space:]]+ ]]; then
            # Add new brews
            for pkg in "${NEW_BREWS[@]}"; do
                echo "      - $pkg" >> "$TEMP_FILE"
            done
            NEW_BREWS=()  # Clear array to avoid duplicates
        fi
    elif [[ "$IN_DARWIN_CASKS" == true && "$line" =~ ^[[:space:]]*-[[:space:]]+ ]]; then
        # Check if this is the last cask in the section
        NEXT_LINE=$(sed -n "$((NR+1))p" "$YAML_FILE" 2>/dev/null || echo "")
        if [[ ! "$NEXT_LINE" =~ ^[[:space:]]*-[[:space:]]+ ]]; then
            # Add new casks
            for pkg in "${NEW_CASKS[@]}"; do
                echo "      - $pkg" >> "$TEMP_FILE"
            done
            NEW_CASKS=()  # Clear array to avoid duplicates
        fi
    fi
done < "$YAML_FILE"

# Handle case where sections are empty and we need to add first packages
if [[ ${#NEW_BREWS[@]} -gt 0 ]]; then
    # Find the brews section and add packages
    sed -i '' '/^[[:space:]]*brews:[[:space:]]*$/a\
'"$(printf '      - %s\n' "${NEW_BREWS[@]}")" "$TEMP_FILE"
fi

if [[ ${#NEW_CASKS[@]} -gt 0 ]]; then
    # Find the casks section and add packages
    sed -i '' '/^[[:space:]]*casks:[[:space:]]*$/a\
'"$(printf '      - %s\n' "${NEW_CASKS[@]}")" "$TEMP_FILE"
fi

# Replace original file
mv "$TEMP_FILE" "$YAML_FILE"

# Report success
if [[ ${#NEW_BREWS[@]} -gt 0 ]]; then
    print_color "$GREEN" "✅ Successfully added new brew formulas:"
    for pkg in "${NEW_BREWS[@]}"; do
        print_color "$CYAN" "  + $pkg"
    done
fi

if [[ ${#NEW_CASKS[@]} -gt 0 ]]; then
    print_color "$GREEN" "✅ Successfully added new casks:"
    for pkg in "${NEW_CASKS[@]}"; do
        print_color "$CYAN" "  + $pkg"
    done
fi

if [[ ${#REMOVED_BREWS[@]} -gt 0 ]]; then
    print_color "$GREEN" "✅ Successfully removed uninstalled formulas:"
    for pkg in "${REMOVED_BREWS[@]}"; do
        print_color "$RED" "  - $pkg"
    done
fi

if [[ ${#REMOVED_CASKS[@]} -gt 0 ]]; then
    print_color "$GREEN" "✅ Successfully removed uninstalled casks:"
    for pkg in "${REMOVED_CASKS[@]}"; do
        print_color "$RED" "  - $pkg"
    done
fi

echo ""
print_color "$GREEN" "✨ DONE! Run 'chezmoi apply' to apply your changes."