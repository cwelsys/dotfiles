<#
    .SYNOPSIS
        PSReadLine & PSFzf Configuration File.
    .DESCRIPTION
        This script is sets up the PSReadLine and PSFzf modules with a custom color scheme and key bindings.
#>

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

$Env:GLOW_STYLE = "$HOME/.config/glow/catppuccin-mocha.json"

#PSStyle
$PSStyle.Formatting.TableHeader = $Flavor.Teal.Foreground()
$PSStyle.Formatting.CustomTableHeaderLabel = $Flavor.Teal.Background() + $Flavor.Base.Foreground()
$PSStyle.Formatting.Debug = $Flavor.Peach.Foreground()
$PSStyle.Formatting.Verbose = $Flavor.Lavender.Foreground()
$PSStyle.Formatting.FeedbackText = $Flavor.Sky.Foreground()
$PSStyle.FileInfo.SymbolicLink = $Flavor.Blue.Foreground()
$PSStyle.Progress.Style = $Flavor.Teal.Background() + $Flavor.Base.Foreground()

# PSReadline
# ----------------------------------------------------------------
$PSReadLineOptions = @{
    BellStyle                     = "None"
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
    ExtraPromptLineCount          = $True
    HistoryNoDuplicates           = $True
    HistorySearchCursorMovesToEnd = $True
    MaximumHistoryCount           = 4096
    PredictionSource              = "HistoryAndPlugin"
    PredictionViewStyle           = "ListView"
    PromptText                    = ''
    ShowToolTips                  = $True
}

Set-PSReadLineOption @PSReadLineOptions
Set-PSReadlineKeyHandler -Key UpArrow -Function HistorySearchBackward
Set-PSReadlineKeyHandler -Key DownArrow -Function HistorySearchForward
Set-PSReadlineKeyHandler -Key Tab -ScriptBlock { Invoke-FzfTabCompletion }

$parameters = @{
    Key              = "F1"
    BriefDescription = "Command Help"
    LongDescription  = "Invoke the help window for the current command or prompt."
    ScriptBlock      = {
        param($key, $arg)

        $ast = $null
        $tokens = $null
        $errors = $null
        $cursor = $null
        [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$ast, [ref]$tokens, [ref]$errors, [ref]$cursor)

        $commandAst = $ast.FindAll( {
                $node = $args[0]
                $node -is [CommandAst] -and
                $node.Extent.StartOffset -le $cursor -and
                $node.Extent.EndOffset -ge $cursor
            }, $true) | Select-Object -Last 1

        if ($commandAst -ne $null) {
            $commandName = $commandAst.GetCommandName()
            if ($commandName -ne $null) {
                $command = $ExecutionContext.InvokeCommand.GetCommand($commandName, 'All')
                if ($command -is [AliasInfo]) {
                    $commandName = $command.ResolvedCommandName
                }

                if ($commandName -ne $null) {
                    Get-Help $commandName -ShowWindow
                }
            }
        }
    }
}
Set-PSReadLineKeyHandler @parameters

# Reference: copy from
# - https://ianmorozoff.com/2023/01/10/predictive-intellisense-on-by-default-in-powershell-7-3/#keybinding
$parameters1 = @{
    Key              = "F4"
    BriefDescription = "Toggle PSReadLineOption PredictionSource"
    LongDescription  = "Toggle PSReadLineOption PredictionSource option between 'None' and 'HistoryAndPlugin'"
    ScriptBlock      = {
        # Get the current state of PredictionSource
        $state = (Get-PSReadLineOption).PredictionSource

        # Toggle between None and HistoryAndPlugin
        switch ($state) {
            "None" { Set-PSReadLineOption -PredictionSource HistoryAndPlugin }
            "History" { Set-PSReadLineOption -PredictionSource None }
            "Plugin" { Set-PSReadLineOption -PredictionSource None }
            "HistoryAndPlugin" { Set-PSReadLineOption -PredictionSource None }
            Default { Write-Host "Current PSReadlineOption PredictionSource is Unknown" -ForegroundColor "Cyan" }
        }

        # Trigger autocomplete to appear without changing the line
        # InvokePrompt() does not cause ListView style suggestions to disappear when toggling off
        # [Microsoft.PowerShell.PSConsole.ReadLine]::InvokePrompt()

        # Trigger autocomplete to appear or disappear while preserving the current input
        [Microsoft.PowerShell.PSConsoleReadLine]::Insert(' ')
        [Microsoft.PowerShell.PSConsoleReadLine]::BackwardDeleteChar()
    }
}
Set-PSReadLineKeyHandler @parameters1

# Sometimes you want to get a property of invoke a member on what you've entered so far
# but you need parens to do that.  This binding will help by putting parens around the current selection,
# or if nothing is selected, the whole line.
$parameters2 = @{
    Key              = 'Alt+('
    BriefDescription = "Parenthesize Selection"
    LongDescription  = "Put parenthesis around the selection or entire line and move the cursor to after the closing parenthesis"
    ScriptBlock      = {
        param($key, $arg)
        $selectionStart = $null
        $selectionLength = $null
        [Microsoft.PowerShell.PSConsoleReadLine]::GetSelectionState([ref]$selectionStart, [ref]$selectionLength)

        $line = $null
        $cursor = $null
        [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)
        if ($selectionStart -ne 1) {
            [Microsoft.PowerShell.PSConsoleReadLine]::Replace($selectionStart, $selectionLength, '(' + $line.SubString($selectionStart, $selectionLength) + ')')
            [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($selectionStart + $selectionLength + 2)
        } else {
            [Microsoft.PowerShell.PSConsoleReadLine]::Replace(0, $line.Length, '(' + $line + ')')
            [Microsoft.PowerShell.PSConsoleReadLine]::EndOfLine()
        }
    }
}
Set-PSReadLineKeyHandler @parameters2

# Each time you press Alt+', this key handler will change the token
# under or before the cursor.  It will cycle through single quotes, double quotes, or
# no quotes each time it is invoked.
$parameters3 = @{
    Key              = "Alt+'"
    BriefDescription = "Toggle Quote Argument"
    LongDescription  = "Toggle quotes on the argument under the cursor"
    ScriptBlock      = {
        param($key, $arg)

        $ast = $null
        $tokens = $null
        $errors = $null
        $cursor = $null
        [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$ast, [ref]$tokens, [ref]$errors, [ref]$cursor)

        $tokenToChange = $null
        foreach ($token in $tokens) {
            $extent = $token.Extent
            if ($extent.StartOffset -le $cursor -and $extent.EndOffset -ge $cursor) {
                $tokenToChange = $token

                # If the cursor is at the end (it's really 1 past the end) of the previous token,
                # we only want to change the previous token if there is no token under the cursor
                if ($extent.EndOffset -eq $cursor -and $foreach.MoveNext()) {
                    $nextToken = $foreach.Current
                    if ($nextToken.Extent.StartOffset -eq $cursor) {
                        $tokenToChange = $nextToken
                    }
                }
                break
            }
        }

        if ($tokenToChange -ne $null) {
            $extent = $tokenToChange.Extent
            $tokenText = $extent.Text
            if ($tokenText[0] -eq '"' -and $tokenText[-1] -eq '"') {
                # Switch to no quotes
                $replacement = $tokenText.Substring(1, $tokenText.Length - 2)
            } elseif ($tokenText[0] -eq "'" -and $tokenText[-1] -eq "'") {
                # Switch to double quotes
                $replacement = '"' + $tokenText.Substring(1, $tokenText.Length - 2) + '"'
            } else {
                # Add single quotes
                $replacement = "'" + $tokenText + "'"
            }

            [Microsoft.PowerShell.PSConsoleReadLine]::Replace(
                $extent.StartOffset,
                $tokenText.Length,
                $replacement)
        }
    }
}
Set-PSReadLineKeyHandler @parameters3

# This example will replace any aliases on the command line with the resolved commands.
$parameters4 = @{
    Key              = "F7"
    BriefDescription = "Expand Aliases"
    LongDescription  = "Replace any aliases on the command line with the resolved commands"
    ScriptBlock      = {
        param($key, $arg)

        $ast = $null
        $tokens = $null
        $errors = $null
        $cursor = $null
        [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$ast, [ref]$tokens, [ref]$errors, [ref]$cursor)

        $startAdjustment = 0
        foreach ($token in $tokens) {
            if ($token.TokenFlags -band [TokenFlags]::CommandName) {
                $alias = $ExecutionContext.InvokeCommand.GetCommand($token.Extent.Text, 'Alias')
                if ($alias -ne $null) {
                    $resolvedCommand = $alias.ResolvedCommandName
                    if ($resolvedCommand -ne $null) {
                        $extent = $token.Extent
                        $length = $extent.EndOffset - $extent.StartOffset
                        [Microsoft.PowerShell.PSConsoleReadLine]::Replace(
                            $extent.StartOffset + $startAdjustment,
                            $length,
                            $resolvedCommand)

                        # Our copy of the tokens won't have been updated, so we need to
                        # adjust by the difference in length
                        $startAdjustment += ($resolvedCommand.Length - $length)
                    }
                }
            }
        }
    }
}
Set-PSReadLineKeyHandler @parameters4

# PSFzf
# ----------------------------------------------------------------
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

$commandOverride = [ScriptBlock] { param($Location) Write-Host $Location }
$PSFzfOptions = @{
    AltCCommand                   = $commandOverride
    PSReadlineChordProvider       = "Ctrl+t"
    PSReadlineChordReverseHistory = "Ctrl+r"
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
    if ($InputPath -match "^.*:\d+:.*$") {
        $InputPath = ($InputPath -split ":")[0]
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
    $RG_PREFIX = "rg --column --line-number --no-heading --color=always --smart-case"
    $InputPath = "" |
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

Set-PSReadLineKeyHandler -Key "Ctrl+f" -ScriptBlock {
    [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()
    [Microsoft.PowerShell.PSConsoleReadLine]::Insert("fdz")
    [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
}

Set-PSReadLineKeyHandler -Key "Ctrl+g" -ScriptBlock {
    [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()
    [Microsoft.PowerShell.PSConsoleReadLine]::Insert("rgz")
    [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
}
