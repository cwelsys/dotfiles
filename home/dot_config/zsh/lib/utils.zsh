function cdl() {
	cd "$@" && ls -la
}

fdz-widget() {
	BUFFER="fdz"
	zle accept-line
}
zle -N fdz-widget
bindkey '^F' fdz-widget

rgz-widget() {
	BUFFER="rgz"
	zle accept-line
}
zle -N rgz-widget
bindkey '^G' rgz-widget

function fancy-ctrl-z () {
  if [[ $#BUFFER -eq 0 ]]; then
    BUFFER=" fg-fzf"
    zle accept-line -w
  else
    zle push-input -w
    zle clear-screen -w
  fi
}
zle -N fancy-ctrl-z
bindkey '^Z' fancy-ctrl-z

.zle_select-all () {
  (( CURSOR=0 ))
  (( MARK=$#BUFFER ))
  (( REGION_ACTIVE=1 ))
}
zle -N       .zle_select-all
bindkey '^A' .zle_select-all

.zle_smart-backspace () {
  if (( REGION_ACTIVE )); then
    zle kill-region
  else
    zle backward-delete-char
  fi
}
zle -N       .zle_smart-backspace
bindkey '^?' .zle_smart-backspace

.zle_smart-ctrl-backspace () {
  if (( REGION_ACTIVE )); then
    zle kill-region
  else
    zle backward-kill-word
  fi
}
zle -N       .zle_smart-ctrl-backspace
bindkey '^H' .zle_smart-ctrl-backspace

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

function omzPlugin() {
  zinit ice atpull"%atclone" atclone"_fix-omz-plugin" lucid $2
  zinit snippet OMZP::$1
}

function omzLib() {
  zinit wait'!' lucid for OMZL::$1
}

function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	yazi "$@" --cwd-file="$tmp"
	if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
		builtin cd -- "$cwd"
	fi
	rm -f -- "$tmp"
}

