#!/bin/sh
# PATH configuration
# Source this file from your shell RC file (.zshrc, .bashrc, etc.)

# Function to safely prepend to PATH (avoid duplicates)
prepend_path() {
    case ":$PATH:" in
        *":$1:"*) ;;
        *) PATH="$1${PATH:+:$PATH}" ;;
    esac
}

# System paths (prepend in reverse order of priority)
prepend_path "/usr/bin"
prepend_path "/usr/local/bin"
prepend_path "/usr/local/sbin"

# macOS specific paths
if [ "$(uname)" = "Darwin" ]; then
    prepend_path "/opt/homebrew/opt/openjdk/bin"
    prepend_path "/opt/homebrew/opt/ncurses/bin"
    prepend_path "/opt/vagrant/bin"
fi

# User paths (highest priority)
prepend_path "${XDG_DATA_HOME:-$HOME/.local/share}/npm/bin"
prepend_path "${GOBIN:-$HOME/.local/share/go/bin}"
prepend_path "${CARGO_HOME:-$HOME/.local/share/cargo}/bin"
prepend_path "${XDG_BIN_HOME:-$HOME/.local/bin}"
prepend_path "$HOME/bin"

export PATH
