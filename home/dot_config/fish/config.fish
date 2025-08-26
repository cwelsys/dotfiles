set fish_greeting

if test -n "$GHOSTTY_RESOURCES_DIR"
    builtin source "$GHOSTTY_RESOURCES_DIR"/shell-integration/fish/vendor_conf.d/ghostty-shell-integration.fish
end

if test -f "$HOMEBREW_PREFIX/bin/brew"
    eval ($HOMEBREW_PREFIX/bin/brew shellenv)
end

if type -q aliae
    aliae init fish --config "$HOME/.config/aliae.yaml" | source
end

function mark_prompt_start --on-event fish_prompt
    echo -en "\e]133;A\e\\"
end

if type -q brew
    if test -d (brew --prefix)"/share/fish/completions"
        set -p fish_complete_path (brew --prefix)/share/fish/completions
    end

    if test -d (brew --prefix)"/share/fish/vendor_completions.d"
        set -p fish_complete_path (brew --prefix)/share/fish/vendor_completions.d
    end
end

if type -q starship
    function starship_transient_prompt_func
    starship module character
    end
    starship init fish | source
    enable_transience
end

if type -q atuin
    atuin init fish | source
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
