#!/usr/bin/env bash

if [[ "$SHELL" =~ .*zsh$ ]]; then
	exit 0
fi

chsh -s "/bin/zsh"
