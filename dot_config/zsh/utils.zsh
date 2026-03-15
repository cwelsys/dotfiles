export ZSH_PLUGINS_ALIAS_TIPS_TEXT="tip: "
export ZSH_PLUGINS_ALIAS_TIPS_EXCLUDES="_ ll vi s l la g d z yay paru"

fdz-widget() {
	fdz
	zle reset-prompt
}
zle -N fdz-widget
bindkey '^F' fdz-widget

  fzf-atuin-history-widget() {
    local selected num
    setopt localoptions noglobsubst noposixbuiltins pipefail no_aliases 2>/dev/null
    selected=$(atuin search --cmd-only --limit ${ATUIN_LIMIT:-5000} | tac |
      FZF_DEFAULT_OPTS="--height ${FZF_TMUX_HEIGHT:-40%} $FZF_DEFAULT_OPTS -n2..,.. --tiebreak=index --bind=ctrl-r:toggle-sort,ctrl-z:ignore $FZF_CTRL_R_OPTS --query=${LBUFFER} +m" fzf)
    local ret=$?
    if [ -n "$selected" ]; then
      LBUFFER+="${selected}"
    fi
    zle reset-prompt
    return $ret
  }
  zle -N fzf-atuin-history-widget
  bindkey '^R' fzf-atuin-history-widget

function omzPlugin() {
  zinit ice atpull"%atclone" atclone"_fix-omz-plugin" lucid $2
  zinit snippet OMZP::$1
}

function omzLib() {
  zinit wait'!' lucid for OMZL::$1
}

_fix-omz-plugin() {
  if [[ ! -f ._zinit/teleid ]] then return 0; fi
  if [[ ! $(cat ._zinit/teleid) =~ "^OMZP::.*" ]] then return 0; fi
  local OMZP_NAME=$(cat ._zinit/teleid | sed -n 's/OMZP:://p')
  git clone --quiet --no-checkout --depth=1 --filter=tree:0 https://github.com/ohmyzsh/ohmyzsh
  cd ohmyzsh
  git sparse-checkout set --no-cone plugins/$OMZP_NAME
  git checkout --quiet
  cd ..
  local OMZP_PATH="ohmyzsh/plugins/$OMZP_NAME"
  local file
  for file in ohmyzsh/plugins/$OMZP_NAME/*~(.gitignore|*.plugin.zsh)(D); do
    local filename="${file:t}"
    echo "Copying $file to $(pwd)/$filename..."
    cp -r $file $filename
  done
  rm -rf ohmyzsh
}

fdz() {
  local file
  file=$(fd --type file --follow --hidden --exclude .git | fzf \
    --height=90% \
    --prompt="Files> " \
    --bind="ctrl-t:transform:[[ \$FZF_PROMPT == *Directory* ]] && \
  echo change-prompt\\(Files\\> \\)+reload\\(fd --type file\\) || \
  echo change-prompt\\(Directory\\> \\)+reload\\(fd --type directory\\)" \
    --bind='load:transform:if (( FZF_COLUMNS < 120 )); then ph=$(( FZF_LINES - FZF_MATCH_COUNT - 8 )); echo change-preview-window\(bottom,$((ph > 10 ? ph : 10)),wrap,noinfo\); fi' \
    --bind='resize:transform:if (( FZF_COLUMNS < 120 )); then ph=$(( FZF_LINES - FZF_MATCH_COUNT - 8 )); echo change-preview-window\(bottom,$((ph > 10 ? ph : 10)),wrap,noinfo\); fi' \
    --preview="if echo \$FZF_PROMPT | grep -q 'Files> '; then \
      bat --color=always {} --style=plain; \
      else eza -T --colour=always --icons=always {}; fi")
  [ -n "$file" ] && _fzf_open_path "$file"
}


_fzf_open_path() {
  local file="$1"
  if [[ "$file" =~ ^.*:[0-9]+:.*$ ]]; then
    file=$(echo "$file" | cut -d: -f1)
  fi
  [ ! -e "$file" ] && return

  local cmd
  cmd=$(printf "bat\ncat\ncd\nvim\ncode\nrm\necho" | fzf --prompt="Select Command> ")
  case "$cmd" in
  bat) bat "$file" ;;
  cat) cat "$file" ;;
  cd) if [ -f "$file" ]; then cd "$(dirname "$file")"; else cd "$file"; fi ;;
  vim) vim "$file" ;;
  code) code "$file" ;;
  rm) rm -rf "$file" ;;
  echo) echo "$file" ;;
  esac
}

iconcp() {
  local char="${1:-$(cat)}"
  python3 -c "print(''.join(f'U+{ord(c):04X} ' for c in '$char').strip())"
}

