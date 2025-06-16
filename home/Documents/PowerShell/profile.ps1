# 👾 Encoding
$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# 🚌 Tls
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

if ([Environment]::GetCommandLineArgs().Contains('-NonInteractive')) {
	$Global:InteractiveMode = $false
}
else {
	$Global:InteractiveMode = $true
}

if ($InteractiveMode -and $env:TERM_PROGRAM -ne 'vscode') {
	fastfetch
}

# 🌐 Env
$env:DOTS = & chezmoi source-path
$env:DOTFILES = $env:DOTS
$Env:PWSH = Split-Path $PROFILE -Parent
$Env:PYTHONIOENCODING = 'utf-8'
$env:CARAPACE_BRIDGES = 'powershell,inshellisense'
$env:CARAPACE_NOSPACE = '*'
$Env:_ZO_DATA_DIR = "$Env:PWSH"
$env:SSH_AUTH_SOCK = '\\.\pipe\openssh-ssh-agent'
$Env:GLOW_STYLE = "$HOME/.config/glow/catppuccin-mocha.json"
. $Env:PWSH\priv.ps1
. $Env:PWSH\utils.ps1

foreach ($module in $((Get-ChildItem -Path "$env:PWSH\psm\*" -Include *.psm1).FullName )) {
	Import-Module "$module" -Global
}

function Invoke-Starship-TransientFunction {
	&starship module character
}

Invoke-Expression (&starship init powershell)
Enable-TransientPrompt

Invoke-Expression (&scoop-search --hook)
mise activate pwsh | Out-String | Invoke-Expression
carapace _carapace | Out-String | Invoke-Expression

. $Env:PWSH\readline.ps1

Invoke-Expression (& { ( zoxide init powershell --cmd cd | Out-String ) })
