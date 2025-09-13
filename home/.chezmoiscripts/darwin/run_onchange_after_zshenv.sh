#!/bin/bash

set -eufo pipefail

sudo tee /etc/zshenv > /dev/null << 'EOF'
fpath+=("/opt/homebrew")

eval "$(/opt/homebrew/bin/brew shellenv)"

export ZDOTDIR="${XDG_CONFIG_HOME:-$HOME/.config}/zsh"

PATH=$PATH:/usr/local/bin
EOF

echo "zshenv (/etc/zshenv) configured"
