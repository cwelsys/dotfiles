$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

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

$env:DOTS = & chezmoi source-path
$env:DOTFILES = $env:DOTS
$Env:PWSH = Split-Path $PROFILE -Parent
$Env:PYTHONIOENCODING = 'utf-8'
$env:CARAPACE_BRIDGES = 'powershell,inshellisense'
$env:CARAPACE_NOSPACE = '*'
$Env:_ZO_DATA_DIR = "$Env:PWSH"
$env:SSH_AUTH_SOCK = '\\.\pipe\openssh-ssh-agent'
$Env:GLOW_STYLE = "$HOME/.config/glow/catppuccin-mocha.json"

$global:term_app = $env:TERM_PROGRAM
if ($null -ne $env:WT_SESSION) {
	$global:term_app = 'WindowsTerminal'
}

foreach ($module in $((Get-ChildItem -Path "$env:PWSH\psm\*" -Include *.psm1).FullName )) {
	Import-Module "$module" -Global
}

foreach ($file in $((Get-ChildItem -Path "$env:PWSH\lib\*" -Include *.ps1).FullName)) {
	. "$file"
}

Set-ShellIntegration -TerminalProgram $term_app

if (Get-Command 'starship' -ErrorAction SilentlyContinue) {
	Invoke-Expression (&starship init powershell)
	function Invoke-Starship-TransientFunction {
		&starship module character
	}
	if ($env:TERM_PROGRAM -ne 'vscode') {
		Enable-TransientPrompt
	}
}

iex "$(thefuck --alias)"
Invoke-Expression (&scoop-search --hook)
mise activate pwsh | Out-String | Invoke-Expression
carapace _carapace | Out-String | Invoke-Expression
Invoke-Expression (& { ( zoxide init powershell --cmd cd | Out-String ) })
