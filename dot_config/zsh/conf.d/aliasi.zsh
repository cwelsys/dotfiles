alias z='cd'
alias ..='cd ..'
alias …='cd ../..'
alias ….='cd ../../..'
alias …..='cd ../../../..'

alias c='clear'
alias qq='exit'
alias g='git'
alias zshrc='${=EDITOR} ${ZDOTDIR:-$HOME}/.zshrc'

alias grep='grep --color'
alias sgrep='grep -R -n -H -C 5 --exclude-dir={.git,.svn,CVS} '
alias -g H='| head'
alias -g T='| tail'
alias -g G='| grep'
alias -g L="| less"
alias -g M="| most"
alias -g LL="2>&1 | less"
alias -g CA="2>&1 | cat -A"
alias -g NE="2> /dev/null"
alias -g NUL="> /dev/null 2>&1"
alias -g P="2>&1| pygmentize -l pytb"

alias dud='du -d 1 -h'
alias ff='find . -type f -name'
alias h='history'
alias hgrep="fc -El 0 | grep"
alias help='man'
alias p='ps -f'
alias sortnr='sort -n -r'
alias unexport='unset'
alias path='print -l $path'

alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'
alias mkdir='mkdir -pv'

psgrep() {
  ps aux | grep "${1:-.}" | grep -v grep
}

killit() {
  ps aux | grep -v "grep" | grep "$@" | awk '{print $2}' | xargs sudo kill
}

ip() {
  if [[ -t 1 ]]; then
    command ip -color "$@"
  else
    command ip "$@"
  fi
}

if (( ${+commands[fastfetch]} )); then
  alias cl='clear && fastfetch'
  alias fet='fastfetch'
  alias cpu='fastfetch --logo none --structure cpu'
  alias gpu='fastfetch --logo none --structure gpu'
  alias ram='fastfetch --logo none --structure memory'
  alias osinfo='fastfetch --logo none --structure os'
  alias sysinfo='fastfetch -c all'
  alias mobo='fastfetch --logo none --structure board'
fi

if (( ${+commands[nvim]} )); then
  alias v='nvim'
  alias vi='nvim'
  alias vim='nvim'
fi

(( ${+commands[lazydocker]} )) && alias ld='lazydocker'
(( ${+commands[lazygit]} ))    && alias lg='lazygit'
(( ${+commands[lazyjournal]} )) && alias lj='lazyjournal'

if (( ${+commands[doggo]} )); then
  alias dog='doggo'
  alias dig='doggo'
fi

(( ${+commands[btop]} ))    && alias top='btop'
(( ${+commands[magick]} ))  && alias mg='magick'
(( ${+commands[thefuck]} )) && alias tf='fuck'
(( ${+commands[wiremix]} )) && alias wmx='wiremix'

if (( ${+commands[topgrade]} )); then
  alias tg='topgrade'
  alias tgnr='topgrade --disable remotes'
fi

(( ${+commands[yt-dlp]} )) && alias yt='yt-dlp'

alias wget='wget --hsts-file="$XDG_DATA_HOME/wget-hsts"'

if (( ${+commands[claude]} )); then
  alias cc='claude'
  alias cr='claude --resume'
fi

(( ${+commands[opencode]} )) && alias opc='opencode'
(( ${+commands[ghostty]} ))  && alias boo='ghostty +boo'

if (( ${+commands[kitten]} )); then
  alias icat='kitten icat'
  alias diff='kitten diff'
  alias kcp='kitten transfer'
  alias kclip='kitten clipboard'
fi

if [[ -n $KITTY_INSTALLATION_DIR ]]; then
  alias fonts='kitten choose-fonts'
  alias ssh="kitten ssh"
elif [[ -n $GHOSTTY_RESOURCES_DIR ]] || (( ${+commands[ghostty]} )); then
  alias fonts='ghostty +list-fonts'
fi

y() {
  local tmp cwd
  tmp=$(mktemp -t "yazi-cwd.XXXXXX")
  command yazi "$@" --cwd-file="$tmp"
  read -r cwd <"$tmp"
  [[ $cwd != $PWD && -d $cwd ]] && builtin cd -- "$cwd"
  rm -f -- "$tmp"
}

alias adb='HOME="$XDG_DATA_HOME"/android adb'

if (( ${+commands[svn]} )); then
  alias svn='svn --config-dir "$XDG_CONFIG_HOME/subversion"'
fi

if (( ${+commands[rsync]} )); then
  alias rcp='rsync -avz --progress -h'
  alias rmv='rsync -avz --progress -h --remove-source-files'
fi

alias x='chmod +x'

if (( ${+commands[xdg-open]} )); then
  alias xo='xdg-open'
  e() { nohup xdg-open . >/dev/null 2>&1 & }
elif [[ $OSTYPE == darwin* ]]; then
  alias xo='open'
  e() { open . }
fi

if (( ${+commands[sudo]} )); then
  alias se='sudo -e'
  alias svim='SUDO_EDITOR="nvim" sudo -e'
  alias s='sudo '
  alias su='sudo su'
fi

if (( ${+commands[eza]} )); then
  alias l='ls'
  alias ls="eza $eza_params"
  alias la="eza -a $eza_params"
  alias ll="eza -l $eza_params"
  alias lla="eza -al --header $eza_params"
  alias lo="eza --oneline $eza_params"
  alias l.="eza -a $eza_params | grep -e '^\\.'"
fi

if (( ${+commands[uv]} )); then
  alias uv="noglob uv"
  alias uva='uv add'
  alias uvexp='uv export --format requirements-txt --no-hashes --output-file requirements.txt --quiet'
  alias uvi='uv init'
  alias uvinw='uv init --no-workspace'
  alias uvl='uv lock'
  alias uvlr='uv lock --refresh'
  alias uvlu='uv lock --upgrade'
  alias uvp='uv pip'
  alias uvpi='uv python install'
  alias uvpl='uv python list'
  alias uvpu='uv python uninstall'
  alias uvpy='uv python'
  alias uvpp='uv python pin'
  alias uvr='uv run'
  alias uvrm='uv remove'
  alias uvs='uv sync'
  alias uvsr='uv sync --refresh'
  alias uvsu='uv sync --upgrade'
  alias uvtr='uv tree'
  alias uvup='uv self update'
  alias uvv='uv venv'
fi

(( ${+commands[tree]} )) && alias lt='tree'

if (( ${+commands[bat]} )); then
  alias cat='bat --paging=never'
fi

if (( ${+commands[chezmoi]} )); then
  alias cm='chezmoi'
  alias cma='chezmoi add'
  alias cme='chezmoi edit'
  alias cmu='chezmoi update'
  alias cmapl='chezmoi apply'
fi

cdc() { cd "$HOME/.config" || return 1 }
cds() { cd "$HOME/src" || return 1 }
cdcm() { cd "${DOTFILES:-$HOME/.local/share/chezmoi}" || return 1 }

cmra() {
  if (( $# )); then
    chezmoi re-add "$@"
    return
  fi
  local files
  files=$(chezmoi status 2>/dev/null | awk '$1 ~ /^.M/ {print $2}')
  if [[ -z $files ]]; then
    echo "No locally modified files to re-add"
    return 0
  fi
  local selected
  selected=$(echo "$files" | fzf --multi --ansi \
    --preview="chezmoi diff --reverse --pager cat ~/{} 2>/dev/null | delta --pager=never")
  if [[ -n $selected ]]; then
    echo "$selected" | while IFS= read -r file; do
      chezmoi re-add ~/"$file"
    done
  fi
}

if (( ${+commands[python3]} )); then
  alias py='python3'
  alias venv='python3 -m venv'
fi

alias pip='python -m pip'

(( ${+commands[npm]} ))  && alias npm-ls='npm list -g'
(( ${+commands[pnpm]} )) && alias pnpm-ls='pnpm list -g'
(( ${+commands[bun]} ))  && alias bun-ls='bun pm ls -g'
(( ${+commands[go-global-update]} )) && alias go-ls='go-global-update --dry-runs'

if (( ${+commands[cargo]} )); then
  alias cargols='cargo install --list'
fi

(( ${+commands[cargo-binstall]} )) && alias cargob='cargo-binstall'

if (( ${+commands[docker]} )); then
  alias d='docker'
  alias dr='docker restart'
  alias dc='docker compose'
  alias dcu='docker compose up -d --remove-orphans'
  alias dcd='docker compose down'
  alias dcs='docker compose stop'
  alias dcr='docker compose restart'
  alias dcp='docker compose pull'
  alias dcre='docker compose down && docker compose up -d --remove-orphans'
  alias cscli='docker exec crowdsec cscli'
  alias occ='docker exec --user www-data nextcloud-aio-nextcloud php occ'
  alias nc-clear='docker exec -it nextcloud-aio-database psql -U oc_nextcloud -d nextcloud_database -c "TRUNCATE oc_activity;"'
  alias ollama='docker exec ollama ollama'

  dip() {
    if [[ -z $1 ]]; then
      echo "Usage: dip <container_name_or_id>"
      return 1
    fi
    docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$1"
  }

  dex() {
    if [[ -z $1 ]]; then
      echo "Usage: dex <container_fuzzy_name> [shell:-sh]"
      return 1
    fi
    local names name lines
    names=$(docker ps --filter "name=^/.*$1.*$" --format '{{.Names}}')
    lines=$(printf '%s' "$names" | grep -c '^')
    name=""

    if (( lines == 0 )); then
      echo "No container found"
      return 1
    elif (( lines > 1 )); then
      while IFS= read -r line; do
        echo "Found: $line"
        [[ $line == $1 ]] && name="$1"
      done < <(printf '%s\n' "$names")
      if [[ -z $name ]]; then
        echo "More than one container found, be more specific"
        return 1
      else
        echo "More than one container found but input matched one perfectly."
      fi
    else
      name="$names"
      echo "Found: $name"
    fi

    docker container exec -it "$name" "${2:-sh}"
  }
fi

if (( ${+commands[nvidia-settings]} )); then
  alias nvidia-settings='nvidia-settings --config="$XDG_CONFIG_HOME/nvidia/settings"'
fi

skills() {
  if [[ $1 == add ]]; then
    npx skills add "${@:2}" -a claude-code --copy
  else
    npx skills "$@"
  fi
}

if (( ${+commands[systemctl]} )); then
  alias sy='systemctl'
  alias sys='systemctl status'
  alias sye='sudo systemctl enable'
  alias syd='sudo systemctl disable'
  alias syst='sudo systemctl start'
  alias syz='sudo systemctl stop'
  alias syr='sudo systemctl restart'
  alias syrl='sudo systemctl reload'
  alias sydr='sudo systemctl daemon-reload'
  alias syen='sudo systemctl enable --now'
  alias sydn='sudo systemctl disable --now'
  alias sym='sudo systemctl mask'
  alias syunm='sudo systemctl unmask'
  alias syf='sudo systemctl list-units --failed'

  alias syu='systemctl --user'
  alias syus='systemctl status --user'
  alias syue='systemctl enable --user'
  alias syud='systemctl disable --user'
  alias syust='systemctl start --user'
  alias syuz='systemctl stop --user'
  alias syur='systemctl restart --user'
  alias syurl='systemctl reload --user'
  alias syudr='systemctl daemon-reload --user'
  alias syuen='systemctl enable --now --user'
  alias syudn='systemctl disable --now --user'
  alias syum='systemctl mask --user'
  alias syuunm='systemctl unmask --user'
  alias syuf='systemctl list-units --failed --user'

  alias reboot='sudo systemctl reboot'
  alias poweroff='sudo systemctl poweroff'
  alias suspend='sudo systemctl suspend'
  alias hibernate='sudo systemctl hibernate'
fi

(( ${+commands[journalctl]} )) && { alias jc='journalctl -r'; alias jcu='journalctl -r --user' }
(( ${+commands[ps]} ))         && alias psg='ps aux | grep -i'

if (( ${+commands[iotop]} )) && [[ $OSTYPE == linux* ]]; then
  alias iotop='sudo iotop --delay 2'
fi

if (( ${+commands[jq]} )); then
  alias jq='jq -C'
  alias jl='jq -C | less'
fi

(( ${+commands[fgrep]} )) && alias fgrep='fgrep --color=auto'
(( ${+commands[egrep]} )) && alias egrep='egrep --color=auto'
(( ${+commands[flatpak]} )) && alias fp='flatpak'
(( ${+commands[pacman]} ))  && alias pacman='sudo pacman'

if (( ${+commands[yay]} )); then
  alias ys='yay -Ss'
  yor() {
    if [[ $1 == -a ]]; then
      yay -Qtdq
    else
      yay -Qtdq | grep -v "\-debug$"
    fi
  }
  yi() {
    if (( ! $# )); then
      {
        yay -Slq --repo
        yay -Slq --aur
      } |
        awk 'NR==FNR{inst[$1]=1;next} {if($1 in inst) print $0" \033[1;32m[installed]\033[0m"; else print}' \
          <(yay -Qq) - |
        fzf --multi --ansi -0 --tiebreak=index \
          --preview="yay --color=always -Si {1}" \
          --preview-window "bottom,noinfo" |
        awk '{print $1}' |
        xargs --no-run-if-empty --open-tty yay -S
    else
      yay -S "$@"
    fi
  }

  yu() {
    local use_pattern=0 use_purge=0 pattern=""

    while (( $# )); do
      case $1 in
      -a|-ap|-pa)
        use_pattern=1
        [[ $1 == -ap || $1 == -pa ]] && use_purge=1
        shift
        pattern="$1"
        shift
        ;;
      -p)
        use_purge=1
        shift
        ;;
      *)
        break
        ;;
      esac
    done

    if (( use_pattern )); then
      if [[ -z $pattern ]]; then
        echo "Error: pattern required"
        return 1
      fi
      if (( use_purge )); then
        yay -Rnsc $(yay -Qq | grep "$pattern")
      else
        yay -R $(yay -Qq | grep "$pattern")
      fi
      return
    fi

    if (( use_purge )); then
      yay -Rnsc "$@"
      return
    fi

    if (( $# )); then
      yay -Rn "$@"
      return
    fi

    yay -Qq |
      fzf --multi --ansi \
        --preview="yay --color=always -Qi {1}" \
        --preview-window "bottom,noinfo" |
      xargs --no-run-if-empty --open-tty yay -Rns
  }

  info() {
    if [[ -z $1 ]]; then
      echo "Usage: (pkg)info <package_name>"
      return 1
    fi
    yay -Si "$1" 2>/dev/null || yay -Qi "$1"
  }

  list() {
    if [[ -z $1 ]]; then
      yay -Qq
    else
      yay -Qs "$@"
    fi
  }

  files() {
    if [[ -z $1 ]]; then
      echo "Usage: files <package_name>"
      return 1
    fi
    yay -Ql "$1"
  }
fi

if [[ $OSTYPE == darwin* ]] && (( ${+commands[brew]} )); then
  alias bs='brew search'
  alias bsl='brew services list'
  alias bsr='brew services run'
  alias bsra='bsr --all'
  alias info='brew info'
  alias tap='brew tap'
  alias untap='brew untap'

  list() {
    if [[ -z $1 ]]; then
      brew list
    else
      brew list | grep -i "$@"
    fi
  }

  files() {
    if [[ -z $1 ]]; then
      echo "Usage: files <package_name>"
      return 1
    fi
    brew list "$1"
  }

  brews() {
    local formulae="$(brew leaves | xargs brew deps --installed --for-each)"
    local casks="$(brew list --cask 2>/dev/null)"

    local blue="$(tput setaf 4)"
    local bold="$(tput bold)"
    local off="$(tput sgr0)"

    echo "${blue}==>${off} ${bold}Formulae${off}"
    echo "${formulae}" | sed "s/^\(.*\):\(.*\)$/\1${blue}\2${off}/"
    echo "\n${blue}==>${off} ${bold}Casks${off}\n${casks}"
  }

  (( ${+commands[m]} )) && alias trash-empty='m trash --clean'

  bi() {
    if (( ! $# )); then
      (brew formulae && brew casks) |
        awk 'NR==FNR{inst[$1]=1;next} {if($1 in inst) print $0" \033[1;32m[installed]\033[0m"; else print}' \
          <(brew list) - |
        fzf --multi --ansi -0 --tiebreak=index \
          --preview "brew info {1}" \
          --preview-window "bottom,noinfo" |
        awk '{print $1}' |
        xargs --no-run-if-empty brew install
    else
      brew install "$@"
    fi
  }

  bu() {
    if (( ! $# )); then
      brew list |
        fzf --multi --ansi \
          --preview "brew info {1}" \
          --preview-window "bottom,noinfo" |
        xargs --no-run-if-empty brew uninstall
    else
      brew uninstall "$@"
    fi
  }
fi

rl() { exec "$SHELL" -l }

if [[ -n $WSLENV ]]; then
  cdw() { cd "${WIN_HOME:-/mnt/c/users/$USER}" || return 1 }
fi

iconcp() {
  local char="${1:-$(cat)}"
  python3 -c "print(''.join(f'U+{ord(c):04X} ' for c in '$char').strip())"
}
