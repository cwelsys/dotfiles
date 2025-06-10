source ./aliae.nu
source ./priv.nu
source ./themes/catppuccin_mocha.nu
source ~/.cache/carapace/init.nu
source ~/.local/share/atuin/init.nu
source ~/.cache/.zoxide.nu
source ~/.cache/.mise.nu

$env.config.show_banner = false
$env.config.edit_mode = 'vi'


oh-my-posh init nu --config .config/posh.toml
