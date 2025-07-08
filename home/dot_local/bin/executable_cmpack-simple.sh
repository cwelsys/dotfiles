#!/bin/bash

# Simplified version for testing DNF package detection

set -eo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

print_color() {
    local color=$1
    local text=$2
    echo -e "${color}${text}${NC}"
}

print_color "$BLUE" "Testing DNF package detection..."

# Test different methods to get user-installed packages
echo "Method 1: dnf repoquery --userinstalled"
dnf repoquery --userinstalled --qf '%{name}' | head -20

echo ""
echo "Method 2: dnf history userinstalled"
dnf history userinstalled 2>/dev/null | head -20 || echo "Command failed"

echo ""
echo "Method 3: rpm -qa --qf '%{NAME} %{INSTALLTIME:date}\n'"
rpm -qa --qf '%{NAME} %{INSTALLTIME:date}\n' | sort -k2 | tail -20

print_color "$GREEN" "Done testing"