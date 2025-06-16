# Catppuccin (syntax highlighting)
# -----------------------------------------------------------------
# Install Catppuccin PowerShell module if not already installed
if (-not (Get-Module -ListAvailable -Name Catppuccin -ErrorAction SilentlyContinue)) {
	Write-Host 'Installing PowerShell Module Catppuccin...' -ForegroundColor 'Green'
	git clone 'https://github.com/catppuccin/powershell.git' "$env:USERPROFILE\Documents\PowerShell\Modules\Catppuccin"
}

# Import required Modules
Import-Module Catppuccin

$Flavor = $Catppuccin['Mocha']

#PSStyle
$PSStyle.Formatting.TableHeader = $Flavor.Mauve.Foreground()
$PSStyle.Formatting.CustomTableHeaderLabel = $Flavor.Mauve.Background() + $Flavor.Base.Foreground()
$PSStyle.Formatting.Debug = $Flavor.Peach.Foreground()
$PSStyle.Formatting.Verbose = $Flavor.Lavender.Foreground()
$PSStyle.Formatting.FeedbackText = $Flavor.Sky.Foreground()
$PSStyle.FileInfo.SymbolicLink = $Flavor.Blue.Foreground()
$PSStyle.Progress.Style = $Flavor.Blue.Background() + $Flavor.Base.Foreground()

# PSReadline
# ----------------------------------------------------------------
$PSReadLineOptions = @{
	BellStyle                     = 'None'
	Colors                        = @{
		Command                = $Flavor.Blue.Foreground()
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
	ExtraPromptLineCount          = $True
	HistoryNoDuplicates           = $True
	HistorySearchCursorMovesToEnd = $True
	MaximumHistoryCount           = 4096
	PredictionSource              = 'HistoryAndPlugin'
	PredictionViewStyle           = 'ListView'
	PromptText                    = ''
	ShowToolTips                  = $True
}
Set-PSReadLineOption @PSReadLineOptions

Set-PSReadLineKeyHandler -Key Tab -ScriptBlock { Invoke-FzfTabCompletion }
Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
