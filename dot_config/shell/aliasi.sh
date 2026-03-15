#!/bin/bash

alias z='cd'
alias ..='cd ..'
alias …='cd ../..'
alias ….='cd ../../..'
alias …..='cd ../../../..'

alias c='clear'
alias qq='exit'

if command -v fastfetch >/dev/null 2>&1; then
  alias cl='clear && fastfetch'
  alias fet='fastfetch'
  alias cpu='fastfetch --logo none --structure cpu'
  alias gpu='fastfetch --logo none --structure gpu'
  alias ram='fastfetch --logo none --structure memory'
  alias osinfo='fastfetch --logo none --structure os'
  alias sysinfo='fastfetch -c all'
  alias mobo='fastfetch --logo none --structure board'
fi

if command -v nvim >/dev/null 2>&1; then
  alias v='nvim'
  alias vi='nvim'
  alias vim='nvim'
fi

# if command -v lazydocker >/dev/null 2>&1; then
#     alias ld='lazydocker'
# fi

if command -v ducker >/dev/null 2>&1; then
  alias ld='ducker'
fi

if command -v lazygit >/dev/null 2>&1; then
  alias lg='lazygit'
fi

if command -v lazyjournal >/dev/null 2>&1; then
  alias lj='lazyjournal'
fi

if command -v doggo >/dev/null 2>&1; then
  alias dog='doggo'
  alias dig='doggo'
fi

if command -v btop >/dev/null 2>&1; then
  alias top='btop'
fi

if command -v magick >/dev/null 2>&1; then
  alias mg='magick'
fi

if command -v thefuck >/dev/null 2>&1; then
  alias tf='fuck'
fi

if command -v wiremix >/dev/null 2>&1; then
  alias wmx='wiremix'
fi

if command -v topgrade >/dev/null 2>&1; then
  alias tg='topgrade'
  alias tgnr='topgrade --disable remotes'
fi

if command -v yt-dlp >/dev/null 2>&1; then
  alias yt='yt-dlp'
fi

if command -v claude >/dev/null 2>&1; then
  alias cc='claude'
  alias cr='claude --resume'
fi

if command -v opencode >/dev/null 2>&1; then
  alias opc='opencode'
fi

if command -v ghostty >/dev/null 2>&1; then
  alias boo='ghostty +boo'
fi

if command -v kitten >/dev/null 2>&1; then
  alias icat='kitten icat'
  alias diff='kitten diff'
  alias kcp='kitten transfer'
  alias kclip='kitten clipboard'
fi

if [ -n "$KITTY_INSTALLATION_DIR" ]; then
  alias fonts='kitten choose-fonts'
  alias ssh="kitten ssh"
elif [ -n "$GHOSTTY_RESOURCES_DIR" ] || command -v ghostty >/dev/null 2>&1; then
  alias fonts='ghostty +list-fonts'
fi

y() {
  local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
  command yazi "$@" --cwd-file="$tmp"
  IFS= read -r -d '' cwd <"$tmp"
  [ "$cwd" != "$PWD" ] && [ -d "$cwd" ] && builtin cd -- "$cwd"
  rm -f -- "$tmp"
}

alias adb='HOME="$XDG_DATA_HOME"/android adb'

# if command -v wget >/dev/null 2>&1; then
#     alias wget='wget --hsts-file="$XDG_CACHE_HOME/wget-hsts"'
# fi

if command -v svn >/dev/null 2>&1; then
  alias svn='svn --config-dir "$XDG_CONFIG_HOME/subversion"'
fi

if command -v cp >/dev/null 2>&1; then
  alias cp='cp -i'
fi

if command -v mv >/dev/null 2>&1; then
  alias mv='mv -i'
fi

if command -v rsync >/dev/null 2>&1; then
  alias rcp='rsync --recursive --times --progress --stats --human-readable'
  alias rmv='rsync --recursive --times --progress --stats --human-readable --remove-source-files'
fi

if command -v chmod >/dev/null 2>&1; then
  alias x='chmod +x'
fi

if command -v xdg-open >/dev/null 2>&1; then
  alias xo='xdg-open'
  e() { nohup xdg-open . >/dev/null 2>&1 & }
elif [ "$(uname)" = "Darwin" ]; then
  alias xo='open'
  e() { open .; }
fi

if command -v sudo >/dev/null 2>&1; then
  # alias s='sudo'
  alias se='sudo -e'
  alias svim='SUDO_EDITOR="nvim" sudo -e'
  alias s='sudo ' # alias expansion
  alias su='sudo su'
fi

if command -v eza >/dev/null 2>&1; then
  # shellcheck disable=SC2139
  alias l='ls'
  alias ls="eza $eza_params"
  alias la="eza -a $eza_params"
  alias ll="eza -l $eza_params"
  alias lla="eza -al --header $eza_params"
  alias lo="eza --oneline $eza_params"
  alias l.="eza -a $eza_params | grep -e '^\\.'"
fi

if command -v tree >/dev/null 2>&1; then
  alias lt='tree'
fi

if command -v bat >/dev/null 2>&1; then
  alias cat='bat --paging=never'
fi

if command -v chezmoi >/dev/null 2>&1; then
  alias cm='chezmoi'
  alias cma='chezmoi add'
  alias cme='chezmoi edit'
  alias cmu='chezmoi update'
  alias cmapl='chezmoi apply'
fi

cdc() { cd "$HOME/.config" || return 1; }
cds() { cd "$HOME/src" || return 1; }
cdcm() { cd "${DOTFILES:-$HOME/.local/share/chezmoi}" || return 1; }

cmra() {
  if [ $# -gt 0 ]; then
    chezmoi re-add "$@"
    return
  fi
  local files
  files=$(chezmoi status 2>/dev/null | awk '$1 ~ /^.M/ {print $2}')
  if [ -z "$files" ]; then
    echo "No locally modified files to re-add"
    return 0
  fi
  local selected
  selected=$(echo "$files" | fzf --multi --ansi \
    --preview="chezmoi diff --reverse --pager cat ~/{} 2>/dev/null | delta --pager=never --width=\${FZF_PREVIEW_COLUMNS:-80}")
  if [ -n "$selected" ]; then
    echo "$selected" | while IFS= read -r file; do
      chezmoi re-add ~/"$file"
    done
  fi
}

if command -v python3 >/dev/null 2>&1; then
  alias py='python3'
  alias venv='python3 -m venv'
fi

alias pip='python -m pip'

if command -v npm >/dev/null 2>&1; then
  alias npm-ls='npm list -g'
fi

if command -v pnpm >/dev/null 2>&1; then
  alias pnpm-ls='pnpm list -g'
fi

if command -v bun >/dev/null 2>&1; then
  alias bun-ls='bun pm ls -g'
fi

if command -v go-global-update >/dev/null 2>&1; then
  alias go-ls='go-global-update --dry-runs'
fi

if command -v cargo >/dev/null 2>&1; then
  alias cargols='cargo install --list'
fi

if command -v cargo-binstall >/dev/null 2>&1; then
  alias cargob='cargo-binstall'
fi

if command -v docker >/dev/null 2>&1; then
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
    if [ -z "$1" ]; then
      echo "Usage: dip <container_name_or_id>"
      return 1
    fi
    docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$1"
  }

  dex() {
    if [ -z "$1" ]; then
      echo "Usage: dex <container_fuzzy_name> [shell:-sh]"
      return 1
    fi
    local names name lines
    names=$(docker ps --filter "name=^/.*$1.*$" --format '{{.Names}}')
    lines=$(printf '%s' "$names" | grep -c '^')
    name=""

    if [ "$lines" -eq 0 ]; then
      echo "No container found"
      return 1
    elif [ "$lines" -gt 1 ]; then
      while IFS= read -r line; do
        echo "Found: $line"
        [ "$line" = "$1" ] && name="$1"
      done < <(printf '%s\n' "$names")
      if [ -z "$name" ]; then
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

if command -v nvidia-settings >/dev/null 2>&1; then
  alias nvidia-settings='nvidia-settings --config="$XDG_CONFIG_HOME/nvidia/settings"'
fi

skills() {
  if [[ "$1" == "add" ]]; then
    npx skills add "${@:2}" -a claude-code --copy
  else
    npx skills "$@"
  fi
}

if command -v systemctl >/dev/null 2>&1; then
  # system
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

  # user
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

  # power
  alias reboot='sudo systemctl reboot'
  alias poweroff='sudo systemctl poweroff'
  alias suspend='sudo systemctl suspend'
  alias hibernate='sudo systemctl hibernate'
fi

if command -v journalctl >/dev/null 2>&1; then
  alias jc='journalctl -r'
  alias jcu='journalctl -r --user'
fi

if command -v ps >/dev/null 2>&1; then
  alias psg='ps aux | grep -i'
fi

if command -v iotop >/dev/null 2>&1 && [ "$(uname)" = "Linux" ]; then
  alias iotop='sudo iotop --delay 2'
fi

if command -v jq >/dev/null 2>&1; then
  alias jq='jq -C'
  alias jl='jq -C | less'
fi

if command -v fgrep >/dev/null 2>&1; then
  alias fgrep='fgrep --color=auto'
fi

if command -v egrep >/dev/null 2>&1; then
  alias egrep='egrep --color=auto'
fi

if command -v flatpak >/dev/null 2>&1; then
  alias fp='flatpak'
fi

if command -v pacman >/dev/null 2>&1; then
  alias pacman='sudo pacman'
fi

if command -v yay >/dev/null 2>&1; then
  alias ys='yay -Ss'
  yor() {
    if [ "$1" = "-a" ]; then
      yay -Qtdq
    else
      yay -Qtdq | grep -v "\-debug$"
    fi
  }
  yi() {
    if [ $# -eq 0 ]; then
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
    local use_pattern=0
    local use_purge=0
    local pattern=""

    while [ $# -gt 0 ]; do
      case "$1" in
      -a | -ap | -pa)
        use_pattern=1
        [ "$1" = "-ap" ] || [ "$1" = "-pa" ] && use_purge=1
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

    # Pattern mode (-a or -ap)
    if [ $use_pattern -eq 1 ]; then
      if [ -z "$pattern" ]; then
        echo "Error: pattern required"
        return 1
      fi
      # shellcheck disable=SC2046
      if [ $use_purge -eq 1 ]; then
        yay -Rnsc $(yay -Qq | grep "$pattern")
      else
        yay -R $(yay -Qq | grep "$pattern")
      fi
      return
    fi

    # Purge mode (-p <package>)
    if [ $use_purge -eq 1 ]; then
      yay -Rnsc "$@"
      return
    fi

    # Direct removal (args given)
    if [ $# -gt 0 ]; then
      yay -Rn "$@"
      return
    fi

    # No args: fzf interactive picker
    yay -Qq |
      fzf --multi --ansi \
        --preview="yay --color=always -Qi {1}" \
        --preview-window "bottom,noinfo" |
      xargs --no-run-if-empty --open-tty yay -Rns
  }

  info() {
    if [ -z "$1" ]; then
      echo "Usage: (pkg)info <package_name>"
      return 1
    fi
    yay -Si "$1" 2>/dev/null || yay -Qi "$1"
  }

  list() {
    if [ -z "$1" ]; then
      yay -Qq
    else
      yay -Qs "$@"
    fi
  }

  files() {
    if [ -z "$1" ]; then
      echo "Usage: files <package_name>"
      return 1
    fi
    yay -Ql "$1"
  }

fi

if [ "$(uname)" = "Darwin" ] && command -v brew >/dev/null 2>&1; then
  alias bs='brew search'
  alias bsl='brew services list'
  alias bsr='brew services run'
  alias bsra='bsr --all'
  alias info='brew info'
  alias tap='brew tap'
  alias untap='brew untap'

  list() {
    if [ -z "$1" ]; then
      brew list
    else
      brew list | grep -i "$@"
    fi
  }

  files() {
    if [ -z "$1" ]; then
      echo "Usage: files <package_name>"
      return 1
    fi
    brew list "$1"
  }

  function brews() {
    local formulae="$(brew leaves | xargs brew deps --installed --for-each)"
    local casks="$(brew list --cask 2>/dev/null)"

    local blue="$(tput setaf 4)"
    local bold="$(tput bold)"
    local off="$(tput sgr0)"

    echo "${blue}==>${off} ${bold}Formulae${off}"
    echo "${formulae}" | sed "s/^\(.*\):\(.*\)$/\1${blue}\2${off}/"
    echo "\n${blue}==>${off} ${bold}Casks${off}\n${casks}"
  }

  if command -v m >/dev/null 2>&1; then
    alias trash-empty='m trash --clean'
  fi

  bi() {
    if [ $# -eq 0 ]; then
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
    if [ $# -eq 0 ]; then
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

rl() {
  exec "$SHELL" -l
}

if [ -n "$WSLENV" ]; then
  cdw() { cd "${WIN_HOME:-/mnt/c/users/$USER}" || return 1; }
fi
