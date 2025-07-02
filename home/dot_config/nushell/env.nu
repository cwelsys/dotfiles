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
    | prepend ($env.HOME | path join ".local" "share" "cargo" "bin")
    | prepend (if $nu.os-info.name == "macos" {
        ["/opt/homebrew/bin", "/opt/homebrew/sbin"]
    } else if $nu.os-info.name == "linux" {
        ["/home/linuxbrew/.linuxbrew/bin"]
    } else {
        []
    })
    | flatten
    | where ($it | path exists)
    | uniq
)

let cargo_bin_dir = ($env.HOME | path join ".local" "share" "cargo" "bin")
if ($cargo_bin_dir | path exists) {
    try {
        ls $cargo_bin_dir
        | where name =~ "nu_plugin_.*"
        | get name
        | each { |plugin|
            plugin add $plugin
        }
    }
}

mkdir ~/.local/share/nu

mkdir ($nu.data-dir | path join "vendor/autoload")
starship init nu | save -f ($nu.data-dir | path join "vendor/autoload/starship.nu")
aliae init nu --config ~/.config/aliae.yaml --print | save -f ~/.local/share/nu/aliae.nu
mise activate nu | save -f ~/.local/share/nu/mise.nu
carapace _carapace nushell | save -f ~/.local/share/nu/carapace.nu
atuin init nu | save -f ~/.local/share/nu/atuin.nu
zoxide init nushell --cmd cd | save -f ~/.local/share/nu/zoxide.nu

