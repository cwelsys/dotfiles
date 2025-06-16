$env:FZF_DEFAULT_OPTS = @"
--color=bg+:$($Flavor.Surface0),bg:$($Flavor.Base),spinner:$($Flavor.Rosewater)
--color=hl:$($Flavor.Red),fg:$($Flavor.Text),header:$($Flavor.Red)
--color=info:$($Flavor.Teal),pointer:$($Flavor.Rosewater),marker:$($Flavor.Rosewater)
--color=fg+:$($Flavor.Text),prompt:$($Flavor.Teal),hl+:$($Flavor.Red)
--color=border:$($Flavor.Surface2)
--layout=reverse --cycle --height=~80% --border=rounded --info=right
"@

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

Set-Alias -Name 'fze' -Value 'Invoke-FuzzyEdit'
Set-Alias -Name 'fzg' -Value 'Invoke-FuzzyGitStatus'
Set-Alias -Name 'fzh' -Value 'Invoke-FuzzyHistory'
Set-Alias -Name 'fzd' -Value 'Invoke-FuzzySetLocation'
Set-Alias -Name 'fzs' -Value 'Invoke-FuzzyScoop'

function _fzf_open_path {
	param (
		[Parameter(Mandatory = $True)]
		[string]$InputPath
	)
	if ($InputPath -match '^.*:\d+:.*$') {
		$InputPath = ($InputPath -split ':')[0]
	}
	if (-not (Test-Path $InputPath)) { Return }

	$Cmds = @{
		'bat'    = { bat $InputPath }
		'cat'    = { Get-Content $InputPath }
		'cd'     = {
			if (Test-Path $InputPath -PathType Leaf) { $InputPath = Split-Path $InputPath -Parent }
			Set-Location $InputPath
		}
		'vim'    = { vim $InputPath }
		'code'   = { code $InputPath }
		'remove' = { Remove-Item -Recurse -Force $InputPath }
		'echo'   = { Write-Output $InputPath }
	}
	$Cmd = $Cmds.Keys | fzf --prompt 'Select Command> '
	& $Cmds[$Cmd]
}

function _fzf_get_path_using_fd {
	$InputPath = fd --type file --follow --hidden --exclude .git |
	fzf --prompt 'Files> ' `
		--header-first `
		--header 'CTRL-T: Switch between Files/Directories' `
		--bind 'ctrl-t:transform:if not "%FZF_PROMPT%"=="Files> " (echo ^change-prompt^(Files^> ^)^+^reload^(fd --type file^)) else (echo ^change-prompt^(Directory^> ^)^+^reload^(fd --type directory^))' `
		--preview 'if "%FZF_PROMPT%"=="Files> " (bat --color=always {} --style=plain) else (eza -T --colour=always --icons=always {})'
	return $InputPath
}

function _fzf_get_path_using_rg {
	$INITIAL_QUERY = "${*:-}"
	$RG_PREFIX = 'rg --column --line-number --no-heading --color=always --smart-case'
	$InputPath = '' |
	fzf --ansi --disabled --query "$INITIAL_QUERY" `
		--bind "start:reload:$RG_PREFIX {q}" `
		--bind "change:reload:sleep 0.1 & $RG_PREFIX {q} || rem" `
		--bind 'ctrl-t:transform:if not "%FZF_PROMPT%" == "1. ripgrep> " (echo ^rebind^(change^)^+^change-prompt^(1. ripgrep^> ^)^+^disable-search^+^transform-query:echo ^{q^} ^> %TEMP%\rg-fzf-f ^& type %TEMP%\rg-fzf-r) else (echo ^unbind^(change^)^+^change-prompt^(2. fzf^> ^)^+^enable-search^+^transform-query:echo ^{q^} ^> %TEMP%\rg-fzf-r ^& type %TEMP%\rg-fzf-f)' `
		--color 'hl:-1:underline,hl+:-1:underline:reverse' `
		--delimiter ':' `
		--prompt '1. ripgrep> ' `
		--preview-label 'Preview' `
		--header 'CTRL-T: Switch between ripgrep/fzf' `
		--header-first `
		--preview 'bat --color=always {1} --highlight-line {2} --style=plain' `
		--preview-window 'up,60%,border-bottom,+{2}+3/3'
	return $InputPath
}

function fdz { _fzf_open_path $(_fzf_get_path_using_fd) }
function rgz { _fzf_open_path $(_fzf_get_path_using_rg) }

Set-PSReadLineKeyHandler -Key 'Ctrl+f' -ScriptBlock {
	[Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()
	[Microsoft.PowerShell.PSConsoleReadLine]::Insert('fdz')
	[Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
}

Set-PSReadLineKeyHandler -Key 'Ctrl+g' -ScriptBlock {
	[Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()
	[Microsoft.PowerShell.PSConsoleReadLine]::Insert('rgz')
	[Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
}
