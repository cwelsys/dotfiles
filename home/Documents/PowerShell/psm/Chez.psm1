<#
.SYNOPSIS
    PowerShell module for managing dotfiles with chezmoi.
.DESCRIPTION
    This module provides convenient functions and aliases for common chezmoi operations
    including adding files, editing configuration, committing changes.
.LINK
    https://github.com/twpayne/chezmoi
.NOTES
    Author: Connor Welsh
    Requires: chezmoi on PATH
#>

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
        Commits changes with the specified message and pushes to remote.
    .EXAMPLE
        Invoke-ChezmoiCommitAndPush
        Opens git commit editor for interactive commit message entry.
    #>
  [CmdletBinding()]
  [Alias('cmc')]
  param(
    [Parameter(Position = 0)]
    [string]$Message
  )

  if ([string]::IsNullOrEmpty($Message)) {
    chezmoi git 'commit'
  }
  else {
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
    .EXAMPLE
        Invoke-ChezmoiSaveChanges
        Re-adds all modified files and commits with fast commit or regular commit.
    #>
  [CmdletBinding()]
  [Alias('cms')]
  param()

  chezmoi re-add

  try {
    chezmoi git 'f' 2>&1
    if ($LASTEXITCODE -ne 0) {
      Write-Warning "No 'f' alias for git!"
      Invoke-ChezmoiCommitAndPush
    }
  }
  catch {
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
    .PARAMETER Arguments
        Files, directories, or patterns to add to chezmoi source state.
    .EXAMPLE
        Invoke-ChezmoiAdd ~/.bashrc
        Adds the .bashrc file to chezmoi source state.
    .EXAMPLE
        Invoke-ChezmoiAdd ~/.config/nvim/
        Adds the entire nvim configuration directory.
    #>
  [CmdletBinding()]
  [Alias('cma')]
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
    .DESCRIPTION
        Opens files from the chezmoi source state in the default editor.
    .PARAMETER Arguments
        Files to edit in the chezmoi source state.
    .EXAMPLE
        Invoke-ChezmoiEdit ~/.bashrc
        Opens the source state version of .bashrc for editing.
    #>
  [CmdletBinding()]
  [Alias('cme')]
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
    .DESCRIPTION
        Pulls the latest changes from the source and updates the target state.
    .PARAMETER Arguments
        Additional arguments to pass to chezmoi update.
    .EXAMPLE
        Invoke-ChezmoiUpdate
        Updates all managed files from the source state.
    #>
  [CmdletBinding()]
  [Alias('cmu')]
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
    .DESCRIPTION
        Re-adds files that have been modified since they were last added to chezmoi.
    .PARAMETER Arguments
        Specific files to re-add, or all modified files if none specified.
    .EXAMPLE
        Invoke-ChezmoiReAdd
        Re-adds all modified files to the source state.
    .EXAMPLE
        Invoke-ChezmoiReAdd ~/.bashrc
        Re-adds only the .bashrc file if it has been modified.
    #>
  [CmdletBinding()]
  [Alias('cmra')]
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
    .DESCRIPTION
        Applies the source state to the target state, updating managed files.
    .PARAMETER Arguments
        Additional arguments to pass to chezmoi apply.
    .EXAMPLE
        Invoke-ChezmoiApply
        Applies all pending changes from source to target state.
    .EXAMPLE
        Invoke-ChezmoiApply --dry-run
        Shows what changes would be applied without actually making them.
    #>
  [CmdletBinding()]
  [Alias('cmapl')]
  param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Arguments
  )

  chezmoi apply @Arguments
}

Export-ModuleMember -Function @(
  'Invoke-ChezmoiCommitAndPush',
  'Invoke-ChezmoiSaveChanges',
  'Invoke-ChezmoiAdd',
  'Invoke-ChezmoiEdit',
  'Invoke-ChezmoiUpdate',
  'Invoke-ChezmoiReAdd',
  'Invoke-ChezmoiApply'
) -Alias @(
  'cmc',
  'cms',
  'cma',
  'cme',
  'cmu',
  'cmra',
  'cmapl'
)
