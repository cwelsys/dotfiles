Import-Module Catppuccin

$Flavor = $Catppuccin['Mocha']

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

# hacky workaround to make listview play nice w/ starship transient prompt
Set-PSReadLineKeyHandler -Key Enter -BriefDescription 'AcceptLineAndClear' -LongDescription 'Accept the current line and clear predictions' -ScriptBlock {
    [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
    [Console]::Write("`e[J")
}

Set-PSReadlineKeyHandler -Key UpArrow -Function HistorySearchBackward
Set-PSReadlineKeyHandler -Key DownArrow -Function HistorySearchForward
Set-PSReadlineKeyHandler -Key Tab -BriefDescription 'Invoke-FzfTabCompletion' -LongDescription 'Tab expands into a FZF modal window similar to the zsh fzf-tab plugin' -ScriptBlock { Invoke-FzfTabCompletion }

$tglquote = @{
    Key              = "Alt+'"
    BriefDescription = 'Toggle Quote Argument'
    LongDescription  = 'Toggle quotes on the argument under the cursor'
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
            }
            elseif ($tokenText[0] -eq "'" -and $tokenText[-1] -eq "'") {
                # Switch to double quotes
                $replacement = '"' + $tokenText.Substring(1, $tokenText.Length - 2) + '"'
            }
            else {
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
Set-PSReadLineKeyHandler @tglquote

$tglpred = @{
    Key              = 'F4'
    BriefDescription = 'Toggle PSReadLineOption PredictionSource'
    LongDescription  = "Toggle PSReadLineOption PredictionSource option between 'None' and 'HistoryAndPlugin'"
    ScriptBlock      = {
        # Get the current state of PredictionSource
        $state = (Get-PSReadLineOption).PredictionSource

        # Toggle between None and HistoryAndPlugin
        switch ($state) {
            'None' { Set-PSReadLineOption -PredictionSource HistoryAndPlugin }
            'History' { Set-PSReadLineOption -PredictionSource None }
            'Plugin' { Set-PSReadLineOption -PredictionSource None }
            'HistoryAndPlugin' { Set-PSReadLineOption -PredictionSource None }
            Default { Write-Host 'Current PSReadlineOption PredictionSource is Unknown' -ForegroundColor 'Cyan' }
        }

        # Trigger autocomplete to appear without changing the line
        # InvokePrompt() does not cause ListView style suggestions to disappear when toggling off
        # [Microsoft.PowerShell.PSConsole.ReadLine]::InvokePrompt()

        # Trigger autocomplete to appear or disappear while preserving the current input
        [Microsoft.PowerShell.PSConsoleReadLine]::Insert(' ')
        [Microsoft.PowerShell.PSConsoleReadLine]::BackwardDeleteChar()
    }
}
Set-PSReadLineKeyHandler @tglpred

$parens = @{
    Key              = 'Alt+('
    BriefDescription = 'Parenthesize Selection'
    LongDescription  = 'Put parenthesis around the selection or entire line and move the cursor to after the closing parenthesis'
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
        }
        else {
            [Microsoft.PowerShell.PSConsoleReadLine]::Replace(0, $line.Length, '(' + $line + ')')
            [Microsoft.PowerShell.PSConsoleReadLine]::EndOfLine()
        }
    }
}
Set-PSReadLineKeyHandler @parens


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

Set-PSReadLineKeyHandler -Key 'Ctrl+f' -BriefDescription 'Invoke-FuzzyFileFinder' -LongDescription 'Launch fuzzy file finder using fd and fzf' -ScriptBlock {
    [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()
    [Microsoft.PowerShell.PSConsoleReadLine]::Insert('fdz')
    [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
}

Set-PSReadLineKeyHandler -Key 'Ctrl+g' -BriefDescription 'Invoke-FuzzyRipGrep' -LongDescription 'Launch fuzzy text search using ripgrep and fzf' -ScriptBlock {
    [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()
    [Microsoft.PowerShell.PSConsoleReadLine]::Insert('rgz')
    [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
}
