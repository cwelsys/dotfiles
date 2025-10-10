export ZSH_PLUGINS_ALIAS_TIPS_TEXT="tip: "
export ZSH_PLUGINS_ALIAS_TIPS_EXCLUDES="_ ll vi s l la g d"

fdz-widget() {
	fdz
	zle reset-prompt
}
zle -N fdz-widget
bindkey '^F' fdz-widget

rgz-widget() {
	rgz
	zle reset-prompt
}
zle -N rgz-widget
bindkey '^G' rgz-widget

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

function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	yazi "$@" --cwd-file="$tmp"
	if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
		builtin cd -- "$cwd"
	fi
	rm -f -- "$tmp"
}

function sy() {
    local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
    sudo yazi "$@" --cwd-file="$tmp"
    if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
        builtin cd -- "$cwd"
    fi
    rm -f -- "$tmp"
}

fdz() {
  local file
  file=$(fd --type file --follow --hidden --exclude .git | fzf \
    --prompt="Files> " \
    --header="CTRL-T: Switch between Files/Directories" \
    --bind="ctrl-t:transform:[[ \$FZF_PROMPT == *Directory* ]] && \
  echo change-prompt\\(Files\\> \\)+reload\\(fd --type file\\) || \
  echo change-prompt\\(Directory\\> \\)+reload\\(fd --type directory\\)" \
    --preview="if echo \$FZF_PROMPT | grep -q 'Files> '; then \
      bat --color=always {} --style=plain; \
      else eza -T --colour=always --icons=always {}; fi")
  [ -n "$file" ] && _fzf_open_path "$file"
}

rgz() {
  local file
  RG_PREFIX="rg --column --line-number --no-heading --color=always --smart-case"
  file=$(FZF_DEFAULT_COMMAND="$RG_PREFIX ''" fzf --ansi --disabled \
    --bind="start:reload:$RG_PREFIX {q}" \
    --bind="change:reload:sleep 0.1; $RG_PREFIX {q} || true" \
    --color="hl:-1:underline,hl+:-1:underline:reverse" \
    --delimiter=":" \
    --prompt="1. ripgrep> " \
    --header="CTRL-T: Switch between ripgrep/fzf" \
    --header-first \
    --preview="bat --color=always {1} --highlight-line {2} --style=plain" \
    --preview-window="up,60%,border-bottom,+{2}+3/3")
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

clone() {
  if [[ -z "$1" ]]; then
    echo "What git repo do you want?" >&2
    return 1
  fi
  local user repo
  if [[ "$1" = */* ]]; then
    user=${1%/*}
    repo=${1##*/}
  else
    user=$GITHUB_USERNAME
    repo=$1
  fi

  local giturl="github.com"
  local dest=${XDG_PROJECTS_HOME:-~/Projects}/$user/$repo

  if [[ ! -d $dest ]]; then
    git clone --recurse-submodules "git@${giturl}:${user}/${repo}.git" "$dest"
  else
    echo "No need to clone, that directory already exists."
    echo "Taking you there."
  fi
  cd $dest
}

extract() {
  setopt localoptions noautopushd

  if (( $# == 0 )); then
    cat >&2 <<'EOF'
Usage: extract [-option] [file ...]
Options:
  -r, --remove    Remove archive after unpacking.
EOF
  fi

  local remove_archive=1
  if [[ "$1" == "-r" ]] || [[ "$1" == "--remove" ]]; then
    remove_archive=0
    shift
  fi

  local pwd="$PWD"
  while (( $# > 0 )); do
    if [[ ! -f "$1" ]]; then
      echo "extract: '$1' is not a valid file" >&2
      shift
      continue
    fi

    local success=0
    local extract_dir="${1:t:r}"
    local file="$1" full_path="${1:A}"
    case "${file:l}" in
      (*.tar.gz|*.tgz) (( $+commands[pigz] )) && { pigz -dc "$file" | tar xv } || tar zxvf "$file" ;;
      (*.tar.bz2|*.tbz|*.tbz2) tar xvjf "$file" ;;
      (*.tar.xz|*.txz)
        tar --xz --help &> /dev/null \
        && tar --xz -xvf "$file" \
        || xzcat "$file" | tar xvf - ;;
      (*.tar.zma|*.tlz)
        tar --lzma --help &> /dev/null \
        && tar --lzma -xvf "$file" \
        || lzcat "$file" | tar xvf - ;;
      (*.tar.zst|*.tzst)
        tar --zstd --help &> /dev/null \
        && tar --zstd -xvf "$file" \
        || zstdcat "$file" | tar xvf - ;;
      (*.tar) tar xvf "$file" ;;
      (*.tar.lz) (( $+commands[lzip] )) && tar xvf "$file" ;;
      (*.tar.lz4) lz4 -c -d "$file" | tar xvf - ;;
      (*.tar.lrz) (( $+commands[lrzuntar] )) && lrzuntar "$file" ;;
      (*.gz) (( $+commands[pigz] )) && pigz -dk "$file" || gunzip -k "$file" ;;
      (*.bz2) bunzip2 "$file" ;;
      (*.xz) unxz "$file" ;;
      (*.lrz) (( $+commands[lrunzip] )) && lrunzip "$file" ;;
      (*.lz4) lz4 -d "$file" ;;
      (*.lzma) unlzma "$file" ;;
      (*.z) uncompress "$file" ;;
      (*.zip|*.war|*.jar|*.ear|*.sublime-package|*.ipa|*.ipsw|*.xpi|*.apk|*.aar|*.whl) unzip "$file" -d "$extract_dir" ;;
      (*.rar) unrar x -ad "$file" ;;
      (*.rpm)
        command mkdir -p "$extract_dir" && builtin cd -q "$extract_dir" \
        && rpm2cpio "$full_path" | cpio --quiet -id ;;
      (*.7z) 7za x "$file" ;;
      (*.deb)
        command mkdir -p "$extract_dir/control" "$extract_dir/data"
        builtin cd -q "$extract_dir"; ar vx "$full_path" > /dev/null
        builtin cd -q control; extract ../control.tar.*
        builtin cd -q ../data; extract ../data.tar.*
        builtin cd -q ..; command rm *.tar.* debian-binary ;;
      (*.zst) unzstd "$file" ;;
      (*.cab) cabextract -d "$extract_dir" "$file" ;;
      (*.cpio) cpio -idmvF "$file" ;;
      (*)
        echo "extract: '$file' cannot be extracted" >&2
        success=1 ;;
    esac

    (( success = success > 0 ? success : $? ))
    (( success == 0 && remove_archive == 0 )) && rm "$full_path"
    shift

    # Go back to original working directory in case we ran cd previously
    builtin cd -q "$pwd"
  done
}
