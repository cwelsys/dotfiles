# 👾 Encoding
$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# 🚌 Tls
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# 🌐 Env
$env:DOTS = & chezmoi source-path
$env:DOTFILES = $env:DOTS
$Env:PWSH = Split-Path $PROFILE -Parent
$Env:LIBS = Join-Path -Path $Env:PWSH -ChildPath "lib"

foreach ($module in $((Get-ChildItem -Path "$env:LIBS\psm\*" -Include *.psm1).FullName )) {
	Import-Module "$module" -Global
}
foreach ($file in $((Get-ChildItem -Path "$env:LIBS\*" -Include *.ps1).FullName)) {
	. "$file"
}

# 🐚 Prompt
if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
	oh-my-posh init pwsh --config "$HOME\.config\posh.toml" | Invoke-Expression
} elseif (Get-Command starship -ErrorAction SilentlyContinue) {
	Invoke-Expression (&starship init powershell)
}

# 💤 zoxide
if (Get-Command zoxide -ErrorAction SilentlyContinue) {
	$Env:_ZO_DATA_DIR = "$Env:PWSH"
	Invoke-Expression (& { (zoxide init powershell --cmd cd | Out-String) })
}

if ( Test-Path '$Env:XDG_DATA_HOME/inshellisense/pwsh/init.ps1' -PathType Leaf ) { . $Env:XDG_DATA_HOME/inshellisense/pwsh/init.ps1 }
