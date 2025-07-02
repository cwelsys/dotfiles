if (-not $Global:PSDefaultParameterValues) { $Global:PSDefaultParameterValues = @{} }
$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$global:term_app = $env:TERM_PROGRAM
if ($null -ne $env:WT_SESSION) {
	$global:term_app = 'WindowsTerminal'
}

$Env:PWSH = "$HOME/.config/powershell"

if ($IsMacOS) {
	$HOMEBREW_PREFIX = '/opt/homebrew'
	& "$HOMEBREW_PREFIX/bin/brew" shellenv | Invoke-Expression
}

if ($IsWindows) {
	$env:SSH_AUTH_SOCK = '\\.\pipe\openssh-ssh-agent'
}

Remove-Item Alias:rm -Force -ErrorAction SilentlyContinue
Remove-Item Alias:ls -Force -ErrorAction SilentlyContinue
Remove-Item Alias:cat -Force -ErrorAction SilentlyContinue

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
}

if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
	oh-my-posh init pwsh --config "$HOME/.config/posh.toml" | Invoke-Expression
}

if ($PSVersionTable.PSVersion.Major -ne 5) {
	foreach ($file in $((Get-ChildItem -Path "$env:PWSH\lib\*" -Include *.ps1).FullName)) {
		. "$file"
	}
	if (Get-Command mise -ErrorAction SilentlyContinue) {
		mise activate pwsh | Out-String | Invoke-Expression
	}
	Set-ShellIntegration
	if ($IsWindows) {
		PSDynTitle
	}
}


if (Get-Command aliae -ErrorAction SilentlyContinue) {
	aliae init pwsh --config "$HOME/.config/aliae.yaml" | Invoke-Expression
}

if (Get-Command chezmoi -ErrorAction 'SilentlyContinue') {
	chezmoi completion powershell | Out-String | Invoke-Expression
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
