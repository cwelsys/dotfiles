#!/bin/bash

# set XDG Base for all login shells
sudo tee /etc/profile.d/xdg-base-dirs.sh >/dev/null <<'EOF'
#!/bin/sh
# XDG Base Directory Specification
# Loaded by /etc/profile for all login shells including SSH sessions

export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
export XDG_BIN_HOME="${XDG_BIN_HOME:-$HOME/.local/bin}"
export XDG_PROJECTS_DIR="${XDG_PROJECTS_DIR:-$HOME/Projects}"
EOF

sudo chmod +x /etc/profile.d/xdg-base-dirs.sh

# preserves kitty ssh's shell integration injection
sudo tee /etc/zsh/zshenv >/dev/null <<'EOF'
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
if [[ -z "$KITTY_ORIG_ZDOTDIR" ]]; then
    export ZDOTDIR="$XDG_CONFIG_HOME/zsh"
fi
EOF

# tell bash to source ~/.bashrc from /etc/bash.bashrc
if [ -f /etc/bash.bashrc ]; then
  if ! grep -q "source.*\.bashrc" /etc/bash.bashrc; then
    sudo tee -a /etc/bash.bashrc >/dev/null <<'EOF'

# Source user's .bashrc if it exists
if [ -f "$HOME/.bashrc" ]; then
    source "$HOME/.bashrc"
fi
EOF
  fi
fi

if [ -f /etc/pulse/client.conf ]; then
  sudo sed -i 's|^; cookie-file =.*|cookie-file = ~/.config/pulse/cookie|' /etc/pulse/client.conf
fi
