$Global:PSDefaultParameterValues['Out-Default:OutVariable'] = '+LastOutput'
$Global:PSDefaultParameterValues['Get-ChildItem:Force'] = $true
$Global:PSDefaultParameterValues['del:Force'] = $true

$Global:HostsFile = if ($IsLinux) { '/etc/hosts' } elseif ($IsMacOS) { '' } else { 'C:\Windows\System32\drivers\etc\hosts' }

if ($IsLinux) {
	$XdgDefaults = @{
		XDG_CONFIG_HOME = "$env:HOME/.config"
		XDG_CACHE_HOME  = "$env:HOME/.cache"
		XDG_DATA_HOME   = "$env:HOME/.local/share"
		XDG_STATE_HOME  = "$env:HOME/.local/state"
		XDG_DATA_DIRS   = '/usr/local/share:/usr/share'
		XDG_CONFIG_DIRS = '/etc/xdg'
	}
	$XdgDefaults.GetEnumerator() |
	? { -not (Get-Item env:/$($_.Key) -ErrorAction Ignore) } |
	% { Set-Content env:/$($_.Key) $_.Value }
}

# https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_commonparameters
[string[]]$CommonParameters = (
	'Verbose',
	'Debug',
	'ErrorAction',
	'WarningAction',
	'InformationAction',
	'ErrorVariable',
	'WarningVariable',
	'InformationVariable',
	'ProgressAction',
	'OutVariable',
	'OutBuffer',
	'PipelineVariable',
	'WhatIf',
	'Confirm'
)
[Collections.Generic.HashSet[string]]$CommonParameters = [Collections.Generic.HashSet[string]]::new($CommonParameters)

$ArgumentCompleterSnippet = @'
{
    param ($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
    $Names = @()
    ($Names -like "$wordToComplete*"), ($Names -like "*$wordToComplete*") | Write-Output | Select-Object -Unique
}
'@

Set-Alias os Out-String
Set-Alias vi nvim
Set-Alias vim nvim
Set-Alias cm chezmoi
Set-Alias tf terraform
Set-Alias k kubectl
Set-Alias p podman
Set-Alias c clear
Set-Alias pc podman-compose
Set-Alias mg magick
Set-Alias lg lazygit
Set-Alias ld lazydocker
Set-Alias lj lazyjournal
Set-Alias tg topgrade
Set-Alias keys Get-PSReadLineKeyHandler
Set-Alias clip Set-Clipboard
Set-Alias json ConvertTo-Json
Set-Alias unjson ConvertFrom-Json
if ($IsLinux) {
	Set-Alias scl systemctl
}
if ($IsWindows) {
	Set-Alias su gsudo
	Set-Alias df Get-Volume
}

# Save typing out [pscustomobject]
Add-Type 'public class o : System.Management.Automation.PSObject {}' -WarningAction Ignore

Import-Module Catppuccin -ErrorAction SilentlyContinue
if (Get-Module Catppuccin) {
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
		HistoryNoDuplicates           = $True
		HistorySearchCursorMovesToEnd = $True
		PredictionSource              = 'HistoryAndPlugin'
		PredictionViewStyle           = 'ListView'
		PromptText                    = ''
		ShowToolTips                  = $True
	}
	Set-PSReadLineOption @PSReadLineOptions
}

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

function Get-PSReadlineHistory {
	gc (Get-PSReadLineOption).HistorySavePath
}

# dotnet tab-completion
if (Get-Command dotnet -ErrorAction Ignore) {
	Register-ArgumentCompleter -Native -CommandName dotnet -ScriptBlock {
		param($commandName, $wordToComplete, $cursorPosition)
		dotnet complete --position $cursorPosition "$wordToComplete" | ForEach-Object {
			[Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
		}
	}
}
$env:DOTNET_CLI_TELEMETRY_OPTOUT = '1'

if ($IsWindows) {
	Register-ArgumentCompleter -Native -CommandName winget -ScriptBlock {
		param($wordToComplete, $commandAst, $cursorPosition)
		$word = $wordToComplete.Replace('"', '""')
		$ast = $commandAst.ToString().Replace('"', '""')
		winget complete --word=$word --commandline $ast --position $cursorPosition | ForEach-Object {
			[Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
		}
	}
}

if ($IsWindows -and $env:TERM_PROGRAM -eq 'WezTerm') {
	$env:SSH_AUTH_SOCK = '\\.\pipe\openssh-ssh-agent'
}
elseif (-not $env:SSH_AUTH_SOCK) {
	[string[]]$SshAgentOutput = @()
	if ($IsLinux -and (Get-Command gnome-keyring-daemon -ErrorAction Ignore)) {
		$SshAgentOutput = gnome-keyring-daemon --start
	}
	elseif ($env:TERM_PROGRAM -ne 'vscode') {
		$SshAgentOutput = $(ssh-agent) -replace ';.*' | Select-Object -SkipLast 1
	}
	$env:SSH_AUTH_SOCK = $SshAgentOutput -match 'SSH_AUTH_SOCK' -replace '.*='
}

function Import-Script {
	<#
        .SYNOPSIS
        Imports script as global module. Equivalent to dot-sourcing.
    #>
	param (
		[Parameter(Mandatory, Position = 0, ValueFromPipeline)]
		[ArgumentCompleter({
				param ($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)

				$Files = Get-ChildItem $PSScriptRoot -Filter *.ps1 | % BaseName
            ($Files -like "$wordToComplete*"), ($Files -like "*$wordToComplete*") | Write-Output
			})]
		[string[]]$Name
	)

	if ($MyInvocation.ExpectingInput) {
		$Name = $input
	}

	foreach ($_Name in $Name) {
		[string]$Path = [IO.Path]::ChangeExtension($_Name, 'ps1')  # no-op when already ps1
		if (-not (Test-Path $Path)) { $Path = Join-Path $PSScriptRoot $Path }
		$Path = Resolve-Path $Path -ErrorAction Stop

		$Importer = ". $Path; Export-ModuleMember -Function * -Variable * -Cmdlet * -Alias *"
		$ScriptBlock = [scriptblock]::Create($Importer)
		$Module = New-Module -Name $_Name -ScriptBlock $ScriptBlock

		Import-Module $Module -Global -Force
	}
}
Set-Alias ips Import-Script

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

function Invoke-Eza {
	[alias('ls')]
	param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Path)
	eza.exe $ezaParams @Path
}

function Invoke-EzaGitIgnore {
	[alias('l')]
	param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Path)
	eza.exe $ezaParams --git-ignore @Path
}

# function Invoke-EzaDir {
# 	[alias('ld')]
# 	param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Path)
# 	eza.exe $ezaParams -lDa --show-symlinks --time-style=relative @Path
# }

# function Invoke-EzaFile {
# 	[alias('lf')]
# 	param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Path)
# 	eza.exe $ezaParams -lfa --show-symlinks --time-style=relative @Path
# }

function Invoke-EzaList {
	[alias('ll')]
	param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Path)
	# eza.exe $ezaParams -la --time-style=relative --sort=modified @Path
	eza.exe $ezaParams --all --header --long @Path
}

function Invoke-EzaAll {
	[alias('la')]
	param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Path)
	# eza.exe $ezaParams -la @Path
	eza.exe $ezaParams -lbhHigUmuSa @Path
}

function Invoke-EzaOneline {
	[alias('lo')]
	param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Path)
	eza.exe $ezaParams --oneline @Path
}

function Invoke-EzaExtended {
	[alias('lx')]
	param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Path)
	# eza.exe $ezaParams -la --extended @Path
	eza.exe $ezaParams -lbhHigUmuSa@ @Path
}

function Invoke-EzaTree {
	[alias('lt', 'tree')]
	param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Path)
	eza.exe $ezaParams --tree @Path
}
function Get-CommandInfo {
	[CmdletBinding()]
	[Alias('w')]
	param (
		[Parameter(Mandatory = $true, Position = 0)]
		[string]$Name
	)
	$commandExists = Get-Command $Name -ErrorAction SilentlyContinue
	if ($commandExists) {
		return $commandExists | Select-Object -ExpandProperty Definition
	}
	else {
		Write-Warning "Command not found: $Name."
		break
	}
}
