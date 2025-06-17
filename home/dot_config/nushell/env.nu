$env.CARAPACE_BRIDGES = 'zsh,fish,bash,inshellisense'
$env.ATUIN_NOBIND = 'true'
$env.BAT_THEME = "Catppuccin Mocha"
$env.LS_COLORS = "Gxfxcxdxbxegedabagacad"
$env.ENV_CONVERSIONS = {
    "PATH": {
        from_string: { |s| $s | split row (char esep) | path expand --no-symlink }
        to_string: { |v| $v | path expand --no-symlink | str join (char esep) }
    }
    "Path": {
        from_string: { |s| $s | split row (char esep) | path expand --no-symlink }
        to_string: { |v| $v | path expand --no-symlink | str join (char esep) }
    }
}

load-env {
  XDG_DATA_HOME: ($env.HOME | path join ".local" "share")
}

load-env {
  NUPM_HOME: ($env.XDG_DATA_HOME | path join "nupm")
}

# Directories to search for scripts when calling source or use
# The default for this is $nu.default-config-dir/scripts
$env.NU_LIB_DIRS = [
    ($nu.default-config-dir | path join 'scripts') # add <nushell-config-dir>/scripts
    ($env.NUPM_HOME | path join "modules")
]

# Directories to search for plugin binaries when calling register
# The default for this is $nu.default-config-dir/plugins
$env.NU_PLUGIN_DIRS = [
    ($nu.default-config-dir | path join 'plugins') # add <nushell-config-dir>/plugins
]

$env.PATH = (
    $env.PATH
    | split row (char esep)
    | prepend ($env.HOME | path join ".local" "bin")
    | prepend ($env.HOME | path join ".cargo" "bin")
    | prepend ($env.XDG_DATA_HOME | path join "mise" "shims" )
    | uniq
)


carapace _carapace nushell | save -f ~/.cache/carapace/init.nu
atuin init nu | save -f ~/.local/share/atuin/init.nu
zoxide init nushell --cmd cd | save -f ~/.cache/.zoxide.nu

$env.EDITOR = "nvim"
$env.VISUAL = $env.EDITOR
