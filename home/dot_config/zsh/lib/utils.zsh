function cdl() {
	cd "$@" && ls -la
}

fdz-widget() {
	BUFFER="fdz"
	zle accept-line
}
zle -N fdz-widget
bindkey '^F' fdz-widget

rgz-widget() {
	BUFFER="rgz"
	zle accept-line
}
zle -N rgz-widget
bindkey '^G' rgz-widget

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

function do-nothing() {
}
zle -N do-nothing

# Bind F13 to the no-op function
#bindkey '^[[25~' do-nothing
#bindkey '^[[1;2P' do-nothing
#bindkey '^[[[E' do-nothing

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

function omzPlugin() {
  zinit ice atpull"%atclone" atclone"_fix-omz-plugin" lucid $2
  zinit snippet OMZP::$1
}

function omzLib() {
  zinit wait'!' lucid for OMZL::$1
}


function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	yazi "$@" --cwd-file="$tmp"
	if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
		builtin cd -- "$cwd"
	fi
	rm -f -- "$tmp"
}

function colors(){
  for i in {0..255}; do print -Pn "%K{$i}  %k%F{$i}${(l:3::0:)i}%f " ${${(M)$((i%6)):#3}:+$'\n'}; done
}
