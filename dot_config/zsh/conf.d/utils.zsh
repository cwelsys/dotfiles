export ZSH_PLUGINS_ALIAS_TIPS_TEXT="tip: "
export ZSH_PLUGINS_ALIAS_TIPS_EXCLUDES="_ ll vi s l la g d z yay paru"

fzf-atuin-history-widget() {
  local selected num
  setopt localoptions noglobsubst noposixbuiltins pipefail no_aliases 2>/dev/null
  selected=$(atuin search --cmd-only --limit ${ATUIN_LIMIT:-5000} | tac |
    FZF_DEFAULT_OPTS="--height ${FZF_TMUX_HEIGHT:-40%} $FZF_DEFAULT_OPTS -n2..,.. --tiebreak=index --bind=ctrl-r:toggle-sort,ctrl-z:ignore $FZF_CTRL_R_OPTS --query=${LBUFFER} +m" fzf)
  local ret=$?
  if [[ -n $selected ]]; then
    LBUFFER+="${selected}"
  fi
  zle reset-prompt
  return $ret
}
zle -N fzf-atuin-history-widget
bindkey '^R' fzf-atuin-history-widget

iconcp() {
  local char="${1:-$(cat)}"
  python3 -c "print(''.join(f'U+{ord(c):04X} ' for c in '$char').strip())"
}
