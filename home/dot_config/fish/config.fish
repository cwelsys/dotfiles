set fish_greeting

if test -f /home/linuxbrew/.linuxbrew/bin/brew
    eval (/home/linuxbrew/.linuxbrew/bin/brew shellenv)
end

if test -f /opt/homebrew/bin
    eval (/opt/homebrew/bin/brew shellenv)
end

if type -q brew
    if test -d (brew --prefix)"/share/fish/completions"
        set -p fish_complete_path (brew --prefix)/share/fish/completions
    end

    if test -d (brew --prefix)"/share/fish/vendor_completions.d"
        set -p fish_complete_path (brew --prefix)/share/fish/vendor_completions.d
    end
end

aliae init fish --config "$HOME/.config/aliae.yaml" | source

if type -q starship
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
