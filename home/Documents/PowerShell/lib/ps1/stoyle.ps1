#requires -Module PSReadline
#requires -Module PSFzf
#requires -Module CompletionPredictor

if (!(Get-Command fzf -ErrorAction SilentlyContinue)) { return }
if (-not (Get-Module -ListAvailable -Name Catppuccin -ErrorAction SilentlyContinue)) {
	Write-Host "Installing PowerShell Module Catppuccin..." -ForegroundColor "Green"
	git clone "https://github.com/catppuccin/powershell.git" "$env:USERPROFILE\Documents\PowerShell\Modules\Catppuccin"
}

Import-Module Catppuccin

$Flavor = $Catppuccin['Mocha']
$PSStyle.Formatting.Debug = $Flavor.Sky.Foreground()
$PSStyle.Formatting.Error = $Flavor.Red.Foreground()
$PSStyle.Formatting.ErrorAccent = $Flavor.Blue.Foreground()
$PSStyle.Formatting.FormatAccent = $Flavor.Teal.Foreground()
$PSStyle.Formatting.TableHeader = $Flavor.Rosewater.Foreground()
$PSStyle.Formatting.Verbose = $Flavor.Yellow.Foreground()
$PSStyle.Formatting.Warning = $Flavor.Peach.Foreground()

$Colors = @{
	# Powershell colours
	ContinuationPrompt     = $Flavor.Teal.Foreground()
	Emphasis               = $Flavor.Red.Foreground()
	Selection              = $Flavor.Surface0.Background()

	# PSReadLine prediction colours
	InlinePrediction       = $Flavor.Overlay0.Foreground()
	ListPrediction         = $Flavor.Teal.Foreground()
	ListPredictionSelected = $Flavor.Surface0.Background()

	# Syntax highlighting
	Command                = $Flavor.Blue.Foreground()
	Comment                = $Flavor.Overlay0.Foreground()
	Default                = $Flavor.Text.Foreground()
	Error                  = $Flavor.Red.Foreground()
	Keyword                = $Flavor.Mauve.Foreground()
	Member                 = $Flavor.Rosewater.Foreground()
	Number                 = $Flavor.Peach.Foreground()
	Operator               = $Flavor.Sky.Foreground()
	Parameter              = $Flavor.Pink.Foreground()
	String                 = $Flavor.Green.Foreground()
	Type                   = $Flavor.Yellow.Foreground()
	Variable               = $Flavor.Lavender.Foreground()
}

$PSReadLineOptions = @{
	ExtraPromptLineCount = $true
	HistoryNoDuplicates  = $true
	MaximumHistoryCount  = 5000
	PredictionSource     = "HistoryAndPlugin"
	PredictionViewStyle  = "ListView"
	ShowToolTips         = $true
}

Set-PSReadLineOption -Colors $Colors
Set-PSReadLineOption @PSReadLineOptions
Set-PSReadlineKeyHandler -Key UpArrow -Function HistorySearchBackward
Set-PSReadlineKeyHandler -Key DownArrow -Function HistorySearchForward

# fzf
$env:FZF_DEFAULT_OPTS = "--color=fg:#cad3f5,fg+:#d0d0d0,bg:-1,bg+:#262626 --color=hl:#ed8796,hl+:#5fd7ff,info:#94e2d5,marker:#AAE682 --color=prompt:#94e2d5,spinner:#f4dbd6,pointer:#f4dbd6,header:#ed8796 --color=border:#585b70,label:#aeaeae,query:#d9d9d9 --layout=reverse --cycle --height=~80% --border=rounded --bind=alt-w:toggle-preview-wrap --bind=ctrl-e:toggle-preview"

$env:_PSFZF_FZF_DEFAULT_OPTS = $env:FZF_DEFAULT_OPTS

# Directory navigation
$env:FZF_ALT_C_COMMAND = "fd --type d --hidden --follow --exclude .git --fixed-strings --strip-cwd-prefix --color always"
$env:FZF_ALT_C_OPTS = "--prompt='Directory  ' --preview='eza --tree --level=1 --color=always --icons=always {}' --preview-window=right:50%:border-left"

# File selection
$env:FZF_CTRL_T_COMMAND = "fd --type f --hidden --follow --exclude .git --strip-cwd-prefix --color always"
$env:FZF_CTRL_T_OPTS = "--prompt='File  ' --preview='bat --style=numbers --color=always --line-range :500 {}' --preview-window=right:60%:border-left"

$commandOverride = [ScriptBlock] { param($Location) Set-Location $Location }
Set-PsFzfOption -AltCCommand $commandOverride

Set-PSReadlineKeyHandler -Key Tab -ScriptBlock { Invoke-FzfTabCompletion }
Set-PsFzfOption -PSReadlineChordProvider "Ctrl+t" -PSReadlineChordReverseHistory "Ctrl+r" -PSReadlineChordReverseHistoryArgs "Alt+a"
Set-PsFzfOption -GitKeyBindings -EnableAliasFuzzyGitStatus -EnableAliasFuzzyEdit -EnableAliasFuzzyKillProcess -EnableAliasFuzzyScoop -EnableFd
Set-PsFzfOption -TabExpansion
