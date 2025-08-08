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

# Check if we're currently the user we want to rename
if [ "$USER" = "$OLD_USER" ]; then
    echo -e "${YELLOW}Cannot rename user while logged in as that user${NC}"
    echo -e "${YELLOW}Creating new user $NEW_USER and setting up rename service...${NC}"
    
    # Create the new user with same groups as old user
    OLD_GROUPS=$(groups "$OLD_USER" | cut -d: -f2 | sed 's/^ //')
    sudo useradd -m -s /bin/zsh "$NEW_USER"
    
    # Add new user to same groups as old user
    for group in $OLD_GROUPS; do
        if [ "$group" != "$OLD_USER" ]; then
            sudo usermod -aG "$group" "$NEW_USER" || true
        fi
    done
    
    # Copy home directory contents
    sudo cp -r "/home/$OLD_USER"/. "/home/$NEW_USER/"
    sudo chown -R "$NEW_USER:$NEW_USER" "/home/$NEW_USER"
    
    # Set same password (copy from shadow)
    OLD_HASH=$(sudo getent shadow "$OLD_USER" | cut -d: -f2)
    sudo usermod -p "$OLD_HASH" "$NEW_USER"
    
    # Create one-time service to remove old user on next boot
    sudo tee /etc/systemd/system/remove-parallels-user.service > /dev/null <<EOF
[Unit]
Description=Remove old parallels user after reboot
After=multi-user.target

[Service]
Type=oneshot
ExecStart=/bin/bash -c 'pkill -u parallels || true; sleep 5; userdel -r parallels || true; rm -f /etc/systemd/system/remove-parallels-user.service; systemctl daemon-reload'
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF
    
    sudo systemctl enable remove-parallels-user.service
    
    echo -e "${GREEN}Created user $NEW_USER successfully${NC}"
    echo -e "${YELLOW}Old user will be removed on next reboot${NC}"
    echo -e "${RED}IMPORTANT: Log out and log in as '$NEW_USER' now!${NC}"
    
else
    # We're not the old user, so we can rename directly
    echo -e "${YELLOW}Renaming user $OLD_USER to $NEW_USER...${NC}"
    
    # Kill processes for old user
    sudo pkill -u "$OLD_USER" || true
    sleep 2
    sudo pkill -9 -u "$OLD_USER" || true
    
    # Rename the user
    sudo usermod -l "$NEW_USER" "$OLD_USER"
    sudo groupmod -n "$NEW_USER" "$OLD_USER"
    sudo usermod -d "/home/$NEW_USER" -m "$NEW_USER"
    sudo usermod -c "$NEW_USER" "$NEW_USER"
    sudo chown -R "$NEW_USER:$NEW_USER" "/home/$NEW_USER"
    
    # Update sudoers if needed
    if [ -f "/etc/sudoers.d/50-$OLD_USER" ]; then
        sudo mv "/etc/sudoers.d/50-$OLD_USER" "/etc/sudoers.d/50-$NEW_USER"
        sudo sed -i "s/$OLD_USER/$NEW_USER/g" "/etc/sudoers.d/50-$NEW_USER"
    fi
    
    echo -e "${GREEN}Successfully renamed user $OLD_USER to $NEW_USER${NC}"
fi
