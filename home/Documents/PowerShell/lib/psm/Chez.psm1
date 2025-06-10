function Invoke-ChezmoiCommitAndPush {
  <#
    .SYNOPSIS
        Commits changes to chezmoi repository and pushes them.
    .DESCRIPTION
        Commits changes to chezmoi repository with an optional message and pushes them.
        If no message is provided, opens the default git commit editor.
    .PARAMETER Message
        Optional commit message. If not provided, opens the default git commit editor.
    .EXAMPLE
        Invoke-ChezmoiCommitAndPush "Update dotfiles"
    .EXAMPLE
        Invoke-ChezmoiCommitAndPush
    #>
  [CmdletBinding()]
  param(
    [Parameter(Position = 0)]
    [string]$Message
  )

  if ([string]::IsNullOrEmpty($Message)) {
    chezmoi git "commit"
  } else {
    chezmoi git "commit -m `"$Message`""
  }

  if ($LASTEXITCODE -eq 0) {
    chezmoi git push
  }
}

function Invoke-ChezmoiSaveChanges {
  <#
    .SYNOPSIS
        Re-adds files to chezmoi and attempts to use git fast commit.
    .DESCRIPTION
        Updates the source state with chezmoi re-add and attempts to use
        git's "f" alias. If that fails, falls back to regular commit and push.
    #>
  [CmdletBinding()]
  param()

  chezmoi re-add

  try {
    chezmoi git "f" 2>&1
    if ($LASTEXITCODE -ne 0) {
      Write-Warning "No 'f' alias for git!"
      Invoke-ChezmoiCommitAndPush
    }
  } catch {
    Write-Warning "No 'f' alias for git!"
    Invoke-ChezmoiCommitAndPush
  }
}
function Invoke-ChezmoiAdd {
  <#
    .SYNOPSIS
        Adds files to chezmoi.
    .DESCRIPTION
        Adds the named files, directories, or glob patterns to the source state.
    .EXAMPLE
        Invoke-ChezmoiAdd ~/.bashrc
    #>
  [CmdletBinding()]
  param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Arguments
  )

  chezmoi add @Arguments
}

function Invoke-ChezmoiEdit {
  <#
    .SYNOPSIS
        Edits files in the source state.
    #>
  [CmdletBinding()]
  param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Arguments
  )

  chezmoi edit @Arguments
}

function Invoke-ChezmoiUpdate {
  <#
    .SYNOPSIS
        Updates the target state.
    #>
  [CmdletBinding()]
  param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Arguments
  )

  chezmoi update @Arguments
}

function Invoke-ChezmoiReAdd {
  <#
    .SYNOPSIS
        Re-adds modified files.
    #>
  [CmdletBinding()]
  param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Arguments
  )

  chezmoi re-add @Arguments
}

function Invoke-ChezmoiApply {
  <#
    .SYNOPSIS
        Applies changes with chezmoi.
    #>
  [CmdletBinding()]
  param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Arguments
  )
}

Set-Alias -Name 'cmu' -Value Invoke-ChezmoiUpdate -Description "Updates dotfiles with chezmoi"
Set-Alias -Name 'cme' -Value Invoke-ChezmoiEdit -Description "Edits files with chezmoi"
Set-Alias -Name 'cma' -Value Invoke-ChezmoiAdd -Description "Adds files to chezmoi"
Set-Alias -Name 'cmra' -Value Invoke-ChezmoiReAdd -Description "Re-adds files to chezmoi"
Set-Alias -Name 'cmapl' -Value Invoke-ChezmoiApply -Description "Applies changes with chezmoi"
Set-Alias -Name 'cmc' -Value Invoke-ChezmoiCommitAndPush -Description "Commit and push chezmoi changes"
Set-Alias -Name 'cms' -Value Invoke-ChezmoiSaveChanges -Description "Save chezmoi changes with fast commit"
