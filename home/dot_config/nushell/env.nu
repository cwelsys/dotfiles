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

# To add entries to PATH (on Windows you might use Path), you can use the following pattern:
# $env.PATH = ($env.PATH | split row (char esep) | prepend '/some/path')
# An alternate way to add entries to $env.PATH is to use the custom command `path add`
# which is built into the nushell stdlib:
# use std "path add"
# $env.PATH = ($env.PATH | split row (char esep))
# path add /some/path
# path add ($env.CARGO_HOME | path join "bin")
# path add ($env.HOME | path join ".local" "bin")
# $env.PATH = ($env.PATH | uniq)

$env.PATH = (
    $env.PATH
        | split row (char esep)
        | prepend ($env.HOME | path join ".local" "bin")
        | prepend ($env.NUPM_HOME | path join "scripts")
        | uniq
)

# To load from a custom file you can use:
# source ($nu.default-config-dir | path join 'custom.nu')

carapace _carapace nushell | save -f ~/.cache/carapace/init.nu
atuin init nu | save -f ~/.local/share/atuin/init.nu
zoxide init nushell --cmd cd | save -f ~/.cache/.zoxide.nu
mise activate nu | save -f ~/.cache/.mise.nu

$env.EDITOR = "nvim"
$env.VISUAL = $env.EDITOR
