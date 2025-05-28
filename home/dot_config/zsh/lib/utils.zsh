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

history-search-up() {
	zle set-local-history 1
	zle history-beginning-search-backward
	zle set-local-history 0
}
zle -N history-search-up

history-search-down() {
	zle set-local-history 1
	zle history-beginning-search-forward
	zle set-local-history 0
}
zle -N history-search-down

function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	yazi "$@" --cwd-file="$tmp"
	if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
		builtin cd -- "$cwd"
	fi
	rm -f -- "$tmp"
}
