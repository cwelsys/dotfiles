if (-not $Global:PSDefaultParameterValues) { $Global:PSDefaultParameterValues = @{} }
$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$Env:PWSH = "$HOME/.config/powershell"
$Env:DOTS = '{{ .chezmoi.sourceDir }}'
$isVSCode = $env:TERM_PROGRAM -eq 'vscode'
. "$env:PWSH\lib\priv.ps1"

$timer = New-TimeSpan -Minutes 10
$stamp = "$Env:PWSH/timer.txt"
$send = {
	if ((-not $isVSCode) -and (Get-Command fastfetch -ErrorAction SilentlyContinue)) {
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

if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
	oh-my-posh init pwsh --config "$HOME/.config/posh.toml" | Invoke-Expression
}

Set-PSReadLineOption -HistorySavePath $Env:PWSH/history.txt

	# $PSFzfOptions = @{
	# 	AltCCommand                   = [ScriptBlock] { param($Location) Write-Host $Location }
	# 	PSReadlineChordProvider       = 'Ctrl+t'
	# 	PSReadlineChordReverseHistory = 'Ctrl+r'
	# 	GitKeyBindings                = $True
	# 	TabExpansion                  = $True
	# 	EnableAliasFuzzyKillProcess   = $True
	# }

$AsyncProfile = {
	. "$env:PWSH\lib\cons.ps1"
	if (Get-Command code -ErrorAction SilentlyContinue) { $Env:EDITOR = 'code' }
	else {
		if (Get-Command nvim -ErrorAction SilentlyContinue) { $Env:EDITOR = 'nvim' }
		else { $Env:EDITOR = 'notepad' }
	}

	if (Get-Command python -ErrorAction SilentlyContinue) {
		$Env:PYTHONIOENCODING = 'utf-8'
	}

	if (-not $isVSCode) {

		if (Get-Command scoop -ErrorAction SilentlyContinue) {
			Invoke-Expression (&scoop-search --hook)
			Import-Module scoop-completion
		}

		if (Get-Module -ListAvailable -Name posh-git -ErrorAction SilentlyContinue) {
			Import-Module posh-git -Global
			$Env:POSH_GIT_ENABLED = $true
		}

		if (Get-Module -ListAvailable -Name 'powershell-yaml' -ErrorAction SilentlyContinue) {
			Import-Module -Name powershell-yaml -Global
		}

		if (Get-Module -ListAvailable -Name 'Terminal-Icons' -ErrorAction SilentlyContinue) {
			Import-Module -Name Terminal-Icons -Global
		}
		iex "$(thefuck --alias)"
	}

	if (Get-Command carapace -ErrorAction SilentlyContinue) {
		$env:CARAPACE_BRIDGES = 'zsh,fish,bash,inshellisense'
		$Env:CARAPACE_NOSPACE = '*'
		Invoke-Expression (& { (carapace _carapace powershell | Out-String) })
	}

	if ($PSVersionTable.PSVersion.Major -ne 5) {
		. "$env:PWSH\lib\utils.ps1"
		if (Get-Command mise -ErrorAction SilentlyContinue) {
			mise activate pwsh | Out-String | Invoke-Expression
		}
	}

	if (Get-Command zoxide -ErrorAction SilentlyContinue) {
		$Env:_ZO_DATA_DIR = "$Env:PWSH"
		Invoke-Expression (& { (zoxide init powershell --cmd cd | Out-String) })
	}

	if (Import-Module PSFzf -PassThru -ea Ignore) {
    Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t' -PSReadlineChordReverseHistory 'Ctrl+r'
	}
}

if ((-not $isVSCode) -and (Import-Module ProfileAsync -PassThru -ea Ignore)) {
	$splat = if ((Get-Command Import-ProfileAsync).Parameters.LogPath) { @{LogPath = "$env:PWSH\async.log" } } else { @{} }
	Import-ProfileAsync $AsyncProfile @splat
}

else {
	. $AsyncProfile
}

