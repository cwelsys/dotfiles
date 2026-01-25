#!/bin/sh

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

if command -v lazydocker >/dev/null 2>&1; then
    alias ld='lazydocker'
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
fi

if command -v yt-dlp >/dev/null 2>&1; then
    alias yt='yt-dlp'
fi

if command -v claude >/dev/null 2>&1; then
    cc() {
        if [[ -n "$KITTY_WINDOW_ID" ]]; then
            kitty @ set-colors "color8=#1e1e2e"
            command claude "$@"
            kitty @ set-colors --reset 2>/dev/null
        else
            command claude "$@"
        fi
    }
    cr() {
        if [[ -n "$KITTY_WINDOW_ID" ]]; then
            kitty @ set-colors "color8=#1e1e2e"
            command claude --resume "$@"
            kitty @ set-colors --reset 2>/dev/null
        else
            command claude --resume "$@"
        fi
    }
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
elif [ -n "$GHOSTTY_RESOURCES_DIR" ] || command -v ghostty >/dev/null 2>&1; then
    alias fonts='ghostty +list-fonts'
fi

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
    e() { open . ; }
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
        --preview="chezmoi diff --pager cat ~/{} 2>/dev/null | delta -s ansi 2>/dev/null" \
        --preview-window="right,60%,wrap,<80(down,60%,wrap)")
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

if command -v pip3 >/dev/null 2>&1 && ! command -v pip >/dev/null 2>&1; then
    alias pip='pip3'
fi

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
fi

if command -v nerdctl >/dev/null 2>&1; then
    alias n='nerdctl'
fi

if command -v nvidia-settings >/dev/null 2>&1; then
    alias nvidia-settings='nvidia-settings --config="$XDG_CONFIG_HOME/nvidia/settings"'
fi

if command -v systemctl >/dev/null 2>&1; then
    alias sy='systemctl'
    alias sydr='systemctl daemon-reload'
    alias syd='systemctl disable'
    alias sye='systemctl enable'
    alias syr='systemctl restart'
    alias syst='systemctl start'
    alias sys='systemctl status'
    alias syz='systemctl stop'
    alias failed='sudo systemctl list-units --failed'
    alias syu='systemctl --user'
    alias sydru='systemctl daemon-reload --user'
    alias sydu='systemctl disable --user'
    alias syeu='systemctl enable --user'
    alias syru='systemctl restart --user'
    alias systu='systemctl start --user'
    alias syus='systemctl status --user'
    alias syuz='systemctl stop --user'
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
    alias clean='yay --clean'
    alias update='yay -Syyu --noconfirm'
    alias search='yay -Ss'
    alias orphans='yay -Qtdq | grep -v "\-debug$"'
    alias orphans-all='yay -Qtdq'
    alias in='yay -Slq | awk "NR==FNR{inst[\$1]=1;next} {if(\$1 in inst) print \$0\" \033[1;32m[installed]\033[0m\"; else print}" <(yay -Qq) - | fzf --multi --ansi -0 --tiebreak=index --preview="yay --color=always -Si {1}" --preview-window "bottom,noinfo" | awk "{print \$1}" | xargs --no-run-if-empty --open-tty yay -S --cleanafter'
    alias re='yay -Qq | fzf --multi --ansi --preview="yay --color=always -Qi {1}" --preview-window "bottom,noinfo" | xargs --no-run-if-empty --open-tty yay -Rns'

    function remove {
        if [ -z "$1" ]; then
            echo "Usage: remove <package>        - Remove package"
            echo "       remove -a <pattern>     - Remove all packages matching pattern"
            echo "       remove -p <package>     - Purge package (with dependencies & configs)"
            echo "       remove -ap <pattern>    - Purge all packages matching pattern"
            return 1
        fi

        local use_pattern=0
        local use_purge=0
        local pattern=""

        while [ $# -gt 0 ]; do
            case "$1" in
                -a|-ap|-pa)
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
        elif [ $use_purge -eq 1 ]; then
            yay -Rnsc "$@"
        else
            yay -Rn "$@"
        fi
    }

    function info {
        if [ -z "$1" ]; then
            echo "Usage: (pkg)info <package_name>"
            return 1
        fi
        yay -Si "$1" 2>/dev/null || yay -Qi "$1"
    }

    function list {
        if [ -z "$1" ]; then
            yay -Qq
        else
            yay -Qs "$@"
        fi
    }

    function files {
        if [ -z "$1" ]; then
            echo "Usage: files <package_name>"
            return 1
        fi
        yay -Ql "$1"
    }

fi

if [ "$(uname)" = "Darwin" ] && command -v brew >/dev/null 2>&1; then
    alias update='brew update && brew upgrade'
    alias clean='brew cleanup'
    alias remove='brew uninstall'
    alias search='brew search'
    alias info='brew info'
    alias pkginfo='brew info'
    alias tap='brew tap'
    alias untap='brew untap'

    function list {
        if [ -z "$1" ]; then
            brew list
        else
            brew list | grep -i "$@"
        fi
    }

    function files {
        if [ -z "$1" ]; then
            echo "Usage: files <package_name>"
            return 1
        fi
        brew list "$1"
    }

    if command -v m >/dev/null 2>&1; then
        alias trash-empty='m trash --clean'
    fi

    if command -v fzf >/dev/null 2>&1; then
        alias in='(brew formulae && brew casks) | awk "NR==FNR{inst[\$1]=1;next} {if(\$1 in inst) print \$0\" \033[1;32m[installed]\033[0m\"; else print}" <(brew list) - | fzf --multi --ansi -0 --tiebreak=index --preview "brew info {1}" --preview-window "bottom,noinfo" | awk "{print \$1}" | xargs --no-run-if-empty brew install'
        alias re='brew list | fzf --multi --ansi --preview "brew info {1}" --preview-window "bottom,noinfo" | xargs --no-run-if-empty brew uninstall'
    fi
fi

rl() {
    exec "$SHELL" -l
}

if [ -n "$WSLENV" ]; then
    cdw() { cd "${WIN_HOME:-/mnt/c/users/$USER}" || return 1; }
fi
