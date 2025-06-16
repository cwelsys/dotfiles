# 👾 Encoding
$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# 🚌 Tls
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# 🌐 Env
$env:DOTS = & chezmoi source-path
$env:DOTFILES = $env:DOTS
$Env:PWSH = Split-Path $PROFILE -Parent
$Env:LIBS = Join-Path -Path $Env:PWSH -ChildPath 'lib'
$Env:PYTHONIOENCODING = 'utf-8'
$env:CARAPACE_BRIDGES = 'powershell,inshellisense'
$env:CARAPACE_NOSPACE = '*'
$Env:_ZO_DATA_DIR = "$Env:PWSH"
$env:SSH_AUTH_SOCK = '\\.\pipe\openssh-ssh-agent'
$Env:GLOW_STYLE = "$HOME/.config/glow/catppuccin-mocha.json"

. "$env:LIBS\utils.ps1"

# 📝 Editor
if (Get-Command code -ErrorAction SilentlyContinue) { $Env:EDITOR = 'code' }
else {
	if (Get-Command nvim -ErrorAction SilentlyContinue) { $Env:EDITOR = 'nvim' }
	else { $Env:EDITOR = 'notepad' }
}

foreach ($module in $((Get-ChildItem -Path "$env:LIBS\psm\*" -Include *.psm1).FullName )) {
	Import-Module "$module" -Global
}
# foreach ($file in $((Get-ChildItem -Path "$env:LIBS\*" -Include *.ps1).FullName)) {
# 	. "$file"
# }

# 🐚 Prompt
function Invoke-Starship-TransientFunction {
	&starship module character
}

Invoke-Expression (&starship init powershell)
Enable-TransientPrompt
Invoke-Expression (& { ( zoxide init powershell --cmd cd | Out-String ) })
carapace _carapace | Out-String | Invoke-Expression

if ([Environment]::GetCommandLineArgs().Contains('-NonInteractive')) {
	return
}
fastfetch
