# 👾 Encoding
$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# 🚌 Tls
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# 🌐 Env
if (Get-Command chezmoi -ErrorAction SilentlyContinue) {
	$env:DOTS = & chezmoi source-path
} else {
	$env:DOTS = "$HOME\.local\share\chezmoi\home"
}
$Env:PWSH = Split-Path $PROFILE -Parent
$Env:LIBS = Join-Path -Path $Env:PWSH -ChildPath "lib"
$env:POWERSHELL_UPDATECHECK = "Off"

# 📝 Editor
if (Get-Command code -ErrorAction SilentlyContinue) { $Env:EDITOR = "code" }
else {
	if (Get-Command nvim -ErrorAction SilentlyContinue) { $Env:EDITOR = "nvim" }
	else { $Env:EDITOR = "notepad" }
}

# 🐚 Prompt
if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
    oh-my-posh init pwsh --config "$HOME\.config\zen.toml" | Invoke-Expression
} elseif (Get-Command starship -ErrorAction SilentlyContinue) {
    Invoke-Expression (&starship init powershell)
}

# 🥣 scoop
if (Get-Command scoop -ErrorAction SilentlyContinue) {
	Invoke-Expression (&scoop-search --hook)
}

# 🚬 source
foreach ($module in $((Get-ChildItem -Path "$env:LIBS\psm\*" -Include *.psm1).FullName )) {
	Import-Module "$module" -Global
}
foreach ($file in $((Get-ChildItem -Path "$env:LIBS\ps1\*" -Include *.ps1).FullName)) {
	. "$file"
}

# 🐢 completion
# if (Test-Path "$env:LIBS\completions\init.ps1" -PathType Leaf) {
# 	. "$env:LIBS\completions\init.ps1"
# }

# 💤 zoxide
if (Get-Command zoxide -ErrorAction SilentlyContinue) {
	$Env:_ZO_DATA_DIR = "$Env:PWSH"
	Invoke-Expression (& { (zoxide init powershell --cmd cd | Out-String) })
}

# 🐶 FastFetch
if (Get-Command fastfetch -ErrorAction SilentlyContinue) {
	if ([Environment]::GetCommandLineArgs().Contains("-NonInteractive") -or $Env:TERM_PROGRAM -eq "vscode") {
		Return
	}
	fastfetch
}
