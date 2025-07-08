#!/bin/bash

# Test script for APT package detection

set -eo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

print_color() {
    local color=$1
    local text=$2
    echo -e "${color}${text}${NC}"
}

print_color "$BLUE" "Testing APT package detection methods..."

echo "Method 1: apt-mark showmanual (first 20 packages)"
apt-mark showmanual | head -20

echo ""
echo "Method 2: apt-mark showmanual | wc -l (total count)"
apt-mark showmanual | wc -l

echo ""
echo "Method 3: apt list --installed (first 10, manually installed only)"
apt list --installed 2>/dev/null | grep -v "automatic" | head -10

echo ""
echo "Method 4: Check for common dev tools"
for pkg in git curl wget nodejs npm python3-pip docker.io code firefox; do
    if apt-mark showmanual | grep -q "^${pkg}$"; then
        echo "✓ $pkg (manually installed)"
    else
        echo "✗ $pkg (not found in manual list)"
    fi
done

print_color "$GREEN" "APT testing complete"