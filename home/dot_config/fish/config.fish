# 🐶 FastFetch
if type -q fastfetch
    fastfetch
end

set fish_greeting

# 🍺 Brew
if test -f /home/linuxbrew/.linuxbrew/bin/brew
    eval (/home/linuxbrew/.linuxbrew/bin/brew shellenv)
end

if type -q brew
    if test -d (brew --prefix)"/share/fish/completions"
        set -p fish_complete_path (brew --prefix)/share/fish/completions
    end

    if test -d (brew --prefix)"/share/fish/vendor_completions.d"
        set -p fish_complete_path (brew --prefix)/share/fish/vendor_completions.d
    end
end

# 🌐 Env
if type -q bass
    and test -f $HOME/.config/shared/init.sh
    bass ". $HOME/.config/shared/init.sh"
end

# 🐚 Prompt
if type -q oh-my-posh
    oh-my-posh init fish --config ~/.config/zen.toml | source
elif type -q starship
    starship init fish | source
end

if type -q mise
    mise activate fish | source
end

if type -q navi
    navi widget fish | source
end

if type -q zoxide
    zoxide init fish --cmd cd | source
end
