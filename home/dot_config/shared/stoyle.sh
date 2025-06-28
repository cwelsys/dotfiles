export FZF_DEFAULT_OPTS="--color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc
--color=hl:#f38ba8,fg:#cdd6f4,header:#f38ba8
--color=info:#94e2d5,pointer:#f5e0dc,marker:#f5e0dc
--color=fg+:#cdd6f4,prompt:#94e2d5,hl+:#f38ba8
--color=border:#585b70
--layout=reverse --cycle --height=~80% --border=rounded --info=right
--bind=alt-w:toggle-preview-wrap
--bind=ctrl-e:toggle-preview"

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
