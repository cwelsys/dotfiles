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

Remove-Item Alias:rm -Force -ErrorAction SilentlyContinue
Remove-Item Alias:ls -Force -ErrorAction SilentlyContinue
Remove-Item Alias:cat -Force -ErrorAction SilentlyContinue

foreach ($file in $((Get-ChildItem -Path "$env:PWSH\lib\*" -Include *.ps1 -Exclude '7.ps1').FullName)) {
	. "$file"
}

if (Get-Command starship -ErrorAction SilentlyContinue) {
	function Invoke-Starship-TransientFunction {
  &starship module character
	}
	Invoke-Expression (&starship init powershell)
	Enable-TransientPrompt
}

if ($PSVersionTable.PSVersion.Major -ge 7) {
	. "$env:PWSH\lib\7.ps1"
}

if (Get-Command scoop -ErrorAction SilentlyContinue) {
	Invoke-Expression (&scoop-search --hook)
}

if (Get-Command chezmoi -ErrorAction 'SilentlyContinue') {
	chezmoi completion powershell | Out-String | Invoke-Expression
}

if (Get-Command zoxide -ErrorAction SilentlyContinue) {
	Invoke-Expression (& { (zoxide init powershell --cmd cd | Out-String) })
}
