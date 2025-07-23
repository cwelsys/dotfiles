#!/bin/bash

set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[GPG-XDG]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[GPG-XDG]${NC} $1"
}

info() {
    echo -e "${BLUE}[GPG-XDG]${NC} $1"
}

# Handle GPG agent reconfiguration for XDG compliance
if command -v gpgconf >/dev/null 2>&1; then
    log "Reconfiguring GPG agent for XDG-compliant GNUPGHOME..."
    export GNUPGHOME="$XDG_DATA_HOME/gnupg"
    gpgconf --kill gpg-agent 2>/dev/null || true
    sleep 1
    gpgconf --launch gpg-agent 2>/dev/null || true
    if gpgconf --check-programs gpg-agent 2>/dev/null; then
        info "✓ GPG agent successfully reconfigured"
        info "  GNUPGHOME: $GNUPGHOME"
        if SSH_SOCKET=$(gpgconf --list-dirs agent-ssh-socket 2>/dev/null); then
            info "  SSH socket: $SSH_SOCKET"
        fi
    else
        warn "⚠ GPG agent may need manual restart"
    fi

    log "GPG agent XDG configuration completed"
    info "SSH agent integration will work after shell reload"

else
    warn "gpgconf not found - GPG not installed or not in PATH"
    info "Skipping GPG agent reconfiguration"
fi
