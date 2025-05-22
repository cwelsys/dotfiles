#!/usr/bin/env bash

has() {
	command -v $1 >/dev/null
}

if has rsync; then
	alias rcp='rsync --recursive --times --progress --stats --human-readable'
	alias rmv='rsync --recursive --times --progress --stats --human-readable --remove-source-files'
fi

# Others
alias c='clear'
alias cls='clear'
alias csl='clear'
alias ld='lazydocker'
alias lg='lazygit'
alias rl='source ~/.zshrc'
alias sv='sudo -E nvim'
alias v='nvim'
alias yz='yazi'

# package managers
alias npm-ls="npm list -g"
alias pnpm-ls="pnpm list -g"
alias bun-ls="bun pm ls -g"
alias gems="gem list"
alias go-ls="go-global-update --dry-run"
alias dnf="sudo dnf"
alias ..='cd ..'
alias ...='cd ../..'
alias .3='cd ../../..'
alias .4='cd ../../../..'
alias .5='cd ../../../../..'
alias cdc='cd ~/.config/'
alias cdcm='cd ~/.local/share/chezmoi/'

cmc() {
	{ [ -n "$1" ] && chezmoi git "commit -m \"$1\"" || chezmoi git "commit"; } && chezmoi git push
}
cms() {
	chezmoi re-add
	chezmoi git "f" || {
		echo 'No "f" alias for git!'
		cmc
	}
}
alias cm='chezmoi'
alias cma='chezmoi add'
alias cme='chezmoi edit'
alias cmra='chezmoi re-add'
alias t='tmux'
alias ta='tmux has-session &>/dev/null && tmux attach || tmux new-session'
alias mkdir='mkdir -p'

# eza
# if command -v eza >/dev/null 2>&1; then
# 	alias ls="eza --icons --color --header --hyperlink --group --git --group-directories-first"
# 	alias la="ls -al --sort=modified"
# 	alias lD="ls -lDa --show-symlinks --time-style=relative --grid"
# 	alias lF="ls -lfa --show-symlinks --time-style=relative --grid"
# 	alias ll="ls -lbhHigUmuSa --time-style=relative --sort=modified --reverse --grid"
# 	alias lo="ls --oneline"
# 	alias tree="ls --tree"
# fi

if command -v eza >/dev/null 2>&1; then
	EZA_OPTS=(
		'--colour=always'
		'--group-directories-first'
		'--icons=auto'
		'--ignore-glob=".DS_Store|.idea|.venv|.vs|__pycache__|cache|debug|.git|node_modules|venv"'
		'-s Name'
	)
	alias ls='eza $eza_params'
	alias l='eza --git-ignore $eza_params'
	alias ll='eza --all --header --long $eza_params'
	alias llm='eza --all --header --long --sort=modified $eza_params'
	alias la='eza -lbhHigUmuSa'
	alias lx='eza -lbhHigUmuSa@'
	alias lt='eza --tree $eza_params'
	alias tree='eza --tree $eza_params'
else
	alias ls='ls -A --color=auto'
	alias ll='ls -lAg --color=auto'
fi

yzcd() {
	local tmp=$(mktemp)
	yazi "$@" --cwd-file="$tmp"
	local cwd=$(<"$tmp")
	if [[ -n "$cwd" && "$cwd" != "$PWD" ]]; then
		cd "$cwd"
	fi
	rm "$tmp"
}
