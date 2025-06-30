$env.EDITOR = "nvim"
$env.VISUAL = $env.EDITOR

$env.ENV_CONVERSIONS = {
    "PATH": {
        from_string: { |s| $s | split row (char esep) | path expand --no-symlink }
        to_string: { |v| $v | path expand --no-symlink | str join (char esep) }
    }
}

$env.PATH = (
    $env.PATH
    | split row (char esep)
    | prepend ($env.HOME | path join ".local" "bin")
    | prepend ($env.XDG_DATA_HOME | path join "cargo" "bin")
    | uniq
)

load-env {
    XDG_CONFIG_HOME: (if ('XDG_CONFIG_HOME' not-in $env) { ($env.HOME | path join ".config") } else { $env.XDG_CONFIG_HOME })
    XDG_CACHE_HOME: (if ('XDG_CACHE_HOME' not-in $env) { ($env.HOME | path join ".cache") } else { $env.XDG_CACHE_HOME })
    XDG_BIN_HOME: (if ('XDG_BIN_HOME' not-in $env) { ($env.HOME | path join ".local" "bin") } else { $env.XDG_BIN_HOME })
    XDG_DATA_HOME: (if ('XDG_DATA_HOME' not-in $env) { ($env.HOME | path join ".local" "share") } else { $env.XDG_DATA_HOME })
    XDG_STATE_HOME: (if ('XDG_STATE_HOME' not-in $env) { ($env.HOME | path join ".local" "state") } else { $env.XDG_STATE_HOME })
    XDG_DATA_DIRS: (if ('XDG_DATA_DIRS' not-in $env) { ([ /usr/local/share /usr/share ] | str join :) } else { $env.XDG_DATA_DIRS })
    XDG_CONFIG_DIRS: (if ('XDG_CONFIG_DIRS' not-in $env) { ([ /usr/local/share /usr/share ] | str join :) } else { $env.XDG_CONFIG_DIRS })
    XDG_RUNTIME_DIR: (if ('XDG_RUNTIME_DIR' not-in $env) { ($env.HOME | path join ".local" "run" "user" (id -u)) } else { $env.XDG_RUNTIME_DIR })
    NUPM_HOME: ($env.XDG_DATA_HOME | path join "nupm")
    CARAPACE_BRIDGES: 'zsh,fish,bash,inshellisense'
    ATUIN_NOBIND: "true"
    BAT_THEME: "Catppuccin Mocha"
    TZ: "America/New_York"
    DOMAIN: "cwel.sh"
    CASA: "cwel.casa"
    FZF_DEFAULT_OPTS: "--color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc --color=hl:#f38ba8,fg:#cdd6f4,header:#f38ba8 --color=info:#94e2d5,pointer:#f5e0dc,marker:#f5e0dc --color=fg+:#cdd6f4,prompt:#94e2d5,hl+:#f38ba8 --color=border:#585b70 --layout=reverse --cycle --height=~80% --border=rounded --info=right --bind=alt-w:toggle-preview-wrap --bind=ctrl-e:toggle-preview"
        XDG_PROJECTS_DIR: ($env.HOME | path join "Projects")
    MANPAGER: "nvim +Man!"
    WORDCHARS: "~!#$%^&*(){}[]<>?.+;"
    PROMPT_EOL_MARK: ""
    LANG: "en_US.UTF-8"
    LC_ALL: "en_US.UTF-8"
    LC_CTYPE: "en_US.UTF-8"
    DOCKER_HOST: "tcp://psock:2375"
    PASSWORD_STORE_DIR: ($env.XDG_DATA_HOME | path join "pass")
    GNUPGHOME: ($env.XDG_DATA_HOME | path join "gnupg")
    DOCKER_CONFIG: ($env.XDG_CONFIG_HOME | path join "docker")
    CARGO_HOME: ($env.XDG_DATA_HOME | path join "cargo")
    RUSTUP_HOME: ($env.XDG_DATA_HOME | path join "rustup")
    DOTNET_CLI_HOME: ($env.XDG_DATA_HOME | path join "dotnet")
    XAUTHORITY: ($env.XDG_STATE_HOME | path join ".Xauthority")
    PYTHONSTARTUP: ($env.XDG_CONFIG_HOME | path join "python" "pythonrc")
    vivid_theme: "catppuccin-mocha"
    PIPX_HOME: ($env.XDG_DATA_HOME | path join "pipx")
    BAT_CONFIG_DIR: ($env.XDG_CONFIG_HOME | path join "bat")
    GLOW_STYLE: ($env.HOME | path join ".config" "glow" "catppuccin-mocha.json")
    GRADLE_USER_HOME: ($env.XDG_DATA_HOME | path join "gradle")
    NPM_CONFIG_INIT_MODULE: ($env.XDG_CONFIG_HOME | path join "npm" "config" "npm-init.js")
    NPM_CONFIG_CACHE: ($env.XDG_CACHE_HOME | path join "npm")
    NODE_REPL_HISTORY: ($env.XDG_STATE_HOME | path join "node_repl_history")
    GOPATH: ($env.XDG_DATA_HOME | path join "go")
    GOBIN: ($env.XDG_DATA_HOME | path join "go" "bin")
    RIPGREP_CONFIG_PATH: ($env.XDG_CONFIG_HOME | path join "ripgrep" "config")
    LESSHISTFILE: ($env.XDG_CACHE_HOME | path join ".lesshsts")
    WGETRC: ($env.XDG_CONFIG_HOME | path join "wget" "wgetrc")
    PAGER: "bat"
    GIT_PAGER: "delta"
    VAGRANT_HOME: ($env.XDG_DATA_HOME | path join "vagrant")
}

# let cargo_bin_dir = ($env.XDG_DATA_HOME | path join "cargo" "bin")
# if ($cargo_bin_dir | path exists) {
#     try {
#         ls $cargo_bin_dir
#         | where name =~ "nu_plugin_.*"
#         | get name
#         | each { |plugin|
#             try {
#                 plugin add $plugin
#             } catch {
#                 print $"Failed to add plugin: ($plugin)"
#             }
#         }
#     } catch {
#     }
# }

mkdir ($nu.data-dir | path join "vendor/autoload")
starship init nu | save -f ($nu.data-dir | path join "vendor/autoload/starship.nu")

aliae init nu --print | save ~/.cache/.aliae.nu --force

carapace _carapace nushell | save -f ~/.cache/carapace/init.nu

mkdir ~/.local/share/atuin/
atuin init nu | save -f  ~/.local/share/atuin/init.nu

zoxide init nushell --cmd cd | save -f ~/.cache/.zoxide.nu

let mise_path = $nu.default-config-dir | path join mise.nu
^mise activate nu | save $mise_path --force
