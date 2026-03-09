#!/usr/bin/env bash

if [[ "$SHELL" =~ .*zsh$ ]]; then
    echo "Shell is already set to zsh: $SHELL"
    exit 0
fi

if ! command -v zsh >/dev/null 2>&1; then
    echo "Error: zsh is not installed"
    exit 1
fi

ZSH_PATH=""
if grep -q "^/bin/zsh$" /etc/shells; then
    ZSH_PATH="/bin/zsh"
elif grep -q "^/usr/bin/zsh$" /etc/shells; then
    ZSH_PATH="/usr/bin/zsh"
else
    ZSH_PATH=$(which zsh)
    # Add zsh to /etc/shells if it's not there
    if ! grep -q "^$ZSH_PATH$" /etc/shells; then
        echo "Adding $ZSH_PATH to /etc/shells"
        echo "$ZSH_PATH" | sudo tee -a /etc/shells
    fi
fi

echo "Changing shell to: $ZSH_PATH"
if chsh -s "$ZSH_PATH"; then
    echo "Shell changed successfully to $ZSH_PATH"
    echo "Note: You may need to log out and back in for the change to take effect"
else
    echo "Failed to change shell. You may need to run: chsh -s $ZSH_PATH"
fi
