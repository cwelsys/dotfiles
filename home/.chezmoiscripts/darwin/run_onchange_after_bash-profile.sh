#!/bin/bash
if [ -f /etc/bashrc ]; then
	if ! grep -q "source.*\.bashrc" /etc/bashrc; then
		sudo tee -a /etc/bashrc >/dev/null <<'EOF'

if [ -f "$HOME/.bashrc" ]; then
    source "$HOME/.bashrc"
fi
EOF
	fi
fi
