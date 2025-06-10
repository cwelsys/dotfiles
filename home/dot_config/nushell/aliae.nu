alias c = clear
alias lzd = lazydocker
alias lzg = lazygit
alias lg = lazygit
alias tg = topgrade
alias rl = exec nu -l
alias v = nvim
alias vi = nvim
alias npm-ls = npm list -g
alias pnpm-ls = pnpm list -g
alias bun-ls = bun pm ls -g
alias gems = gem list
alias go-ls = go-global-update --dry-run
alias cdc = cd ~/.config/
alias cdcm = cd ~/.local/share/chezmoi/
alias cm = chezmoi
alias cma = chezmoi add
alias cme = chezmoi edit
alias cmu = chezmoi update
alias cmapl = chezmoi apply
alias cmra = chezmoi re-add
alias qq = exit
alias dots = cd $env.DOTFILES
alias cat = bat --paging=never --style=plain
alias fuck = thefuck $"(history | last 1 | get command | get 0)"
alias tf = fuck

def cmc [message?: string] {
  if $message != null {
    chezmoi git commit -m $message
  } else {
    chezmoi git commit
  }
  chezmoi git push
}

def cms [] {
  chezmoi re-add
  try {
    chezmoi git f
  } catch {
    echo 'No "f" alias for git!'
    cmc
  }
}

let eza_params = [
  "--icons=auto"
  "--group-directories-first"
  "--color=always"
  "--ignore-glob=.DS_Store|.idea|.venv|.vs|__pycache__|cache|debug|.git|node_modules|venv|*NTUSER.DAT*|*ntuser.dat*"
]

alias ls = ^eza ...$eza_params
alias l = ^eza --git-ignore ...$eza_params
alias ld = ^eza --all --only-dirs ...$eza_params
alias lf = ^eza --all --only-files ...$eza_params
alias ll = ^eza --all --header --long --time-style=relative --sort=modified ...$eza_params
alias la = ^eza --all --header --long ...$eza_params
alias lo = ^eza --oneline ...$eza_params
alias lx = ^eza --all --header --long --extended ...$eza_params
alias lt = ^eza --tree ...$eza_params
alias tree = ^eza --tree ...$eza_params
