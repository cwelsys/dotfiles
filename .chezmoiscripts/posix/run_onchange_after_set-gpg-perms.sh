#!/usr/bin/env bash

if [ -z "${GNUPGHOME:-}" ]; then
    GNUPGHOME="$HOME/.local/share/gnupg"
fi

if [ -d "$GNUPGHOME" ]; then
    chown -R "$(whoami)" "$GNUPGHOME"
    find "$GNUPGHOME" -type d -exec chmod 700 {} \;
    find "$GNUPGHOME" -type f -exec chmod 600 {} \;
else
    echo "GPG directory $GNUPGHOME does not exist, skipping permission setup"
fi
