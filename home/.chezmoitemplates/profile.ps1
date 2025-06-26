if (-not $Global:PSDefaultParameterValues) { $Global:PSDefaultParameterValues = @{} }

$OutputEncoding = [console]::InputEncoding = [console]::OutputEncoding = [Text.Utf8Encoding]::new($false)
$Global:PSDefaultParameterValues['*:Encoding'] = $Global:PSDefaultParameterValues['*:InputEncoding'] = $Global:PSDefaultParameterValues['*:OutputEncoding'] = $OutputEncoding

$Env:PWSH = '$HOME/.config/powershell'
$Env:DOTS = {{ .chezmoi.sourceDir }}

if ($PSVersionTable.PSEdition -ne 'Core') {
	Set-Variable IsWindows -Value $true -Option Constant -Scope Global
	Set-Variable IsLinux -Value $false -Option Constant -Scope Global
	Set-Variable IsMacOS -Value $false -Option Constant -Scope Global
	Set-Variable IsCoreCLR -Value $false -Option Constant -Scope Global
}

if ($env:TERM_PROGRAM -ne 'vscode') {
	fastfetch
}

if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
	oh-my-posh init pwsh --config "$HOME/.config/posh.toml" | Invoke-Expression
}

Set-PSReadLineOption -HistorySavePath $Env:PWSH/history.txt

$AsyncProfile = {
	foreach ($file in $((Get-ChildItem -Path "$env:PWSH/lib/*" -Include *.ps1).FullName)) {
		. "$file"
	}
	if (Get-Command code -ErrorAction SilentlyContinue) { $Env:EDITOR = 'code' }
	else {
		if (Get-Command nvim -ErrorAction SilentlyContinue) { $Env:EDITOR = 'nvim' }
		else { $Env:EDITOR = 'notepad' }
	}
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
	if (Get-Module -ListAvailable -Name 'PSFzf' -ErrorAction SilentlyContinue) {
		Import-Module -Name PSFzf -Global
	}
	if (Get-Command python -ErrorAction SilentlyContinue) {
		$Env:PYTHONIOENCODING = 'utf-8'
	}
	if ($IsWindows) {
		iex "$(thefuck --alias)"
	}
	if (Get-Command mise -ErrorAction SilentlyContinue) {
		mise activate pwsh | Out-String | Invoke-Expression
	}
	if (Get-Command carapace -ErrorAction SilentlyContinue) {
		$env:CARAPACE_BRIDGES = 'zsh,fish,bash,inshellisense'
		$Env:CARAPACE_NOSPACE = '*'
		Invoke-Expression (& { (carapace _carapace powershell | Out-String) })
	}
	if (Get-Command zoxide -ErrorAction SilentlyContinue) {
		$Env:_ZO_DATA_DIR = "$Env:PWSH"
		Invoke-Expression (& { (zoxide init powershell --cmd cd | Out-String) })
	}
}

if (Import-Module ProfileAsync -PassThru -ea Ignore) {
	$splat = if ((Get-Command Import-ProfileAsync).Parameters.LogPath) { @{LogPath = 'profile.log' } } else { @{} }
	Import-ProfileAsync $AsyncProfile @splat
}
else {
	. $AsyncProfile
}
$commandOverride = [ScriptBlock] { param($Location) Write-Host $Location }
$PSFzfOptions = @{
	AltCCommand                   = $commandOverride
	PSReadlineChordProvider       = 'Ctrl+t'
	PSReadlineChordReverseHistory = 'Ctrl+r'
	GitKeyBindings                = $True
	TabExpansion                  = $True
	EnableAliasFuzzyKillProcess   = $True
}
Set-PsFzfOption @PSFzfOptions
