Import-Module Catppuccin -ErrorAction SilentlyContinue

$Flavor = $Catppuccin['Mocha']

$env:FZF_DEFAULT_OPTS = @"
--color=bg+:$($Flavor.Surface0),bg:$($Flavor.Base),spinner:$($Flavor.Rosewater)
--color=hl:$($Flavor.Red),fg:$($Flavor.Text),header:$($Flavor.Red)
--color=info:$($Flavor.Teal),pointer:$($Flavor.Rosewater),marker:$($Flavor.Rosewater)
--color=fg+:$($Flavor.Text),prompt:$($Flavor.Teal),hl+:$($Flavor.Red)
--color=border:$($Flavor.Surface2)
--layout=reverse --cycle --height=~80% --border=rounded --info=right
--bind=alt-w:toggle-preview-wrap
--bind=ctrl-e:toggle-preview
"@

$PSStyle.Formatting.TableHeader = $Flavor.Teal.Foreground()
$PSStyle.Formatting.CustomTableHeaderLabel = $Flavor.Teal.Background() + $Flavor.Base.Foreground()
$PSStyle.Formatting.Debug = $Flavor.Peach.Foreground()
$PSStyle.Formatting.Verbose = $Flavor.Lavender.Foreground()
$PSStyle.Formatting.FeedbackText = $Flavor.Sky.Foreground()
$PSStyle.FileInfo.SymbolicLink = $Flavor.Blue.Foreground()
$PSStyle.Progress.Style = $Flavor.Teal.Background() + $Flavor.Base.Foreground()

$PSReadLineOptions = @{
	BellStyle                     = 'None'
	Colors                        = @{
		Command                = $Flavor.Teal.Foreground()
		Comment                = $Flavor.Overlay0.Foreground()
		ContinuationPrompt     = $Flavor.Teal.Foreground()
		Default                = $Flavor.Text.Foreground()
		Emphasis               = $Flavor.Lavender.Foreground()
		Error                  = $Flavor.Red.Foreground()
		InlinePrediction       = $Flavor.Overlay0.Foreground()
		Keyword                = $Flavor.Mauve.Foreground()
		ListPrediction         = $Flavor.Overlay0.Foreground()
		ListPredictionSelected = $Flavor.Surface0.Background() + $Flavor.Mauve.Foreground()
		Member                 = $Flavor.Rosewater.Foreground()
		Number                 = $Flavor.Peach.Foreground()
		Operator               = $Flavor.Yellow.Foreground()
		Parameter              = $Flavor.Pink.Foreground()
		Selection              = $Flavor.Surface0.Background()
		String                 = $Flavor.Green.Foreground()
		Type                   = $Flavor.Sky.Foreground()
		Variable               = $Flavor.Mauve.Foreground()
	}
	HistorySavePath               = "$Env:PWSH/history.txt"
	HistoryNoDuplicates           = $True
	HistorySearchCursorMovesToEnd = $True
	PredictionSource              = 'HistoryAndPlugin'
	PredictionViewStyle           = 'Inline'
	PromptText                    = ''
	ShowToolTips                  = $True
}
Set-PSReadLineOption @PSReadLineOptions

Set-PSReadlineKeyHandler -Key UpArrow -Function HistorySearchBackward
Set-PSReadlineKeyHandler -Key DownArrow -Function HistorySearchForward
Set-PSReadlineKeyHandler -Chord Tab -ScriptBlock { Invoke-FzfTabCompletion }
Set-PSReadLineKeyHandler -Chord Escape -Function CancelLine
Set-PSReadLineKeyHandler -Chord Ctrl+a -Function SelectAll
Set-PSReadlineKeyHandler -Chord Ctrl+z -Function Undo
Set-PSReadlineKeyHandler -Chord Ctrl+y -Function Redo
Set-PSReadlineKeyHandler -Chord Shift+Enter -Function InsertLineBelow

if ($IsWindows) {
	Set-PSReadlineKeyHandler -Chord Ctrl+c -Function CopyOrCancelLine
	Set-PSReadlineKeyHandler -Chord Ctrl+x -Function Cut
	Set-PSReadlineKeyHandler -Chord Ctrl+v -Function Paste
}
else {
	Set-PSReadlineKeyHandler -Chord Ctrl+c -Function CopyOrCancelLine
	Set-PSReadlineKeyHandler -Chord Ctrl+x -Function Cut
	Set-PSReadlineKeyHandler -Chord Ctrl+v -Function Paste
	Set-PSReadlineKeyHandler -Chord Ctrl+@ -Function MenuComplete  # Unix shells always intercept Ctrl-space - Fedora seems to map it to Ctrl-@
}

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

# https://gist.github.com/rkeithhill/3103994447fd307b68be
Set-PSReadlineKeyHandler -Chord '(', '[', '{', "'", '"' -Description 'Wrap selection in brackets or quotes' -ScriptBlock {
	param ($Key, $Arg)

	$L = $Key.KeyChar.ToString()
	$R = @{
		'(' = ')'
		'[' = ']'
		'{' = '}'
		"'" = "'"
		'"' = '"'
	}[$L]

	$SelStart = $null
	$SelLength = $null
	[Microsoft.PowerShell.PSConsoleReadLine]::GetSelectionState([ref]$SelStart, [ref]$SelLength)

	if ($SelStart -eq -1 -and $SelLength -eq -1) {
		# Nothing selected
		[Microsoft.PowerShell.PSConsoleReadLine]::Insert($L)
		return
	}

	$Buffer = $null
	$Cursor = $null
	[Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$Buffer, [ref]$Cursor)

	$Replacement = $L + $Buffer.SubString($SelStart, $SelLength) + $R
	[Microsoft.PowerShell.PSConsoleReadLine]::Replace($SelStart, $SelLength, $Replacement)
}

# https://unix.stackexchange.com/questions/196098/copy-paste-in-xfce4-terminal-adds-0-and-1/196574#196574
if ($IsLinux) { printf '\e[?2004l' }

$ezaParams = @(
	'--git'
	'--group'
	'--hyperlink'
	'--group-directories-first'
	'--time-style=long-iso'
	'--color-scale=all'
	'--icons'
	'-I=*NTUSER.DAT*|*ntuser.dat*|.DS_Store|.idea|.venv|.vs|__pycache__|cache|debug|.git|node_modules|venv'
)

$PSFzfOptions = @{
	PSReadlineChordProvider       = 'Ctrl+t'
	PSReadlineChordReverseHistory = 'Ctrl+r'
	GitKeyBindings                = $True
	TabExpansion                  = $True
	EnableAliasFuzzyKillProcess   = $True
}

Set-PsFzfOption @PSFzfOptions
