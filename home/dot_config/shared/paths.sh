#!/bin/sh

pathappend() {
	if ! echo "$PATH" | /bin/grep -Eq "(^|:)$1($|:)" && [ -d "$1" ]; then
		export PATH="$PATH:$1"
	fi
}

pathprepend() {
	if ! echo "$PATH" | /bin/grep -Eq "(^|:)$1($|:)" && [ -d "$1" ]; then
		export PATH="$1:$PATH"
	fi
}

command_exists() {
	command -v "$@" >/dev/null 2>&1
}

# Main bin
pathprepend "$HOME/bin"
pathprepend "$HOME/.local/bin"
pathprepend "/usr/local/sbin"
pathprepend "/usr/bin"

# vscode (in case user turn off the `interop` settings in WSL)
if uname -r | grep -q microsoft; then
	if command_exists code && command_exists wslvar; then
		windows_user_home="$(wslpath "$(wslvar USERPROFILE)")"

		if [ -d "$windows_user_home/AppData/Local/Programs/Microsoft VS Code/bin" ]; then
			pathprepend "$windows_user_home/AppData/Local/Programs/Microsoft VS Code/bin"
		fi

		unset windows_user_home
	fi
fi

# ----------------------
# add more paths below:

# npm global packages
pathprepend "$HOME/.npm-global/bin"

# Homebrew
if [ -d "/home/linuxbrew/.linuxbrew" ]; then
	pathprepend "/home/linuxbrew/.linuxbrew/bin"
	pathprepend "/home/linuxbrew/.linuxbrew/sbin"
fi

# Rust/Cargo
pathprepend "$HOME/.cargo/bin"

# System bins
pathprepend "/usr/local/bin"
pathprepend "/bin"

# Go path
if command_exists go || [ -d "$HOME/.go" ]; then
	export GOPATH="$HOME/.go"
	pathprepend "$GOPATH/bin"
fi

if [[ -f "/home/linuxbrew/.linuxbrew/bin/brew" ]]; then
	eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi
