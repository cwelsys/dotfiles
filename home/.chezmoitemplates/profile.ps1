if (-not $Global:PSDefaultParameterValues) { $Global:PSDefaultParameterValues = @{} }
$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$Env:PWSH = "$HOME/.config/powershell"

$timer = New-TimeSpan -Minutes 10
$stamp = "$Env:PWSH/timer.txt"
$send = {
	if ((-not $env:TERM_PROGRAM -eq 'vscode') -and (Get-Command fastfetch -ErrorAction SilentlyContinue)) {
		if ([Environment]::GetCommandLineArgs().Contains('-NonInteractive')) {
			Return
		}
		fastfetch
	}
}

if (Test-Path $stamp) {
	$last = (Get-Item $stamp).LastWriteTime
}
else {
	$last = [DateTime]::MinValue
}

$ct = Get-Date
$been = $ct - $last
if ($been -ge $timer) {
	& $send
	'' | Out-File $stamp
}

if (Get-Command code -ErrorAction SilentlyContinue) { $Env:EDITOR = 'code' }
else {
	if (Get-Command nvim -ErrorAction SilentlyContinue) { $Env:EDITOR = 'nvim' }
	else { $Env:EDITOR = 'notepad' }
}

if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
	oh-my-posh init pwsh --config "$HOME/.config/posh.toml" | Invoke-Expression
}

if (Get-Command aliae -ErrorAction SilentlyContinue) {
	aliae init pwsh | Invoke-Expression
}

if (Get-Command mise -ErrorAction SilentlyContinue) {
	mise activate pwsh | Out-String | Invoke-Expression
}

foreach ($file in $((Get-ChildItem -Path "$env:PWSH\lib\*" -Include *.ps1).FullName)) {
	. "$file"
}

if (Get-Command carapace -ErrorAction SilentlyContinue) {
	$env:CARAPACE_BRIDGES = 'zsh,fish,bash,inshellisense'
	$Env:CARAPACE_NOSPACE = '*'
	Invoke-Expression (& { (carapace _carapace powershell | Out-String) })
}

if (Get-Command scoop -ErrorAction SilentlyContinue) {
	Invoke-Expression (&scoop-search --hook)
}

if (Get-Command zoxide -ErrorAction SilentlyContinue) {
	$Env:_ZO_DATA_DIR = "$Env:PWSH"
	Invoke-Expression (& { (zoxide init powershell --cmd cd | Out-String) })
}
