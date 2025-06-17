$env:DOTS = & chezmoi source-path
$Env:DOTS = $env:DOTS
$Env:PWSH = Split-Path $PROFILE -Parent
$Env:PYTHONIOENCODING = 'utf-8'
$env:CARAPACE_BRIDGES = 'powershell,inshellisense'
$env:CARAPACE_NOSPACE = '*'
$Env:_ZO_DATA_DIR = "$Env:PWSH"

foreach ($module in $((Get-ChildItem -Path "$env:PWSH\psm\*" -Include *.psm1).FullName )) {
	Import-Module "$module" -Global
}

. "$env:PWSH\lib\utils"
. "$env:PWSH\lib\priv"

Invoke-Expression (&starship init powershell)

mise activate pwsh | Out-String | Invoke-Expression
carapace _carapace | Out-String | Invoke-Expression
Invoke-Expression (& { ( zoxide init powershell --cmd cd | Out-String ) })
