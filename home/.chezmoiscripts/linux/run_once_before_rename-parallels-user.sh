#!/bin/bash

set -e

GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m'

OLD_USER="parallels"
NEW_USER="cwel"

# Check if we're on a Parallels VM
if ! lspci | grep -q "Parallels"; then
    echo -e "${YELLOW}Not running on Parallels VM, skipping user rename${NC}"
    exit 0
fi

# Check if the old user exists
if ! id "$OLD_USER" &>/dev/null; then
    echo -e "${YELLOW}User $OLD_USER doesn't exist, skipping rename${NC}"
    exit 0
fi

# Check if new user already exists
if id "$NEW_USER" &>/dev/null; then
    echo -e "${YELLOW}User $NEW_USER already exists, skipping rename${NC}"
    exit 0
fi

echo -e "${YELLOW}Renaming user $OLD_USER to $NEW_USER...${NC}"

# Kill all processes for the old user (except current session)
sudo pkill -u "$OLD_USER" -f "(?!$$)" || true

# Rename the user
sudo usermod -l "$NEW_USER" "$OLD_USER"

# Rename the group
sudo groupmod -n "$NEW_USER" "$OLD_USER"

# Move and rename home directory
sudo usermod -d "/home/$NEW_USER" -m "$NEW_USER"

# Update user's full name/comment
sudo usermod -c "$NEW_USER" "$NEW_USER"

# Fix ownership of home directory
sudo chown -R "$NEW_USER:$NEW_USER" "/home/$NEW_USER"

# Update any references in system files
sudo sed -i "s/$OLD_USER/$NEW_USER/g" /etc/passwd 2>/dev/null || true
sudo sed -i "s/$OLD_USER/$NEW_USER/g" /etc/group 2>/dev/null || true
sudo sed -i "s/$OLD_USER/$NEW_USER/g" /etc/shadow 2>/dev/null || true

# Update sudoers if needed
if [ -f /etc/sudoers.d/50-$OLD_USER ]; then
    sudo mv "/etc/sudoers.d/50-$OLD_USER" "/etc/sudoers.d/50-$NEW_USER"
    sudo sed -i "s/$OLD_USER/$NEW_USER/g" "/etc/sudoers.d/50-$NEW_USER"
fi

echo -e "${GREEN}Successfully renamed user $OLD_USER to $NEW_USER${NC}"
echo -e "${YELLOW}Please log out and log back in as $NEW_USER to complete the transition${NC}"
