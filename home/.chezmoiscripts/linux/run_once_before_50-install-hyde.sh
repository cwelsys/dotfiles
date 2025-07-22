#!/usr/bin/env bash

set -eufo pipefail

if [ -d "~/.local/share/HyDE" ]; then
  exit 0
fi

git clone --depth 1 https://github.com/HyDE-Project/HyDE.git ~/.local/share/HyDE
~/.local/share/HyDE/Scripts/install.sh
