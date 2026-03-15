#!/bin/sh

prepend_path() {
  case ":$PATH:" in
  *":$1:"*) ;;
  *) PATH="$1${PATH:+:$PATH}" ;;
  esac
}

prepend_path "/usr/bin"
prepend_path "/usr/local/bin"
prepend_path "/usr/local/sbin"

prepend_path "${XDG_DATA_HOME:-$HOME/.local/share}/npm/bin"
prepend_path "${GOBIN:-$HOME/.local/share/go/bin}"
prepend_path "${CARGO_HOME:-$HOME/.local/share/cargo}/bin"
prepend_path "${XDG_BIN_HOME:-$HOME/.local/bin}"

export PATH
