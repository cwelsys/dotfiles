$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$Env:DOTS = & chezmoi source-path
$Env:PWSH = Split-Path $PROFILE -Parent
$Env:PYTHONIOENCODING = 'utf-8'
$Env:CARAPACE_BRIDGES = 'powershell,inshellisense'
$Env:CARAPACE_NOSPACE = '*'
$Env:_ZO_DATA_DIR = "$Env:PWSH"

foreach ($module in $((Get-ChildItem -Path "$env:PWSH\psm\*" -Include *.psm1).FullName )) {
	Import-Module "$module" -Global
}

foreach ($file in $((Get-ChildItem -Path "$env:PWSH\lib\*" -Include *.ps1).FullName)) {
	. "$file"
}

if ($InteractiveMode -and $env:TERM_PROGRAM -ne 'vscode') {
	fastfetch
}

if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
	oh-my-posh init pwsh --config "$HOME\.config\posh.toml" | Invoke-Expression
}
elseif (Get-Command starship -ErrorAction SilentlyContinue) {
	. "$env:PWSH\starship.ps1"
}

iex "$(thefuck --alias)"
Invoke-Expression (&scoop-search --hook)
mise activate pwsh | Out-String | Invoke-Expression
carapace _carapace | Out-String | Invoke-Expression
Invoke-Expression (& { ( zoxide init powershell --cmd cd | Out-String ) })
