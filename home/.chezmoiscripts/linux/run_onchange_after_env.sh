#!/bin/bash

# Configure zsh to use XDG base directory
sudo tee /etc/zsh/zshenv > /dev/null <<'EOF'
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export ZDOTDIR="$XDG_CONFIG_HOME/zsh"
EOF

# Set up bash to source ~/.bashrc from /etc/bash.bashrc
if [ -f /etc/bash.bashrc ]; then
    if ! grep -q "source.*\.bashrc" /etc/bash.bashrc; then
        sudo tee -a /etc/bash.bashrc > /dev/null <<'EOF'

# Source user's .bashrc if it exists
if [ -f "$HOME/.bashrc" ]; then
    source "$HOME/.bashrc"
fi
EOF
    fi
fi
