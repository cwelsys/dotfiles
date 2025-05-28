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
alias lzd='lazydocker'
alias lzg='lazygit'
alias rl='reload'
alias sv='sudo -E nvim'
alias v='nvim'
alias vi='nvim'

# package managers
alias npm-ls="npm list -g"
alias pnpm-ls="pnpm list -g"
alias bun-ls="bun pm ls -g"
alias gems="gem list"
alias go-ls="go-global-update --dry-run"
alias dnf="sudo dnf"
alias apt="sudo apt"
alias apt-get="sudo apt-get"
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
alias cmu='chezmoi update'
alias cmra='chezmoi re-add'
alias t='tmux'
alias ta='tmux has-session &>/dev/null && tmux attach || tmux new-session'
alias mkdir='mkdir -p'
alias reload='exec $SHELL -l'
alias dots="cd $DOTFILES"

# eza
if command -v eza >/dev/null 2>&1; then
	eza_params=(
		'--icons=auto'
		'--group-directories-first'
		'--color=always'
		'--ignore-glob=".DS_Store|.idea|.venv|.vs|__pycache__|cache|debug|.git|node_modules|venv|*NTUSER.DAT*|*ntuser.dat*"'
	)
	alias ls='eza ${eza_params[@]}'
	alias l='eza --git-ignore ${eza_params[@]}'
	alias ld='eza --all --only-dirs ${eza_params[@]}'
	alias lf='eza --all --only-files ${eza_params[@]}'
	alias ll='eza --all --header --long --time-style=relative --sort=modified ${eza_params[@]}'
	alias la='eza --all --header --long ${eza_params[@]}'
	alias lo='eza --oneline ${eza_params[@]}'
	alias lx='eza --all --header --long --extended ${eza_params[@]}'
	alias lt='eza --tree ${eza_params[@]}'
	alias tree='eza --tree ${eza_params[@]}'
fi
