function cdl() {
	cd "$@" && ls -la
}

fdz-widget() {
	BUFFER="fdz"
	zle accept-line
}
zle -N fdz-widget

rgz-widget() {
	BUFFER="rgz"
	zle accept-line
}
zle -N rgz-widget

function fg-fzf() {
  job="$(jobs | fzf -0 -1 | sed -E 's/\[(.+)\].*/\1/')" && echo '' && fg %$job
}
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

export _ZO_FZF_OPTS=$FZF_DEFAULT_OPTS'
--height=7'

function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	yazi "$@" --cwd-file="$tmp"
	if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
		builtin cd -- "$cwd"
	fi
	rm -f -- "$tmp"
}

function do-nothing() {
}
zle -N do-nothing

# Bind F13 to the no-op function
bindkey '^[[25~' do-nothing
bindkey '^[[1;2P' do-nothing
bindkey '^[[[E' do-nothing
