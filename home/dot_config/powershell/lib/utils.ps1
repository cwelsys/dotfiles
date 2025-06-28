$Env:DOTS = & chezmoi source-path

Remove-Item Alias:rm -Force -ErrorAction SilentlyContinue

Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t' -PSReadlineChordReverseHistory 'Ctrl+r'

Set-Alias sarc Invoke-Sarcastaball
Set-Alias npm-ls Get-NpmGlobalPackages
Set-Alias bun-ls Get-BunGlobalPackages
Set-Alias pnpm-ls Get-PnpmGlobalPackages
Set-Alias md5 Get-FileHashMD5
Set-Alias sha1 Get-FileHashSHA1
Set-Alias sha256 Get-FileHashSHA256
Set-Alias GET Invoke-RestMethodGet
Set-Alias HEAD Invoke-RestMethodHead
Set-Alias POST Invoke-RestMethodPost
Set-Alias PUT Invoke-RestMethodPut
Set-Alias DELETE Invoke-RestMethodDelete
Set-Alias TRACE Invoke-RestMethodTrace
Set-Alias OPTIONS Invoke-RestMethodOptions

function dots { Set-Location $Env:DOTS }
function qq { exit }
function cdcm { Set-Location $Env:DOTS }
function cdc { Set-Location $env:XDG_CONFIG_HOME }

if ($IsWindows) {
  function lock { Invoke-Command { rundll32.exe user32.dll, LockWorkStation } }
  function hibernate { shutdown.exe /h }
  function shutdown { Stop-Computer }
  function reboot { Restart-Computer }
  function HKLM { Set-Location HKLM: }
  function HKCU { Set-Location HKCU: }
  function fdns { ipconfig /flushdns }
  function rdns { ipconfig /release }
  function ddns { ipconfig /displaydns }
  function getnf { Invoke-NerdFontInstaller }
  function export($name, $value) {
    Set-Item -Path "env:$name" -Value $value
  }
  function Invoke-Bat {
    [Alias('cat')]
    param([Parameter(ValueFromRemainingArguments = $true)]$args)
    & (Get-Command bat).Source --paging=never --style=plain @args
  }

  Set-Alias deltemp Remove-TempData

  function komorel {
    komorebic stop --whkd | Out-Null
    komorebic start --whkd | Out-Null
    yasbc reload | Out-Null
  }

}
function envs { Get-ChildItem Env: }
function paths { $env:PATH -Split ';' }
function e { Invoke-Item . }
function sysinfo { if (Get-Command fastfetch -ErrorAction SilentlyContinue) { fastfetch -c all } else { Get-ComputerInfo } }
function profiles { Get-PSProfile { $_.exists -eq 'True' } | Format-List }
function rst { Get-Process -Id $PID | Select-Object -ExpandProperty Path | ForEach-Object { Invoke-Command { & "$_" } -NoNewScope } }

function Get-NpmGlobalPackages { (npm ls -g | Select-Object -skip 1).Trim().Split() | ForEach-Object { if ($_ -match [regex]::Escape('@')) { Write-Output $_ } } }
function Get-BunGlobalPackages { (bun pm ls -g | Select-Object -Skip 1).Trim().Split() | ForEach-Object { if ($_ -match [regex]::Escape('@')) { Write-Output $_ } } }
function Get-PnpmGlobalPackages { (pnpm ls -g | Select-Object -Skip 5) | ForEach-Object { $name = $_.Split()[0]; $version = $_.Split()[1]; Write-Output "$name@$version" } }
function cmpack {
  [CmdletBinding(DefaultParameterSetName = 'Args')]
  param(
    [Parameter(ValueFromRemainingArguments = $true)]
    $Args
  )
  $scriptPath = Join-Path $env:XDG_BIN_HOME 'update-manifest.ps1'
  if (Test-Path $scriptPath) {
    & $scriptPath @Args
  }
  else {
    Write-Error "Script not found: $scriptPath"
  }
}
function y {
  $tmp = [System.IO.Path]::GetTempFileName()
  yazi $args --cwd-file="$tmp"
  $cwd = Get-Content -Path $tmp -Encoding UTF8
  if (-not [String]::IsNullOrEmpty($cwd) -and $cwd -ne $PWD.Path) {
    Set-Location -LiteralPath ([System.IO.Path]::GetFullPath($cwd))
  }
  Remove-Item -Path $tmp
}

function fortune {
  [System.IO.File]::ReadAllText("$Env:PWSH\lib\Assets\fortune.txt") -replace "`r`n", "`n" -split "`n%`n" | Get-Random
}

function cfortune {
  [CmdletBinding()]
  param()

  $fortuneText = fortune
  $fortuneText | cowsay
}

function Get-PSProfile {
  $PROFILE.PSExtended.PSObject.Properties |
  Select-Object Name, Value, @{Name = 'IsExist'; Expression = { Test-Path -Path $_.Value -PathType Leaf } }
}


function Remove-TempData {
  Write-Color 'Deleting temp data...' -Color Gray

  $path1 = 'C' + ':\Windows\Temp'
  Get-ChildItem $path1 -Force -Recurse -ErrorAction SilentlyContinue | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue

  $path2 = 'C' + ':\Windows\Prefetch'
  Get-ChildItem $path2 -Force -Recurse -ErrorAction SilentlyContinue | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue

  $path3 = 'C' + ':\Users\*\AppData\Local\Temp'
  Get-ChildItem $path3 -Force -Recurse -ErrorAction SilentlyContinue | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue

  Write-Color 'Temp data deleted successfully.' -Color Green
}

function Import-Profile {
  [Alias('rl')]
  param()

  if (Test-Path -Path $PROFILE) { . $PROFILE }
  elseif (Test-Path -Path $PROFILE.CurrentUserAllHosts) { . $PROFILE.CurrentUserAllHosts }
}

function Invoke-Sarcastaball {
  [cmdletbinding()]
  param(
    [Parameter(HelpMessage = 'provide string' , Mandatory = $true)]
    [string]$Message
  )
  $charArray = $Message.ToCharArray()

  foreach ($char in $charArray) {
    $Var = $(Get-Random) % 2
    if ($var -eq 0) {
      $string = $char.ToString()
      $Upper = $string.ToUpper()
      $output = $output + $Upper
    }
    else {
      $lower = $char.ToString()
      $output = $output + $lower
    }
  }
  $output
  $output = $null
}

function Invoke-RestMethodGet {
  <#
    .SYNOPSIS
        Sends a GET http request.
    .INPUTS
        System.Object
    .OUTPUTS
        System.Object
    .LINK
        Invoke-RestMethod
    #>
  Invoke-RestMethod -Method GET @args
}

function Invoke-RestMethodHead {
  <#
    .SYNOPSIS
        Sends a HEAD http request.
    .INPUTS
        System.Object
    .OUTPUTS
        System.Object
    .LINK
        Invoke-RestMethod
    #>
  Invoke-RestMethod -Method HEAD @args
}

function Invoke-RestMethodPost {
  <#
    .SYNOPSIS
        Sends a POST http request.
    .INPUTS
        System.Object
    .OUTPUTS
        System.Object
    .LINK
        Invoke-RestMethod
    #>
  Invoke-RestMethod -Method POST @args
}

function Invoke-RestMethodPut {
  <#
    .SYNOPSIS
        Sends a PUT http request.
    .INPUTS
        System.Object
    .OUTPUTS
        System.Object
    .LINK
        Invoke-RestMethod
    #>
  Invoke-RestMethod -Method PUT @args
}

function Invoke-RestMethodDelete {
  <#
    .SYNOPSIS
        Sends a DELETE http request.
    .INPUTS
        System.Object
    .OUTPUTS
        System.Object
    .LINK
        Invoke-RestMethod
    #>
  Invoke-RestMethod -Method DELETE @args
}

function Invoke-RestMethodTrace {
  <#
    .SYNOPSIS
        Sends a TRACE http request.
    .INPUTS
        System.Object
    .OUTPUTS
        System.Object
    .LINK
        Invoke-RestMethod
    #>
  Invoke-RestMethod -Method TRACE @args
}

function Invoke-RestMethodOptions {
  <#
    .SYNOPSIS
        Sends an OPTIONS http request.
    .INPUTS
        System.Object
    .OUTPUTS
        System.Int64
        System.String
        System.Xml.XmlDocument
        PSObject
    .LINK
        Invoke-RestMethod
    #>
  Invoke-RestMethod -Method OPTIONS @args
}

function Get-FileHashMD5 {
  <#
    .SYNOPSIS
        Calculates the MD5 hash of an input.
    .PARAMETER Path
        Path to calculate hashes from.
    .EXAMPLE
        Get-FileHashMD5 file
    .EXAMPLE
        Get-FileHashMD5 file1,file2
    .EXAMPLE
        Get-FileHashMD5 *.gz
    .INPUTS
        System.String[]
    .OUTPUTS
        Microsoft.PowerShell.Commands.FileHashInfo
    .LINK
        Get-FileHash
    #>
  [CmdletBinding()]
  param(
    [Parameter(
      Mandatory = $true,
      Position = 0,
      ValueFromPipeline = $true
    )]
    [string]$Path
  )
  Get-FileHash $Path -Algorithm MD5
}

function Get-FileHashSHA1 {
  <#
    .SYNOPSIS
        Calculates the SHA1 hash of an input.
    .PARAMETER Path
        File(s) to calculate hashes from.
    .EXAMPLE
        Get-FileHashSHA1 file
    .EXAMPLE
        Get-FileHashSHA1 file1,file2
    .EXAMPLE
        Get-FileHashSHA1 *.gz
    .INPUTS
        System.String[]
    .OUTPUTS
        Microsoft.PowerShell.Commands.FileHashInfo
    .LINK
        Get-FileHash
    #>
  [CmdletBinding()]
  param(
    [Parameter(
      Mandatory = $true,
      Position = 0,
      ValueFromPipeline = $true
    )]
    [string]$Path
  )
  Get-FileHash $Path -Algorithm SHA1
}

function Get-FileHashSHA256 {
  <#
    .SYNOPSIS
        Calculates the SHA256 hash of an input.
    .PARAMETER Path
        File(s) to calculate hashes from.
    .EXAMPLE
        Get-FileHashSHA256 file
    .EXAMPLE
        Get-FileHashSHA256 file1,file2
    .EXAMPLE
        Get-FileHashSHA256 *.gz
    .INPUTS
        System.String[]
    .OUTPUTS
        Microsoft.PowerShell.Commands.FileHashInfo
    .LINK
        Get-FileHash
    #>
  [CmdletBinding()]
  param(
    [Parameter(
      Mandatory = $true,
      Position = 0,
      ValueFromPipeline = $true
    )]
    [string]$Path
  )
  Get-FileHash $Path -Algorithm SHA256
}

function Invoke-ChezmoiCommitAndPush {
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
  [CmdletBinding()]
  [Alias('cma')]
  param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Arguments
  )

  chezmoi add @Arguments
}

function Invoke-ChezmoiEdit {
  [CmdletBinding()]
  [Alias('cme')]
  param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Arguments
  )

  chezmoi edit @Arguments
}

function Invoke-ChezmoiUpdate {
  [CmdletBinding()]
  [Alias('cmu')]
  param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Arguments
  )

  chezmoi update @Arguments
}

function Invoke-ChezmoiReAdd {
  [CmdletBinding()]
  [Alias('cmra')]
  param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Arguments
  )

  chezmoi re-add @Arguments
}

function Invoke-ChezmoiApply {
  [CmdletBinding()]
  [Alias('cmapl')]
  param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Arguments
  )

  chezmoi apply @Arguments
}

function split {
  param
  (
    [Parameter(ValueFromPipeline)]
    [string[]]$InputObject,

    [Parameter(Mandatory, Position = 0, ValueFromRemainingArguments)]
    [ValidateCount(1, 3)]
    [string[]]$args
  )

  end {
    $input -split $args
  }
}

function join {
  param
  (
    [Parameter(ValueFromPipeline)]
    [string[]]$InputObject,

    [Parameter(Mandatory, Position = 0, ValueFromRemainingArguments)]
    [ValidateCount(1, 3)]
    [AllowEmptyString()]
    [string[]]$args
  )

  end {
    $input -join $args
  }
}

function replace {
  param
  (
    [Parameter(ValueFromPipeline)]
    [string[]]$InputObject,

    [Parameter(Mandatory, Position = 0)]
    [ValidateCount(1, 2)]
    [AllowEmptyString()]
    [string[]]$args
  )

  end {
    $input -replace $args
  }
}

function match {
  param
  (
    [Parameter(ValueFromPipeline)]
    [string[]]$InputObject,

    [Parameter(Mandatory, Position = 0)]
    [string]$Pattern
  )

  end {
    $input -match $Pattern
  }
}

function notmatch {
  param
  (
    [Parameter(ValueFromPipeline)]
    [string[]]$InputObject,

    [Parameter(Mandatory, Position = 0)]
    [string]$Pattern
  )

  end {
    $input -notmatch $Pattern
  }
}


function Switch-Order {
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory, ValueFromPipeline)]
    [object]$InputObject
  )

  end {
    [Array]::Reverse($input)
    $input
  }
}
Set-Alias reverse Switch-Order


function Split-Line {
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory, ValueFromPipeline)]
    [object]$InputObject,

    [switch]$SkipEmpty,

    [switch]$SkipEmptyOrWhitespace
  )

  process {
    $EolPattern = '\r?\n'
    $Lines = $InputObject -split $EolPattern

    if ($SkipWhitespace) {
      $Lines = $Lines | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
    }
    elseif ($SkipEmpty) {
      $Lines = $Lines | Where-Object { -not [string]::IsNullOrEmpty($_) }
    }

    $Lines | Write-Output
  }
}

function Trim-String {
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory, ValueFromPipeline)]
    [object]$InputObject,

    [switch]$Stream
  )

  if ($MyInvocation.ExpectingInput) {
    $InputObject = $input
  }
  $InputObject | Out-String -Stream:$Stream | ForEach-Object { $_.Trim() }
}
Set-Alias trim Trim-String

function Split-Batch {
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory, ValueFromPipeline)]
    [object]$InputObject,

    [Parameter(Mandatory, Position = 1)]
    [ValidateRange(2, 2147483647)]
    [int]$BatchSize
  )

  $Enumerator = $input.GetEnumerator()

  while ($true) {
    $Batch = 1..$BatchSize | ? { $Enumerator.MoveNext() } | % { $Enumerator.Current }
    if (-not $Batch) { break }

    $PSCmdlet.WriteObject($Batch)
  }
}
Set-Alias batch Split-Batch


function ConvertTo-ListExpression {
  [CmdletBinding(DefaultParameterSetName = 'Default')]
  param
  (
    [Parameter(Mandatory, ValueFromPipeline)]
    [object]$InputObject,

    [Parameter(ParameterSetName = 'Default')]
    [switch]$Singleline,

    [Parameter(ParameterSetName = 'Default')]
    [switch]$DoubleQuote,

    [Parameter(ParameterSetName = 'Explicit')]
    [ValidatePattern("(?s)^(['`"]).*\1$")]      # First char is a quotemark, last char is same as first
    [string]$Join = "',$([Environment]::NewLine)'"
  )

  if ($MyInvocation.ExpectingInput) {
    $InputObject = $input
  }

  if ($DoubleQuote) {
    $Join = $Join -replace '(^.)|(.$)', '"'
  }

  if ($Singleline) {
    $Join = $Join -replace '\r?\n', ' '
  }

  $Quotemark = $Join[0]

  $Items = $InputObject | Split-Line -SkipEmptyOrWhitespace

  "$Quotemark$($Items -join $Join)$Quotemark"
}


function Get-EnumValues {
  [CmdletBinding(DefaultParameterSetName = 'ByType')]
  param
  (
    [Parameter(ParameterSetName = 'ByType', Mandatory, Position = 0, ValueFromPipeline)]
    [ValidateScript({ $_.IsEnum })]
    [type]$Enum,

    [Parameter(ParameterSetName = 'FromInstance', Mandatory, Position = 0, ValueFromPipeline)]
    [enum]$InputObject
  )

  process {
    if ($PSCmdlet.ParameterSetName -eq 'FromInstance') { $Enum = $InputObject.GetType() }

    [Enum]::GetValues($Enum) | ForEach-Object {
      [pscustomobject]@{
        Value = $_.value__
        Name  = [string]$_
      }
    }
  }
}
Set-Alias enumvals Get-EnumValues

function ConvertFrom-Base64 {
  [CmdletBinding()]
  param
  (
    [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
    [string]$Base64
  )

  process {
    [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($Base64))
  }
}

function ConvertTo-Base64 {
  [CmdletBinding()]
  param
  (
    [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
    [string]$String
  )

  process {
    [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($String))
  }
}

function Copy-SshKey {
  [CmdletBinding(DefaultParameterSetName = 'ByFilter')]
  param
  (
    [Parameter(Mandatory, ValueFromPipeline, Position = 0)]
    [ValidateNotNullOrEmpty()]
    [string[]]$Hostname,

    [Parameter(Mandatory, ParameterSetName = 'ByPath', Position = 1)]
    [ArgumentCompleter({ Get-ChildItem ~/.ssh -File -Filter '*.pub' })]
    [string[]]$KeyFile,

    [Parameter(ParameterSetName = 'ByFilter', Position = 1)]
    [string]$Filter = $([regex]::Escape($env:USER)),

    [string]$Username,

    [switch]$IncludePrivateKey
  )

  begin {
    if (-not $KeyFile) {
      $KeyFile = (Get-Content ~/.ssh/config) -imatch 'IdentityFile' -ireplace '.*IdentityFile ' -imatch $Filter
    }

    $KeyFile = $KeyFile -replace '\.pub$'

    if ($IncludePrivateKey) {
      $KeyFile = $KeyFile | ForEach-Object { $_; "$_.pub" } | Write-Output
    }
    else {
      $KeyFile = $KeyFile -replace '$', '.pub'
    }
  }

  process {
    $Hostname | ForEach-Object {
      $User = if ($Username) {
        $Username
      }
      else {
        $UserConfig = ssh -G $Hostname | Select-String '^user (?<User>.*)'
        if ($UserConfig) {
          $UserConfig.Matches.Groups[-1].Value
        }
        else {
          $env:USER
        }
      }

      $UserHome = if ($User -eq 'root') { '/root' } else { "/home/$User" }
      $Dest = "$User@$_`:$UserHome/.ssh"

      scp -r $KeyFile $Dest
    }
  }
}
$PSDefaultParameterValues['Copy-SshKey:KeyFile'] = '~/.ssh/freddie_home', '~/.ssh/freddie_git'

function Copy-Terminfo {
  <#
        .DESCRIPTION
        When using kitty and SSHing to pwsh, the console can be garbled. This is caused by TERM
        being set to 'xterm-kitty' on the remote host, but kitty not having a terminfo entry. This
        can be worked around with `$env:TERM = 'xterm-256color'; ssh <host>`, but the actual fix
        is to copy over the kitty declaration to the remote host.
    #>
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory, ValueFromPipeline)]
    [ValidateNotNullOrEmpty()]
    [string[]]$Hostname,

    [string]$Username,

    [switch]$Force
  )

  begin {
    if ($env:TERM -ne 'xterm-kitty' -and -not $Force) {
      Write-Warning "TERM is not 'xterm-kitty'; use -Force to override"
      return
    }
    $Src = Resolve-Path $HOME/.terminfo
  }

  process {
    $Hostname | ForEach-Object {
      $User = if ($Username) {
        $Username
      }
      else {
        $UserConfig = ssh -G $Hostname | Select-String '^user (?<User>.*)'
        if ($UserConfig) {
          $UserConfig.Matches.Groups[-1].Value
        }
        else {
          $env:USER
        }
      }

      $UserHome = if ($User -eq 'root') { '/root' } else { "/home/$User" }
      $Dest = "$User@$_`:$UserHome"

      scp -r $Src $Dest
    }
  }
}


function Forget-KnownHost {
  [CmdletBinding()]
  param
  (
    [string]$Path = '~/.ssh/known_hosts',

    [Parameter(Mandatory, Position = 0)]
    [ArgumentCompleter({
        param ($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
        $Path = $fakeBoundParameters.Path
        if (-not $Path) { $Path = '~/.ssh/known_hosts' }
        $Hosts = @(Get-Content $Path) -replace '\s.*' -split ',' | sort -Unique
        @($Hosts) -like "$wordToComplete*"
      })]
    [ValidateNotNullOrEmpty()]
    [SupportsWildcards()]
    [string]$Hostname,

    [switch]$Check
  )

  $Content = gc $Path -ErrorAction Stop
  $Content = $Content | ? {
    $Hosts = $_ -replace '\s.*' -split ',' | sort -Unique
    # $Hosts | Write-Host
    $IsMatch = [bool]($Hosts -like $Hostname)
    -not $IsMatch -xor $Check
  }

  if ($Check) {
    $Content
  }
  else {
    $Content > $Path
  }
}

function Read-Journal {
  [CmdletBinding()]
  param
  (
    [string]$Unit,

    [ValidateRange(1, [int]::MaxValue)]
    [int]$Count,

    [ValidateSet('short', 'short-precise', 'short-iso', 'short-iso-precise', 'short-full', 'short-monotonic', 'short-unix', 'verbose', 'export', 'json', 'json-pretty', 'json-sse', 'json-seq', 'cat', 'with-unit')]
    [string]$Format,

    # generate with: journalctl --fields
    [ValidateSet('CODE_LINE', '_COMM', 'INITRD_USEC', '_AUDIT_ID', 'DISK_AVAILABLE', 'OPERATION', 'UNIT', '_AUDIT_FIELD_SUCCESS', 'PRIORITY', 'SYSLOG_FACILITY', '_UID', '_AUDIT_TYPE', '_AUDIT_FIELD_SCONTEXT', 'TID', 'JOB_TYPE', '_AUDIT_FIELD_TABLE', 'LEADER', 'AUDIT_FIELD_DEFAULT_CONTEXT', 'NM_LOG_DOMAINS', 'DISK_KEEP_FREE', 'JOB_RESULT', '_TTY', 'REF', 'INVOCATION_ID', '_SYSTEMD_USER_UNIT', 'AUDIT_FIELD_NEW_LEVEL', 'AUDIT_FIELD_UNIT', '_AUDIT_FIELD_A1', 'SEAT_ID', 'AUDIT_FIELD_HOSTNAME', 'JOURNAL_NAME', '_UDEV_DEVNODE', '_AUDIT_FIELD_TCONTEXT', 'CODE_FILE', '_SYSTEMD_SLICE', 'AVAILABLE_PRETTY', '_FSUID', '_AUDIT_FIELD_ENTRIES', '_SOURCE_MONOTONIC_TIMESTAMP', 'SESSION_ID', '_EXE', 'AVAILABLE', '_AUDIT_FIELD_INO', '_AUDIT_FIELD_AUDIT_ENABLED', '_AUDIT_FIELD_PERMISSIVE', 'AUDIT_FIELD_ACCT', 'CURRENT_USE', '_AUDIT_FIELD_FAMILY', '_SYSTEMD_USER_SLICE', 'CURRENT_USE_PRETTY', '_AUDIT_SESSION', 'INSTALLATION', '_STREAM_ID', 'MESSAGE_ID', 'DBUS_BROKER_LOG_DROPPED', '_MACHINE_ID', 'AUDIT_FIELD_OLD_LEVEL', 'USER_UNIT', '_AUDIT_FIELD_SGID', 'THREAD_ID', '_AUDIT_FIELD_TCLASS', '_AUDIT_FIELD_SYSCALL', '_CMDLINE', 'DISK_AVAILABLE_PRETTY', '_RUNTIME_SCOPE', 'LIMIT_PRETTY', 'SYSLOG_PID', '_AUDIT_FIELD_AUDIT_PID', '_AUDIT_FIELD_SUID', '_FSGID', 'CONFIG_FILE', '_AUDIT_TYPE_NAME', 'GLIB_DOMAIN', '_SYSTEMD_OWNER_UID', 'CODE_FUNC', '_AUDIT_FIELD_ARCH', '_SYSTEMD_SESSION', 'USER_ID', '_GID', 'KERNEL_USEC', '_AUDIT_FIELD_NAME', 'AUDIT_FIELD_COMM', 'REALMD_OPERATION', 'REMOTE', '_PID', 'LIMIT', 'ERRNO', '_AUDIT_FIELD_KEY', 'OBJECT_PID', '_EGID', '_KERNEL_DEVICE', '_UDEV_SYSNAME', 'OLD_COMMIT', '_SYSTEMD_UNIT', '_AUDIT_FIELD_PROG_ID', 'MEMORY_SWAP_PEAK', 'COMMIT', 'FLATPAK_VERSION', 'INTERFACE', '_AUDIT_LOGINUID', 'MAX_USE', '_KERNEL_SUBSYSTEM', '_AUDIT_FIELD_RES', '_PPID', '_CAP_EFFECTIVE', '_SELINUX_CONTEXT', 'AUDIT_FIELD_ADDR', 'TIMESTAMP_BOOTTIME', 'JOB_ID', 'AUDIT_FIELD_TERMINAL', '_AUDIT_FIELD_OLD', '_AUDIT_FIELD_A2', 'USER_INVOCATION_ID', '_TRANSPORT', '_AUDIT_FIELD_OP', 'AUDIT_FIELD_EXE', 'JOURNAL_PATH', 'TAINT', 'TIMESTAMP_MONOTONIC', 'MESSAGE', '_SYSTEMD_INVOCATION_ID', '_AUDIT_FIELD_A3', 'CONFIG_LINE', '_AUDIT_FIELD_EXIT', '_AUDIT_FIELD_DEV', '_EUID', 'MEMORY_PEAK', 'NM_DEVICE', 'AUDIT_FIELD_GRANTORS', 'SYSLOG_IDENTIFIER', '_AUDIT_FIELD_ITEMS', '_SOURCE_REALTIME_TIMESTAMP', 'SYSLOG_TIMESTAMP', '_HOSTNAME', 'AUDIT_FIELD_RES', 'AUDIT_FIELD_OP', 'DISK_KEEP_FREE_PRETTY', '_BOOT_ID', '_AUDIT_FIELD_A0', 'SYSLOG_RAW', 'GLIB_OLD_LOG_API', 'USERSPACE_USEC', '_SYSTEMD_CGROUP', 'CPU_USAGE_NSEC', 'URL', 'MAX_USE_PRETTY', 'NM_LOG_LEVEL', 'DBUS_BROKER_METRICS_DISPATCH_MIN', 'OBJECT_SYSTEMD_SLICE', 'OBJECT_SYSTEMD_USER_UNIT', 'TOPIC', 'SRC', 'DBUS_BROKER_METRICS_DISPATCH_STDDEV', 'DBUS_BROKER_SENDER_SECURITY_LABEL', 'CHECKSUM_ALGORITHM', 'SETYPE', 'DEST', 'DBUS_BROKER_LAUNCH_SERVICE_UNIT', 'OBJECT_AUDIT_SESSION', 'DBUS_BROKER_MESSAGE_MEMBER', 'AUDIT_FIELD_GPG_RES', 'SEUSER', 'DBUS_BROKER_SENDER_WELL_KNOWN_NAME_0', 'GATHER_TIMEOUT', 'SHUTDOWN', 'AUDIT_FIELD_ROOT_DIR', 'PATH', 'DBUS_BROKER_METRICS_DISPATCH_COUNT', 'OBJECT_SYSTEMD_USER_SLICE', 'DBUS_BROKER_MESSAGE_INTERFACE', 'AUDIT_FIELD_KEY_ENFORCE', 'SSSD_PRG_NAME', 'DBUS_BROKER_POLICY_TYPE', 'NM_CONNECTION', 'RECURSE', 'GATHER_SUBSET', 'DBUS_BROKER_LAUNCH_SERVICE_ID', 'AUDIT_FIELD_CIPHER', 'SCOPE', 'DBUS_BROKER_MESSAGE_SERIAL', 'OBJECT_SELINUX_CONTEXT', 'GET_CHECKSUM', 'AUDIT_FIELD_SW_TYPE', 'DBUS_BROKER_TRANSMIT_ACTION', 'DBUS_BROKER_LAUNCH_SERVICE_NAME', 'STATE', 'FILTER', 'OBJECT_UID', 'DBUS_BROKER_LAUNCH_BUS_ERROR_MESSAGE', 'GET_MIME', 'DBUS_BROKER_LAUNCH_ARG0', 'DBUS_BROKER_MESSAGE_TYPE', 'DBUS_BROKER_MESSAGE_UNIX_FDS', 'DBUS_BROKER_LAUNCH_SERVICE_USER', 'MODE', 'SSSD_DOMAIN', 'ACCESS_TIME', 'AUDIT_FIELD_SW', 'AUDIT_FIELD_CWD', 'DBUS_BROKER_SENDER_UNIQUE_NAME', 'AUDIT_FIELD_KIND', 'OBJECT_GID', 'DBUS_BROKER_MESSAGE_PATH', 'OBJECT_AUDIT_LOGINUID', 'SEROLE', 'DBUS_BROKER_METRICS_DISPATCH_MAX', 'MODIFICATION_TIME_FORMAT', 'ACTION', 'DBUS_BROKER_LAUNCH_SERVICE_UID', 'AUDIT_FIELD_KSIZE', 'AUDIT_FIELD_MAC', 'OPERATOR', 'DBUS_BROKER_LAUNCH_SERVICE_PATH', 'AUDIT_FIELD_LADDR', 'AUDIT_FIELD_FP', 'AUDIT_FIELD_PFS', '_LINE_BREAK', 'DBUS_BROKER_MESSAGE_SIGNATURE', 'FACT_PATH', 'DAEMON_REEXEC', 'SELEVEL', 'DBUS_BROKER_LAUNCH_SERVICE_INSTANCE', 'ENABLED', 'AUDIT_FIELD_LPORT', 'FORCE', 'ACCESS_TIME_FORMAT', 'OWNER', 'DBUS_BROKER_RECEIVER_SECURITY_LABEL', 'UNSAFE_WRITES', 'DBUS_BROKER_METRICS_DISPATCH_AVG', 'AUDIT_FIELD_CMD', 'MODIFICATION_TIME', 'AUDIT_FIELD_ID', 'OBJECT_CMDLINE', 'MODULE', 'MASKED', 'AUDIT_FIELD_SUID', 'OBJECT_SYSTEMD_UNIT', 'GROUP', 'DBUS_BROKER_LAUNCH_BUS_ERROR_NAME', 'OBJECT_SYSTEMD_OWNER_UID', 'AUDIT_FIELD_DIRECTION', 'NO_BLOCK', 'GET_ATTRIBUTES', 'DAEMON_RELOAD', 'AUDIT_FIELD_SPID', 'ATTRIBUTES', 'OBJECT_SYSTEMD_INVOCATION_ID', 'OBJECT_EXE', 'FOLLOW', 'DBUS_BROKER_RECEIVER_UNIQUE_NAME', '_AUDIT_FIELD_CAPABILITY', 'AUDIT_FIELD_RPORT', 'OBJECT_SYSTEMD_CGROUP', 'DBUS_BROKER_MESSAGE_DESTINATION', 'OBJECT_COMM', 'OBJECT_CAP_EFFECTIVE', 'NAME', 'BUGFIX', 'BACKUP', 'THROTTLE', 'STRIP_EMPTY_ENDS', 'INSTALLROOT', 'IP_RESOLVE', 'ENABLE_PLUGIN', 'CREATES', 'DISABLE_PLUGIN', 'SKIP_BROKEN', 'CACHEONLY', 'PROTECT', 'ALLOW_DOWNGRADE', 'GPGCHECK', 'FAILOVERMETHOD', 'EXECUTABLE', 'UI_REPOID_VARS', 'DIRECTORY_MODE', 'ALLOWERASING', 'ENABLEGROUPS', 'INCLUDE', 'PASSWORD', 'AUTOREMOVE', 'VALIDATE', 'FILE', 'PROXY', 'S3_ENABLED', 'AUTO_INSTALL_MODULE_DEPS', 'HTTP_CACHING', 'INSERTBEFORE', 'INSTALL_WEAK_DEPS', 'ASYNC', 'REMOTE_SRC', 'FINGERPRINT', 'INSTALL_REPOQUERY', 'NOBEST', 'CREATE', 'DISABLEREPO', 'SECURITY', 'RETRIES', 'KEEPALIVE', 'VALIDATE_CERTS', 'INSERTAFTER', 'GPGKEY', 'CHDIR', 'CHECKSUM', 'REMOVES', 'SKIP_IF_UNAVAILABLE', 'SSLCLIENTCERT', 'TIMEOUT', 'CONTENT', 'METALINK', 'KEY', 'REPO_GPGCHECK', 'STDIN_ADD_NEWLINE', 'PROXY_PASSWORD', 'BASEURL', 'SSLVERIFY', 'LINE', 'DELTARPM_METADATA_PERCENTAGE', 'DESCRIPTION', 'GPGCAKEY', 'SSL_CHECK_CERT_PERMISSIONS', 'LOCAL_FOLLOW', 'MIRRORLIST', 'ARGV', 'BANDWIDTH', 'MIRRORLIST_EXPIRE', 'SSLCACERT', 'PROXY_USERNAME', 'REPOSDIR', 'ENABLEREPO', 'LIST', 'DOWNLOAD_ONLY', 'EXPAND_ARGUMENT_VARS', 'MODULE_HOTFIXES', 'LOCK_TIMEOUT', 'COST', 'DELTARPM_PERCENTAGE', 'USERNAME', 'METADATA_EXPIRE_FILTER', 'SSLCLIENTKEY', 'REGEXP', 'DISABLE_GPG_CHECK', 'DOWNLOAD_DIR', 'UPDATE_ONLY', 'INCLUDEPKGS', 'DISABLE_EXCLUDES', 'FIRSTMATCH', 'CONF_FILE', 'UPDATE_CACHE', 'SEARCH_STRING', 'EXCLUDE', 'BACKREFS', 'RELEASEVER', 'KEEPCACHE', 'STDIN', 'METADATA_EXPIRE', 'SSH_KEY_COMMENT', 'PASSWORD_LOCK', 'UPDATE_PASSWORD', 'PROFILE', 'GROUPS', 'AUTHORIZATION', 'SKELETON', 'EXPIRES', 'HIDDEN', 'PASSWORD_EXPIRE_MIN', 'SSH_KEY_FILE', 'COMMENT', 'AUDIT_FIELD_GRP', 'MOVE_HOME', 'CREATE_HOME', 'PASSWORD_EXPIRE_WARN', 'SSH_KEY_BITS', 'UID', 'HOME', 'PASSWORD_EXPIRE_MAX', 'GENERATE_SSH_KEY', 'SSH_KEY_PASSPHRASE', 'UMASK', 'APPEND', 'ROLE', 'REMOVE', 'NON_UNIQUE', 'SHELL', 'LOCAL', 'SSH_KEY_TYPE', 'SYSTEM', 'LOGIN_CLASS', 'CONTAINS', 'AGE_STAMP', 'READ_WHOLE_FILE', 'DEPTH', 'FILE_TYPE', 'PATHS', 'PATTERNS', 'USE_REGEX', 'EXACT_MODE', 'AGE', 'EXCLUDES', 'SIZE', 'IO_BUFFER_SIZE', 'DECOMPRESS', 'CLIENT_CERT', 'CIPHERS', 'METHOD', 'HEADERS', 'OSTREE_REMOTE', 'COPY', 'URL_PASSWORD', 'HTTP_AGENT', 'URL_USERNAME', 'USE_PROXY', 'USE_GSSAPI', 'DECRYPT', 'UNREDIRECTED_HEADERS', 'EXTRA_OPTS', 'OSTREE_GPG', 'KEEP_NEWER', 'USE_NETRC', 'LIST_FILES', 'NO_DEPENDENCIES', 'CLIENT_KEY', 'TMP_DEST', 'FORCE_BASIC_AUTH', 'OSTREE_SIGN', 'OSTREE_SECONDS', 'OSTREE_XFER_SIZE', 'AUDIT_FIELD_LSM', 'XMLSTRING', 'INPUT_TYPE', 'NAMESPACES', 'AUDIT_FIELD_SEQNO', 'ATTRIBUTE', 'AUDIT_FIELD_SAUID', 'PRINT_MATCH', 'VALUE', 'STRIP_CDATA_TAGS', 'ADD_CHILDREN', '_AUDIT_FIELD_LSM', 'XPATH', 'PRETTY_PRINT', 'COUNT', 'SET_CHILDREN', 'AUDIT_FIELD_TGLOB', '_AUDIT_FIELD_LIST', 'AUDIT_FIELD_FTYPE', 'AUDIT_FIELD_RESRC', 'AUDIT_FIELD_TCONTEXT', 'PROBLEM_COUNT', 'PROBLEM_BINARY', 'PROBLEM_UUID', 'PROBLEM_CRASH_FUNCTION', '_UDEV_DEVLINK', 'PROBLEM_DIR', 'UNIT_RESULT', 'PROBLEM_PID', 'DEVICE', 'PROBLEM_REASON', '_AUDIT_FIELD_SADDR', 'PROBLEM_REPORT', '_AUDIT_FIELD_SIG', 'SLEEP', 'EXIT_CODE', 'EXIT_STATUS', 'COMMAND', 'VIRTUALENV', '_AUDIT_FIELD_OLD_PROM', 'VIRTUALENV_COMMAND', 'IO_METRIC_WRITE_OPERATIONS', 'VIRTUALENV_SITE_PACKAGES', 'IO_METRIC_WRITE_BYTES', '_AUDIT_FIELD_PROM', 'REQUIREMENTS', 'VERSION', 'EXTRA_ARGS', 'EDITABLE', 'IO_METRIC_READ_OPERATIONS', 'IO_METRIC_READ_BYTES', 'VIRTUALENV_PYTHON', 'DNS4', 'FORWARDDELAY', 'HELLOTIME', 'RUNNER_FAST_RATE', 'MIIMON', 'STP', 'DNS6_SEARCH', 'AUDIT_FIELD_ACL', 'HAIRPIN', 'ROUTE_METRIC4', 'DOWNDELAY', 'AUDIT_FIELD_RDEV', 'DNS6_IGNORE_AUTO', 'INGRESS', 'AUDIT_FIELD_NET', 'IFNAME', 'GSM', 'AUDIT_FIELD_OLD_DISK', 'WIFI', 'ZONE', 'SLAVEPRIORITY', 'NEVER_DEFAULT4', 'VXLAN_ID', 'GW6', 'XMIT_HASH_POLICY', 'LIBVIRT_DOMAIN', 'ARP_IP_TARGET', 'LIBVIRT_SOURCE', 'GW4', 'LIBVIRT_CODE', 'AUDIT_FIELD_PATH', 'VXLAN_LOCAL', 'AUDIT_FIELD_DEVICE', 'AUDIT_FIELD_OLD_MEM', 'CONN_NAME', 'WIREGUARD', 'ROUTES6', 'ROUTE_METRIC6', 'AUDIT_FIELD_CLASS', 'UPDELAY', 'IP_TUNNEL_REMOTE', 'AUDIT_FIELD_OLD_NET', 'AUDIT_FIELD_OLD_VCPU', 'AUDIT_FIELD_NEW_VCPU', 'ROUTES4', 'PRIMARY', 'ADDR_GEN_MODE6', 'SSID', 'AUDIT_FIELD_OLD_CHARDEV', 'AUDIT_FIELD_NEW_DISK', 'PATH_COST', 'AUDIT_FIELD_MODEL', 'VXLAN_REMOTE', 'AUDIT_FIELD_VM', 'SLAVE_TYPE', 'MAXAGE', 'WIFI_SEC', 'FLAGS', 'MAY_FAIL4', 'AGEINGTIME', 'AUDIT_FIELD_IMG_CTX', 'AUDIT_FIELD_UUID', 'DNS6', 'MTU', 'MASTER', 'ARP_INTERVAL', 'AUDIT_FIELD_VM_CTX', 'METHOD4', 'DNS4_OPTIONS', 'GW6_IGNORE_AUTO', 'AUDIT_FIELD_BUS', 'EGRESS', 'AUDIT_FIELD_VIRT', 'ROUTES4_EXTENDED', 'AUDIT_FIELD_REASON', 'ROUTES6_EXTENDED', 'DNS4_IGNORE_AUTO', 'AUDIT_FIELD_VM_PID', 'VPN', 'TYPE', 'DNS4_SEARCH', 'TRANSPORT_MODE', 'IP_TUNNEL_LOCAL', 'AUDIT_FIELD_NEW_NET', 'AUDIT_FIELD_MAJ', 'IP_TUNNEL_DEV', 'AUDIT_FIELD_NEW_MEM', 'ROUTING_RULES4', 'IP_TUNNEL_INPUT_KEY', 'IP6', 'DHCP_CLIENT_ID', 'IP_PRIVACY6', 'DNS6_OPTIONS', 'IP4', 'IP_TUNNEL_OUTPUT_KEY', 'MAC', 'RUNNER_HWADDR_POLICY', 'GW4_IGNORE_AUTO', 'VLANDEV', 'MACVLAN', 'RUNNER', 'AUDIT_FIELD_CATEGORY', 'AUDIT_FIELD_NEW_CHARDEV', 'VLANID', 'METHOD6', 'IGNORE_UNSUPPORTED_SUBOPTIONS', 'AUTOCONNECT', 'AUDIT_FIELD_CGROUP', 'N_RESTARTS', 'COREDUMP_TIMESTAMP', 'COREDUMP_PACKAGE_NAME', 'COREDUMP_GID', 'COREDUMP_PROC_STATUS', 'COREDUMP_FILENAME', 'PODMAN_EVENT', 'PODMAN_TIME', 'COREDUMP_CGROUP', 'COREDUMP_PROC_AUXV', 'COREDUMP_PROC_LIMITS', 'COREDUMP_ENVIRON', 'COREDUMP_OPEN_FDS', 'COREDUMP_RLIMIT', 'COREDUMP_UID', 'COREDUMP_USER_UNIT', 'COREDUMP_PROC_MOUNTINFO', 'COREDUMP_PROC_MAPS', 'COREDUMP_PACKAGE_VERSION', 'COREDUMP_PACKAGE_JSON', 'PODMAN_TYPE', 'COREDUMP_UNIT', 'COREDUMP_CMDLINE', 'COREDUMP_PROC_CGROUP', 'COREDUMP_SLICE', 'COREDUMP_ROOT', 'COREDUMP_SIGNAL_NAME', 'COREDUMP_PID', 'COREDUMP_HOSTNAME', 'COREDUMP_SIGNAL', 'COREDUMP_COMM', 'COREDUMP_CWD', 'COREDUMP_EXE', 'COREDUMP_OWNER_UID', 'SRC_RANGE', 'SET_DSCP_MARK_CLASS', 'TCP_FLAGS', 'LIMIT_BURST', 'FLUSH', 'DST_RANGE', 'IP_VERSION', 'RULE_NUM', 'SET_COUNTERS', 'CHAIN_MANAGEMENT', 'TO_SOURCE', 'MATCH_SET', 'POLICY', 'MATCH_SET_FLAGS', 'DESTINATION_PORTS', 'MATCH', 'DESTINATION', 'SOURCE_PORT', 'WAIT', 'GATEWAY', 'IN_INTERFACE', 'SET_DSCP_MARK', 'LOG_LEVEL', 'REJECT_WITH', 'DESTINATION_PORT', 'OUT_INTERFACE', 'TABLE', 'SYN', 'ICMP_TYPE', 'TO_DESTINATION', 'UID_OWNER', 'FRAGMENT', 'TO_PORTS', 'LOG_PREFIX', 'GOTO', 'CHAIN', 'CTSTATE', 'PROTOCOL', 'SOURCE', 'GID_OWNER', 'JUMP', 'NUMERIC', 'DBUS_BROKER_LAUNCH_ARG1', 'BOLT_LOG_CONTEXT', 'BOLT_VERSION', 'BOLT_TOPIC', 'AUDIT_FIELD_NEW_FS', '_AUDIT_FIELD_PATH', 'AUDIT_FIELD_OLD_FS')]
    [string[]]$Fields,

    [switch]$NoSudo,

    [ValidateSet('system', 'user', '*')]
    [string]$Journal,

    $Since,

    $Until
  )

  $_args = @()

  if ($Journal -and $Journal -ne '*') { $args += "--$Journal" }
  if ($Unit) {
    $param = if ($Journal -eq 'user') { 'user-unit' } else { 'unit' }
    $_args += "--$param=$Unit"
  }
  if ($Count) { $_args += "--lines=$Count" }
  if ($Format) { $_args += "--output=$Format" }
  if ($Fields) { $_args += "--output-fields=$($Fields -join ',')" }
  foreach ($Key in 'Since', 'Until') {
    $Value = $PSBoundParameters[$Key]
    if ($null -eq $Value) { continue }

    if ($Value -is [int]) {
      $Value = [timespan]::new(0, 0, [Math]::Abs($Value))
    }
    else {
      try { $null = [timespan]::TryParse($Value, [ref]$Value) } catch {}
    }

    if ($Value -is [timespan]) {
      $Value = [datetime]::Now.Add(-$Value)
    }

    if ($Value -is [datetime]) {
      $Value = $Value.ToString('s')
    }
    else {
      $Value = $Value -replace '(\s+ago)?\s*$', ' ago'
    }

    $_args += "--$($Key.ToLower())=$Value"
  }

  Write-Verbose "journalctl $_args"

  if ($NoSudo) {
    journalctl @_args
  }
  else {
    sudo journalctl @_args
  }
}

function Parse-IniConf {

  [CmdletBinding(DefaultParameterSetName = 'NoMapper')]
  param
  (
    [Parameter(ValueFromPipeline)]
    [string]$InputObject,

    [switch]$AsHashtable,

    [Parameter(ParameterSetName = 'Mapper')]
    [scriptblock]$ValueMapper,

    [Parameter(ParameterSetName = 'Unquote')]
    [switch]$Unquote,

    [Parameter(ParameterSetName = 'Unjson')]
    [switch]$UnJson,

    [string]$DefaultHeader = 'GLOBAL',

    [string[]]$Comment = '#'
  )

  $Content = $(if ($MyInvocation.ExpectingInput) { $input } else { $InputObject }) | Out-String

  if ($Unquote) {
    $ValueMapper = { $_ -replace "^(['`"``])(.*)(\1)$", '$2' }
  }
  elseif ($UnJson) {
    $ValueMapper = { $_ | ConvertFrom-Json -AsHashtable:$AsHashtable }
  }


  if ($Comment) {
    $CommentPatterns = $Comment | ForEach-Object {
      if ($_ -match $_) { $_ } else { [regex]::Escape($_) }
    }

    $CommentPattern = if ($CommentPatterns.Count -gt 1) {
      "($($CommentPatterns -join '|')).*"
    }
    else {
      "$CommentPatterns.*"
    }

    $Content = $Content -replace $CommentPattern
  }

  $Content = $Content.TrimStart() -replace '\n\s+(?=\r?\n)'

  $Output = [ordered]@{}

  $Chunks = $Content -split '(?<=\n)(?=\[.*\])'
  foreach ($Chunk in $Chunks) {
    $Header, $Body = $Chunk -split '(?<=^\s*\[.*\])[\s\r\n$]', 2
    if ($Header -match '^\[(?<Header>.*)\]$') {
      $Header = $Matches.Header
    }
    else {
      $Body = $Header
      $Header = $DefaultHeader
      Write-Warning "Values outside a header have been placed in '$DefaultHeader'"
    }

    $Section = [ordered]@{}
    $Kvps = $Body -split '(?<=\r?\n)(?=\s*\S+\s*=\s*)' | ForEach-Object Trim | Where-Object Length
    foreach ($Kvp in $Kvps) {

      $Key, $Value = $Kvp -split '\s*=\s*', 2

      if ($null -eq $Value) {
        Write-Warning "Key '$Header.$Key' is specified multiple times."
      }
      else {
        $Value = $Value.Trim()
      }

      if ($ValueMapper) {
        $Value = $Value | ForEach-Object $ValueMapper
      }

      if ($Section.Contains($Key)) {
        Write-Warning "Key '$Header.$Key' is specified multiple times."
      }
      $Section[$Key] = $Value
    }

    $Output[$Header] = if ($AsHashtable) { $Section } else { [pscustomobject]$Section }
  }

  if ($AsHashtable) { $Output } else { [pscustomobject]$Output }
}

function Find-UsbDevice {
  [CmdletBinding(DefaultParameterSetName = 'All')]
  param (
    [Parameter(ParameterSetName = 'ByFriendlyName', Position = 0)]
    [SupportsWildcards()]
    $Name,

    [Parameter(ParameterSetName = 'ByDevice')]
    [SupportsWildcards()]
    $Device,

    [switch]$Raw,

    [switch]$IncludeBus
  )

  if ([Environment]::OSVersion.Platform -notin 'Unix', 'MaxOSX') {
    throw [NotImplementedException]::new("Not supported on $([Environment]::OSVersion.Platform)")
  }

  if (-not (Get-Command udevadm -ErrorAction Ignore)) {
    throw [Management.Automation.CommandNotFoundException]::new('udevadm not found.')
  }

  $NameProperties = 'ID_SERIAL', 'ID_USB_SERIAL', 'ID_MODEL_FROM_DATABASE', 'ID_VENDOR_FROM_DATABASE', 'NAME'

  $SysDevPaths = sh -c 'find /sys/bus/usb/devices/usb*/ -name dev'
  foreach ($SysDevPath in $SysDevPaths) {
    $SysPath = Split-Path $SysDevPath
    $DevName = udevadm info -q name -p $SysPath

    if ($Device -and "/dev/$DevName" -notlike $Device) { continue }
    if (-not $IncludeBus -and $DevName.StartsWith('bus/')) { continue }

    $DevProps = udevadm info -q all -p $SysPath

    $Symlinks = @()
    $Properties = [ordered]@{SYSPATH = $SysPath }
    $DevProps | ForEach-Object {
      $Section, $Value = $_ -split ': ', 2
      switch ($Section) {
        'N' { $Key = 'NAME'; break }
        'S' { $Symlinks += $Value; return }
        'E' {
          if ($Symlinks) {
            $Properties.SYMLINK = [string[]]$Symlinks
            $Symlinks = $null
          }
          $Key, $Value = $Value -split '=', 2
          break
        }
        default { return }
      }

      if ($Key -eq 'DEVLINKS') {
        $Value = $Value -split ' '
      }
      elseif (-not $Raw -and $Value -match '\\') {
        $Value = printf $Value
      }

      $Properties[$Key] = $Value
    }

    if ($Name -or -not $Raw) {
      $Names = $NameProperties | ForEach-Object { $Properties[$_] } | Where-Object Length
      if ($Name -and -not ($Names -like $Name)) { continue }
    }

    if ($Raw) {
      [pscustomobject]$Properties
    }
    else {
      [pscustomobject]@{
        FriendlyName = $Names | Select-Object -First 1
        Device       = $Properties.DEVNAME
        Properties   = [pscustomobject]$Properties
      }
    }
  }
}

function Search-History {
  [alias('hist')]
  param (
    [string]$SearchTerm,
    [switch]$g, # global search
    [switch]$s  # session search
  )

  #requires -Module PSReadLine

  if ($PSBoundParameters.Count -eq 0 ) {
    $result = Get-Content (Get-PSReadlineOption).HistorySavePath | Get-Unique
    return $result
  }

  if ($g) {
    $result = Get-Content (Get-PSReadlineOption).HistorySavePath |
    Where-Object { $_ -like "*$SearchTerm*" } | Get-Unique
    return $result
  }

  if ($s) {
    $Table = @(
      @{Expression = 'Id' },
      @{Expression = 'CommandLine'; Label = 'Invoked Commands' },
      @{Expression = 'Duration' },
      @{Expression = 'StartExecutionTime'; Label = 'Executed Time' }
    )

    $result = Get-History | Where-Object { $_.CommandLine -like "*$SearchTerm*" } |
    Format-Table -Property $Table -Wrap -AutoSize
    return $result
  }
}

function Clear-PSHistory {
  [alias('clr-hist')]
  param ()

  Get-PSReadLineOption |
  Select-Object -ExpandProperty HistorySavePath |
  Remove-Item -Force -Recurse
}

function Get-Aliases {
  [CmdletBinding()]
  [Alias('aliae')]
  param()
  Get-MyAlias |
  Sort-Object Source, Name |
  Format-Table -Property Name, Definition, Version, Source -AutoSize
}

function Get-Dirstats {
  [alias('dirstats')]
  param(
    [Alias('d')]
    [string]$Dir,

    [Alias('f')]
    [string]$Format
  )

  $CurrDir = (Get-Location).Path

  if (($Dir) -and (Test-Path $Dir)) { Set-Location $Dir; $AllItemsInCurrDir = Get-Item ./* }
  else { $AllItemsInCurrDir = Get-Item ./* }

  $FormatAndPath = New-Object -TypeName PSObject -Property @{Path = "$((Get-Location).Path)" }

  if (($Format -eq 'KB') -or ($Format -eq 'GB') -or ($Format -eq 'TB')) {
    $FormatAndPath | Add-Member -NotePropertyMembers @{Format = $Format }
  }
  else { $FormatAndPath | Add-Member -NotePropertyMembers @{Format = 'MB' } }

  $FormatAndPath | Select-Object Format, Path | Format-List

  $Index = 0
  $TotalIndex = ($AllItemsInCurrDir).count
  foreach ($ThisDir in $AllItemsInCurrDir) {
    $Index++
    $ContentsOfThisDir = Get-ChildItem $ThisDir.Name -Recurse -Force -ErrorAction Ignore
    $ContentsCount = ($ContentsOfThisDir).count
    $ContentsIndex = 1
    $TotalDirCount = 0
    $TotalFileCount = 0
    $TotalLength = 0
    $LargestItemSize = 0
    $LargestItemDir = $null
    foreach ($Item in $ContentsOfThisDir) {
      Write-Progress -id 1 -Activity "Collecting Stats for -> $($ThisDir.Name) ( $([int]$Index) / $($TotalIndex) )" -Status "$(($ContentsIndex++/$ContentsCount).ToString('P')) Complete"
      if ($Item.Mode -like 'd*') {
        $TotalDirCount++
      }
      elseif ($Item.Mode -NotLike 'd*') {
        $TotalFileCount++
      }
      if ($Item.Length) {
        $TotalLength += ($Item).Length
        if ($LargestItemSize -lt ($Item).Length) {
          $LargestItemSize = ($Item).Length
          $LargestItemDir = $Item.VersionInfo.FileName
        }
      }
    }
    $ThisDir | Add-Member -NotePropertyMembers @{Contents = $ContentsOfThisDir }
    $ThisDir | Add-Member -NotePropertyMembers @{DirCount = $TotalDirCount }
    $ThisDir | Add-Member -NotePropertyMembers @{FileCount = $TotalFileCount }
    $ThisDir | Add-Member -NotePropertyMembers @{LargestItem = $LargestItemDir }
    if ($Format -eq 'KB') { $ThisDir | Add-Member -NotePropertyMembers @{LargestItemSize = [math]::round($LargestItemSize / 1KB, 8) } ; $ThisDir | Add-Member -NotePropertyMembers @{TotalSize = [math]::round($TotalLength / 1KB, 8) } }
    elseif ($Format -eq 'MB') { $ThisDir | Add-Member -NotePropertyMembers @{LargestItemSize = [math]::round($LargestItemSize / 1MB, 8) } ; $ThisDir | Add-Member -NotePropertyMembers @{TotalSize = [math]::round($TotalLength / 1MB, 8) } }
    elseif ($Format -eq 'GB') { $ThisDir | Add-Member -NotePropertyMembers @{LargestItemSize = [math]::round($LargestItemSize / 1GB, 8) } ; $ThisDir | Add-Member -NotePropertyMembers @{TotalSize = [math]::round($TotalLength / 1GB, 8) } }
    elseif ($Format -eq 'TB') { $ThisDir | Add-Member -NotePropertyMembers @{LargestItemSize = [math]::round($LargestItemSize / 1TB, 8) } ; $ThisDir | Add-Member -NotePropertyMembers @{TotalSize = [math]::round($TotalLength / 1TB, 8) } }
    else { $ThisDir | Add-Member -NotePropertyMembers @{LargestItemSize = [math]::round($LargestItemSize / 1MB, 8) } ; $ThisDir | Add-Member -NotePropertyMembers @{TotalSize = [math]::round($TotalLength / 1MB, 8) } } #Set to MB by default
  }
  Write-Progress -id 1 -Completed -Activity 'Complete'
  $AllItemsInCurrDir | Select-Object Mode, LastWriteTime, Name, DirCount, FileCount, TotalSize, LargestItemSize, LargestItem, Contents |
  Sort-Object TotalSize, FileCount, DirCount, Mode, Contents |
  Format-Table -AutoSize

  if ($Dir) { Set-Location $CurrDir }
}

# https://raw.githubusercontent.com/HarmVeenstra/Powershellisfun/refs/heads/main/Create%20a%20Report%20on%20DNS%20lookups/Get-DnsCacheReport.ps1
function Get-DnsCacheReport {
  param (
    [Parameter(Mandatory = $true)][int]$Minutes,
    [Parameter(Mandatory = $false)][string]$CsvPath
  )

  # Set script root directory to ensure relative paths work correctly
  Set-Location $PSScriptRoot
  [System.Environment]::CurrentDirectory = $PSScriptRoot

  # Spinner up a background job to periodically update DNS cache
  $origpos = $host.UI.RawUI.CursorPosition
  $spinner = (Get-Content "$env:PWSH\lib\Assets\spinners.json" | ConvertFrom-Json -AsHashTable).moon.frames
  $spinnerPos = 0

  $t = New-TimeSpan -Minute $Minutes
  $remain = $t
  $d = (Get-Date) + $t
  [int]$Interval = 1

  # Start countdown
  while ($remain.TotalSeconds -gt 0) {
    Write-Host (' {0} ' -f $spinner[$spinnerPos % ($spinner.Count)]) -NoNewline
    Write-Host 'Gathering DNS Cache Information, countdown:' -ForegroundColor 'Green' -NoNewline
    Write-Host (' {0} days {1:d2}:{2:d2}:{3:d2} ' -f $remain.Days, $remain.Hours, $remain.Minutes, $remain.Seconds) -ForegroundColor 'Yellow' -NoNewline
    Write-Host 'remaining...' -ForegroundColor 'Green' -NoNewline

    $Host.UI.RawUI.CursorPosition = $origpos
    $spinnerPos += 1
    Start-Sleep -Seconds $Interval

    # Get DNS cache information and update remaining time
    $dnscache = Get-DnsClientCache
    $result = foreach ($item in $dnscache) {
      [PSCustomObject]@{
        Entry      = $item.Entry
        RecordType = (Get-DnsRecordType $item.Type)
        Status     = (Get-DnsStatus $item.Status)
        Section    = (Get-DnsSection $item.Section)
        Target     = $item.Data
      }
    }
    $remain = ($d - (Get-Date))
  }
  Write-Host 'Finished gathering DNS Cache Information' -ForegroundColor 'Green'
  if ($CsvPath) {
    Write-Host "Saved results into $CsvPath" -ForegroundColor 'Cyan'
    $result | Export-Csv -Path $CsvPath -Encoding utf8 -Delimiter ';' -NoTypeInformation -Force
  }
  $result | Sort-Object Entry | Format-Table
}

function Get-DnsRecordType($type) {
  switch ($type) {
    1 { return 'A' }
    2 { return 'NS' }
    5 { return 'CNAME' }
    6 { return 'SOA' }
    12 { return 'PTR' }
    15 { return 'MX' }
    28 { return 'AAAA' }
    33 { return 'SRV' }
    default { return 'Unknown' }
  }
}

function Get-DnsStatus($status) {
  switch ($status) {
    0 { return 'Success' }
    9003 { return 'NotExist' }
    9501 { return 'NoRecords' }
    9701 { return 'NoRecords' }
    default { return 'Unknown' }
  }
}

function Get-DnsSection($section) {
  switch ($section) {
    1 { return 'Answer' }
    2 { return 'Authority' }
    3 { return 'Additional' }
    default { return 'Unknown' }
  }
}
function Get-Mountpoints {
  [alias('mnts')]
  param()

  $Capacity = @{Name = 'Capacity(GB)'; Expression = { [math]::round(($_.Capacity / 1073741824)) } }
  $FreeSpace = @{Name = 'FreeSpace(GB)'; Expression = { [math]::round(($_.FreeSpace / 1073741824), 1) } }
  $Usage = @{
    Name       = 'Usage'
    Expression = {
      -join ([math]::round(100 - ((($_.FreeSpace / 1073741824) / ($_.Capacity / 1073741824)) * 100), 0), '%')
    }
    Alignment  = 'Right'
  }

  $volumes = if ($IsCoreCLR) {
    Get-CimInstance -ClassName Win32_Volume
  }
  else {
    Get-WmiObject -Class Win32_Volume
  }

  $volumes |
  Where-Object Name -notlike '\\?\Volume*' |
  Format-Table DriveLetter, Label, FileSystem, $Capacity, $FreeSpace, $Usage, PageFilePresent, IndexingEnabled, Compressed -AutoSize
}

function Get-Netstats {
  [alias('netstats')]
  param (
    [switch] $Listen,
    [string] $Process,
    [string] $ID,
    [string] $LocalPort,
    [string] $RemotePort
  )

  $Results = @()

  if ($PSBoundParameters.Count -eq 0) {
    Write-AnimatedProgress -Label 'Collecting TCP & UDP connections ...'
    $TCPConnections = Get-NetTCPConnection -ErrorAction SilentlyContinue
    $UDPConnections = Get-NetUDPEndpoint -ErrorAction SilentlyContinue
    $Sort = 'LocalAddress'
  }

  if ($Listen) {
    Write-AnimatedProgress -Label 'Collecting TCP Connections of Listening State ...'
    $TCPConnections = Get-NetTCPConnection -State Listen -ErrorAction SilentlyContinue
    $Sort = 'LocalAddress'
  }

  if ($Process) {
    Write-AnimatedProgress -Label "Collecting TCP & UDP Connections of Process Name - $Process ..."
    $ProcessId = (Get-Process -Name $Process -ErrorAction SilentlyContinue).Id
    $TCPConnections = Get-NetTCPConnection -OwningProcess $ProcessId -ErrorAction SilentlyContinue
    $UDPConnections = Get-NetUDPEndpoint -OwningProcess $ProcessId -ErrorAction SilentlyContinue
    $Sort = 'LocalAddress'
  }

  if ($ID) {
    Write-AnimatedProgress -Label "Collecting TCP & UDP Connections of Process ID - $ID ..."
    $TCPConnections = Get-NetTCPConnection -OwningProcess $ID -ErrorAction SilentlyContinue
    $UDPConnections = Get-NetUDPEndpoint -OwningProcess $ID -ErrorAction SilentlyContinue
    $Sort = 'LocalAddress'
  }

  if ($LocalPort) {
    Write-AnimatedProgress -Label "Collecting TCP & UDP Connections of Local Port - $LocalPort ..."
    $TCPConnections = Get-NetTCPConnection -LocalPort $LocalPort -ErrorAction SilentlyContinue
    $UDPConnections = Get-NetUDPEndpoint -LocalPort $LocalPort -ErrorAction SilentlyContinue
    $Sort = 'ProcessName'
  }

  if ($RemotePort) {
    Write-AnimatedProgress -Label "Collecting TCP Connections of Remote Port - $RemotePort ..."
    $TCPConnections = Get-NetTCPConnection -RemotePort $RemotePort -ErrorAction SilentlyContinue
    $Sort = 'ProcessName'
  }

  foreach ($Connection in $TCPConnections) {
    $Result = [PSCustomObject]@{
      CreationTime = $Connection.CreationTime
      ID           = $Connection.OwningProcess
      LocalAddress = $Connection.LocalAddress
      LocalPort    = $Connection.LocalPort
      OffloadState = $Connection.OffloadState
      ProcessName  = (Get-Process -Id $Connection.OwningProcess -ErrorAction SilentlyContinue).ProcessName
      Protocol     = 'TCP'
      RemotePort   = $Connection.RemotePort
      State        = $Connection.State
    }

    if (Resolve-DNSName -Name $Connection.RemoteAddress -DnsOnly -ErrorAction SilentlyContinue) {
      $Result | Add-Member -MemberType NoteProperty -Name 'RemoteAddress' -Value (Resolve-DNSName -Name $Connection.RemoteAddress -DnsOnly).NameHost
    }
    else {
      $Result | Add-Member -MemberType NoteProperty -Name 'RemoteAddress' -Value $Connection.RemoteAddress
    }

    $Results += $Result
  }

  foreach ($Connection in $UDPConnections) {
    $Result = [PSCustomObject]@{
      CreationTime  = $Connection.CreationTime
      ID            = $Connection.OwningProcess
      LocalAddress  = $Connection.LocalAddress
      LocalPort     = $Connection.LocalPort
      OffloadState  = $Connection.OffloadState
      ProcessName   = (Get-Process -Id $Connection.OwningProcess -ErrorAction SilentlyContinue).ProcessName
      Protocol      = 'UDP'
      RemoteAddress = $Connection.RemoteAddress
      RemotePort    = $Connection.RemotePort
      State         = $Connection.State
    }
    $Results += $Result
  }

  $Results |
  Select-Object Protocol, LocalAddress, LocalPort, RemoteAddress, RemotePort, ProcessName, ID |
  Sort-Object -Property @{Expression = 'Protocol' }, @{Expression = $Sort } |
  Format-Table -AutoSize -Wrap
}

function Write-AnimatedProgress {
  <#
    .SYNOPSIS
        Show animated animations while waiting for progress done.
    .LINK
        https://github.com/Jaykul/Spinner/blob/master/Spinner.ps1
        https://github.com/DBremen/Write-TerminalProgress/blob/main/Write-TerminalProgress.ps1
        https://github.com/sindresorhus/cli-spinners/blob/07c83e7b9d8a08080d71ac8bda2115c83501d9d6/spinners.json
    #>
  param (
    [string]$SpinnerName = 'earth',
    [string]$Label = '',
    [string[]]$Frames,
    [int]$Interval = 80,
    [int]$Duration = 10
  )

  $e = [char]27
  $Sw = [System.Diagnostics.Stopwatch]::new()
  $Sw.Start()
  $Duration *= 500

  Set-Location $PSScriptRoot
  [System.Environment]::CurrentDirectory = $PSScriptRoot

  if ($SpinnerName) {
    $spinnersPath = "$Env:PWSH\lib\Assets\spinners.json"
    $spinners = Get-Content $spinnersPath | ConvertFrom-Json -AsHashtable
    $spinner = $spinners[$SpinnerName]
    $Interval = $spinner['interval']
    $Frames = $spinner['frames']
  }

  $Frames = $Frames.ForEach{ "$e[u" + $_ + ' ' + $Label }
  Write-Host "$e[s" -NoNewline

  do {
    foreach ($Frame in $Frames) {
      Write-Host $Frame -NoNewline
      Start-Sleep -Milliseconds $Interval
    }
  } while ($Sw.ElapsedMilliseconds -lt $Duration)

  Write-Host ("$e[u" + (' ' * ($Frame.Length + $Label.Length + 1)) + "$e[u") -NoNewline
  $Sw.Stop()
}

function Get-ScheduledTasksInfo {
  param(
    [switch]$Running,
    [switch]$Ready,
    [switch]$Disabled
  )
  if ($Running) {
    Get-ScheduledTask | Where-Object { ($_.State -eq 'Running') } |
    Select-Object TaskName, Author, State, URI |
    Sort-Object TaskName | Format-Table -GroupBy State -Property TaskName, URI, Author -AutoSize -Wrap
  }
  if ($Ready) {
    Get-ScheduledTask | Where-Object { ($_.State -eq 'Ready') } |
    Select-Object TaskName, Author, State, URI |
    Sort-Object TaskName | Format-Table -GroupBy State -Property TaskName, URI, Author -AutoSize -Wrap
  }
  if ($Disabled) {
    Get-ScheduledTask | Where-Object { ($_.State -eq 'Disabled') } |
    Select-Object TaskName, Author, State, URI |
    Sort-Object TaskName | Format-Table -GroupBy State -Property TaskName, URI, Author -AutoSize -Wrap
  }
}

function Get-ScheduledTaskDetail {
  param (
    [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
    [string]$Name
  )
  Get-ScheduledTask -TaskName $Name | Format-List
}

function Invoke-ScheduledTasksRunning {
  Get-ScheduledTasksInfo -Running
}

function Invoke-ScheduledTasksReady {
  Get-ScheduledTasksInfo -Ready
}

function Invoke-ScheduledTasksDisabled {
  Get-ScheduledTasksInfo -Disabled
}

Set-Alias -Name 'tasks-running' -Value 'Invoke-ScheduledTasksRunning'
Set-Alias -Name 'tasks-ready' -Value 'Invoke-ScheduledTasksReady'
Set-Alias -Name 'tasks-disabled' -Value 'Invoke-ScheduledTasksDisabled'

function Get-WifiPassword {
  [alias('wifipass')]
  param ([Alias('n', 'name')][string]$WifiName)

  if (!$WifiName) {
    $wifiList = netsh wlan show profiles | Select-String -Pattern 'All User Profile\s+:\s+(.*)' | ForEach-Object { $_.Matches.Groups[1].Value }

    if (Get-Command gum -ErrorAction SilentlyContinue) {
      $WifiName = gum choose --header="Choose an available Wi-Fi name:" $wifiList
    }

    elseif (Get-Command fzf -ErrorAction SilentlyContinue) {
      $WifiName = $wifiList | fzf --prompt="Select Wi-Fi >  " --height=~80% --layout=reverse --border --exit-0 --cycle --margin="2,40" --padding=1
    }

    else {
      for ($i = 0; $i -lt $wifiList.Count; $i++) {
        Write-Host "[$i] $($wifiList[$i])"
      }
      $index = $(Write-Host 'Enter the corresponding number of Wi-Fi name: ' -ForegroundColor Magenta -NoNewline; Read-Host)
      if ($null -ne $index) {
        if ($index -match '^\d+$' -and [int]$index -lt $wifiList.Count) {
          $WifiName = $wifiList[$index]
        }
        else { return }
      }
    }
  }

  $WifiPassword = netsh wlan show profile name="$WifiName" key=clear | Select-String -Pattern 'Key Content\s+:\s+(.+)' | ForEach-Object { $_.Matches.Groups[1].Value }

  if (!$WifiPassword) { Write-Warning "No password available for Wi-Fi $WifiName"; return }
  else {
    Write-Verbose "Prints password for Wi-Fi $WifiName"
    Write-Output $WifiPassword
  }
}

function bfg {
  # Assume that you installed bfg somewhere in user's `HOME` directory
  $bfgFile = (Get-ChildItem -Path "$Env:USERPROFILE" -Recurse -Filter 'bfg.jar' -ErrorAction SilentlyContinue).FullName

  if (Test-Path "$bfgFile" -PathType Leaf) {
    java -jar $bfgFile $args
  }
  else {
    Write-Warning "File not found: bfg.jar. Please install 'BFG' to continue."
    Write-Host 'Exiting...' -ForegroundColor DarkGray
    return
  }
}

function Remove-GitUnwantedData {
  [alias('git-unwanted')]
  param (
    [Parameter(Mandatory = $True, Position = 0)]
    [string]$RepoName,

    [Alias('lf')][switch]$LargeFiles,
    [string]$Size = '100M',

    [Alias('sd')][switch]$SensitiveData,
    [string]$FileName,
    [switch]$FolderName
  )

  $VerbosePreference = 'SilentlyContinue'

  $currentLocation = "$($(Get-Location).Path)"
  $gitRepo = "$RepoName.git"
  $backupDate = Get-Date -Format 'dd/MM/yyyy_HH:mm:ss'

  Write-Verbose "Clone a fresh copy of your $RepoName (bare repo)"
  gh repo clone $RepoName -- --mirror

  Write-Verbose "Make backup for bare $RepoName to $gitRepo_$backupDate.bak"
  Copy-Item -Path "$currentLocation/$gitRepo" -Destination "$currentLocation/$gitRepo_$backupDate.bak" -Recurse -Force -ErrorAction SilentlyContinue

  if ($LargeFiles) {
    Write-Verbose "Clean repo $RepoName using BFG"
    bfg --strip-blobs-bigger-than $Size $gitRepo
  }
  elseif ($SensitiveData) {
    Write-Verbose 'Remove sensitive data from Git repo'
    $bfgArg = ''
    if ($FileName) { $bfgArg += " --delete-files $FileName" }
    if ($FolderName) { $bfgArgs += " --delete-folders $FolderName" }
    if (!$FileName -and !$FolderName) { return }
    bfg $bfgArg $gitRepo
  }

  Set-Location "$currentLocation/$gitRepo"
  Write-Verbose 'Examine the repo to make sure history has been updated.'
  git reflog expire --expire=now --all

  Write-Verbose "Use 'git gc' command to strip out the unwanted dirty data"
  git gc --prune=now --aggressive

  $updateRefs = $(Write-Host "Are you happy with the updated state of current $repoDir? (y/N) " -ForegroundColor Magenta -NoNewline; Read-Host )
  if ($updateRefs.ToUpper() -eq 'Y') {
    Write-Host 'Pushing new updates for all refs on your remote repository server...' -ForegroundColor Blue
    git push
  }

  Set-Location "$currentLocation"

}

function Invoke-GitOpen {
  [CmdletBinding()]
  [alias('git-open')]
  param (
    [string]$Path = "$($(Get-Location).Path)"
  )

  $currentLocation = "$($(Get-Location).Path)"

  # Exit immediately if `Path` is not a git repo
  $workingDir = (Resolve-Path $Path).Path
  if (!(Test-Path "$workingDir/.git" -PathType Container)) {
    Write-Warning 'not a git repository (or any of the parent directories): .git'
    break
  }

  # Get git branch
  $branch = git -C $workingDir symbolic-ref -q --short HEAD

  # Use `gh` to open github repo
  if (Get-Command gh -ErrorAction SilentlyContinue) {
    Set-Location "$Path"
    gh repo view --branch $branch --web
    Set-Location $currentLocation
  }

  # Find the exact url to open github repo
  # References:
  # - https://github.com/paulirish/git-open

  else {
    $remote = git -C $workingDir config "branch.$branch.remote"
    $gitUrl = git -C $workingDir remote get-url "$remote"

    if ($gitUrl -match '^[a-z\+]+://.*') {
      $gitProtocol = $gitUrl.Replace('://.*', '')
      $uri = $gitUrl -replace '.*://', ''
      $urlPath = $uri.Split('/', 2)[1]
      $domain = $uri.Split('/', 2)[0]

      if ($gitProtocol -ne 'https' -and $gitProtocol -ne 'http') {
        $domain = $domain -replace ':.*', ''
      }
    }
    else {
      $uri = $gitUrl -replace '.*@', ''
      $domain = $uri -replace ':.*', ''
      $urlPath = $uri -replace '.*?:', ''
    }

    $urlPath = $urlPath.TrimStart('/').TrimEnd('.git')
    if ($gitProtocol -eq 'http') { $protocol = 'http' }
    else { $protocol = 'https' }

    $openUrl = "${protocol}://$domain/$urlPath/tree/$branch"

    Write-Output "Opening $openUrl in your browser."
    Start-Process "$openUrl"
  }
}

function Get-KnownFolderPath {
  Param (
    [Parameter(Mandatory = $true)]
    [ValidateSet('3DObjects', 'AddNewPrograms', 'AdminTools', 'AppUpdates', 'CDBurning',
      'ChangeRemovePrograms', 'CommonAdminTools', 'CommonOEMLinks', 'CommonPrograms',
      'CommonStartMenu', 'CommonStartup', 'CommonTemplates', 'ComputerFolder',
      'ConflictFolder', 'ConnectionsFolder', 'Contacts', 'ControlPanelFolder',
      'Cookies', 'Desktop', 'Documents', 'Downloads', 'Favorites', 'Fonts', 'Games',
      'GameTasks', 'History', 'InternetCache', 'InternetFolder', 'Links',
      'LocalAppData', 'LocalAppDataLow', 'LocalizedResourcesDir', 'Music', 'NetHood',
      'NetworkFolder', 'OriginalImages', 'PhotoAlbums', 'Pictures', 'Playlists',
      'PrintersFolder', 'PrintHood', 'Profile', 'ProgramData', 'ProgramFiles',
      'ProgramFilesX64', 'ProgramFilesX86', 'ProgramFilesCommon', 'ProgramFilesCommonX64',
      'ProgramFilesCommonX86', 'Programs', 'Public', 'PublicDesktop', 'PublicDocuments',
      'PublicDownloads', 'PublicGameTasks', 'PublicMusic', 'PublicPictures',
      'PublicVideos', 'QuickLaunch', 'Recent', 'RecycleBinFolder', 'ResourceDir',
      'RoamingAppData', 'SampleMusic', 'SamplePictures', 'SamplePlaylists', 'SampleVideos',
      'SavedGames', 'SavedSearches', 'SEARCH_CSC', 'SEARCH_MAPI', 'SearchHome', 'SendTo',
      'SidebarDefaultParts', 'SidebarParts', 'StartMenu', 'Startup', 'SyncManagerFolder',
      'SyncResultsFolder', 'SyncSetupFolder', 'System', 'SystemX86', 'Templates',
      'TreeProperties', 'UserProfiles', 'UsersFiles', 'Videos',
      'Windows')] [string]$Folder
  )

  # Define known folder GUIDs
  $KnownFolders = @{
    '3DObjects'             = '31C0DD25-9439-4F12-BF41-7FF4EDA38722'
    'AddNewPrograms'        = 'de61d971-5ebc-4f02-a3a9-6c82895e5c04'
    'AdminTools'            = '724EF170-A42D-4FEF-9F26-B60E846FBA4F'
    'AppUpdates'            = 'a305ce99-f527-492b-8b1a-7e76fa98d6e4'
    'CDBurning'             = '9E52AB10-F80D-49DF-ACB8-4330F5687855'
    'ChangeRemovePrograms'  = 'df7266ac-9274-4867-8d55-3bd661de872d'
    'CommonAdminTools'      = 'D0384E7D-BAC3-4797-8F14-CBA229B392B5'
    'CommonOEMLinks'        = 'C1BAE2D0-10DF-4334-BEDD-7AA20B227A9D'
    'CommonPrograms'        = '0139D44E-6AFE-49F2-8690-3DAFCAE6FFB8'
    'CommonStartMenu'       = 'A4115719-D62E-491D-AA7C-E74B8BE3B067'
    'CommonStartup'         = '82A5EA35-D9CD-47C5-9629-E15D2F714E6E'
    'CommonTemplates'       = 'B94237E7-57AC-4347-9151-B08C6C32D1F7'
    'ComputerFolder'        = '0AC0837C-BBF8-452A-850D-79D08E667CA7'
    'ConflictFolder'        = '4bfefb45-347d-4006-a5be-ac0cb0567192'
    'ConnectionsFolder'     = '6F0CD92B-2E97-45D1-88FF-B0D186B8DEDD'
    'Contacts'              = '56784854-C6CB-462b-8169-88E350ACB882'
    'ControlPanelFolder'    = '82A74AEB-AEB4-465C-A014-D097EE346D63'
    'Cookies'               = '2B0F765D-C0E9-4171-908E-08A611B84FF6'
    'Desktop'               = 'B4BFCC3A-DB2C-424C-B029-7FE99A87C641'
    'Documents'             = 'FDD39AD0-238F-46AF-ADB4-6C85480369C7'
    'Downloads'             = '374DE290-123F-4565-9164-39C4925E467B'
    'Favorites'             = '1777F761-68AD-4D8A-87BD-30B759FA33DD'
    'Fonts'                 = 'FD228CB7-AE11-4AE3-864C-16F3910AB8FE'
    'Games'                 = 'CAC52C1A-B53D-4edc-92D7-6B2E8AC19434'
    'GameTasks'             = '054FAE61-4DD8-4787-80B6-090220C4B700'
    'History'               = 'D9DC8A3B-B784-432E-A781-5A1130A75963'
    'InternetCache'         = '352481E8-33BE-4251-BA85-6007CAEDCF9D'
    'InternetFolder'        = '4D9F7874-4E0C-4904-967B-40B0D20C3E4B'
    'Links'                 = 'bfb9d5e0-c6a9-404c-b2b2-ae6db6af4968'
    'LocalAppData'          = 'F1B32785-6FBA-4FCF-9D55-7B8E7F157091'
    'LocalAppDataLow'       = 'A520A1A4-1780-4FF6-BD18-167343C5AF16'
    'LocalizedResourcesDir' = '2A00375E-224C-49DE-B8D1-440DF7EF3DDC'
    'Music'                 = '4BD8D571-6D19-48D3-BE97-422220080E43'
    'NetHood'               = 'C5ABBF53-E17F-4121-8900-86626FC2C973'
    'NetworkFolder'         = 'D20BEEC4-5CA8-4905-AE3B-BF251EA09B53'
    'OriginalImages'        = '2C36C0AA-5812-4b87-BFD0-4CD0DFB19B39'
    'PhotoAlbums'           = '69D2CF90-FC33-4FB7-9A0C-EBB0F0FCB43C'
    'Pictures'              = '33E28130-4E1E-4676-835A-98395C3BC3BB'
    'Playlists'             = 'DE92C1C7-837F-4F69-A3BB-86E631204A23'
    'PrintersFolder'        = '76FC4E2D-D6AD-4519-A663-37BD56068185'
    'PrintHood'             = '9274BD8D-CFD1-41C3-B35E-B13F55A758F4'
    'Profile'               = '5E6C858F-0E22-4760-9AFE-EA3317B67173'
    'ProgramData'           = '62AB5D82-FDC1-4DC3-A9DD-070D1D495D97'
    'ProgramFiles'          = '905e63b6-c1bf-494e-b29c-65b732d3d21a'
    'ProgramFilesX64'       = '6D809377-6AF0-444b-8957-A3773F02200E'
    'ProgramFilesX86'       = '7C5A40EF-A0FB-4BFC-874A-C0F2E0B9FA8E'
    'ProgramFilesCommon'    = 'F7F1ED05-9F6D-47A2-AAAE-29D317C6F066'
    'ProgramFilesCommonX64' = '6365D5A7-0F0D-45E5-87F6-0DA56B6A4F7D'
    'ProgramFilesCommonX86' = 'DE974D24-D9C6-4D3E-BF91-F4455120B917'
    'Programs'              = 'A77F5D77-2E2B-44C3-A6A2-ABA601054A51'
    'Public'                = 'DFDF76A2-C82A-4D63-906A-5644AC457385'
    'PublicDesktop'         = 'C4AA340D-F20F-4863-AFEF-F87EF2E6BA25'
    'PublicDocuments'       = 'ED4824AF-DCE4-45A8-81E2-FC7965083634'
    'PublicDownloads'       = '3D644C9B-1FB8-4f30-9B45-F670235F79C0'
    'PublicGameTasks'       = 'DEBF2536-E1A8-4c59-B6A2-414586476AEA'
    'PublicMusic'           = '3214FAB5-9757-4298-BB61-92A9DEAA44FF'
    'PublicPictures'        = 'B6EBFB86-6907-413C-9AF7-4FC2ABF07CC5'
    'PublicVideos'          = '2400183A-6185-49FB-A2D8-4A392A602BA3'
    'QuickLaunch'           = '52a4f021-7b75-48a9-9f6b-4b87a210bc8f'
    'Recent'                = 'AE50C081-EBD2-438A-8655-8A092E34987A'
    'RecycleBinFolder'      = 'B7534046-3ECB-4C18-BE4E-64CD4CB7D6AC'
    'ResourceDir'           = '8AD10C31-2ADB-4296-A8F7-E4701232C972'
    'RoamingAppData'        = '3EB685DB-65F9-4CF6-A03A-E3EF65729F3D'
    'SampleMusic'           = 'B250C668-F57D-4EE1-A63C-290EE7D1AA1F'
    'SamplePictures'        = 'C4900540-2379-4C75-844B-64E6FAF8716B'
    'SamplePlaylists'       = '15CA69B3-30EE-49C1-ACE1-6B5EC372AFB5'
    'SampleVideos'          = '859EAD94-2E85-48AD-A71A-0969CB56A6CD'
    'SavedGames'            = '4C5C32FF-BB9D-43b0-B5B4-2D72E54EAAA4'
    'SavedSearches'         = '7d1d3a04-debb-4115-95cf-2f29da2920da'
    'SEARCH_CSC'            = 'ee32e446-31ca-4aba-814f-a5ebd2fd6d5e'
    'SEARCH_MAPI'           = '98ec0e18-2098-4d44-8644-66979315a281'
    'SearchHome'            = '190337d1-b8ca-4121-a639-6d472d16972a'
    'SendTo'                = '8983036C-27C0-404B-8F08-102D10DCFD74'
    'SidebarDefaultParts'   = '7B396E54-9EC5-4300-BE0A-2482EBAE1A26'
    'SidebarParts'          = 'A75D362E-50FC-4fb7-AC2C-A8BEAA314493'
    'StartMenu'             = '625B53C3-AB48-4EC1-BA1F-A1EF4146FC19'
    'Startup'               = 'B97D20BB-F46A-4C97-BA10-5E3608430854'
    'SyncManagerFolder'     = '43668BF8-C14E-49B2-97C9-747784D784B7'
    'SyncResultsFolder'     = '289a9a43-be44-4057-a41b-587a76d7e7f9'
    'SyncSetupFolder'       = '0F214138-B1D3-4a90-BBA9-27CBC0C5389A'
    'System'                = '1AC14E77-02E7-4E5D-B744-2EB1AE5198B7'
    'SystemX86'             = 'D65231B0-B2F1-4857-A4CE-A8E7C6EA7D27'
    'Templates'             = 'A63293E8-664E-48DB-A079-DF759E0509F7'
    'TreeProperties'        = '5b3749ad-b49f-49c1-83eb-15370fbd4882'
    'UserProfiles'          = '0762D272-C50A-4BB0-A382-697DCD729B80'
    'UsersFiles'            = 'f3ce0f7c-4901-4acc-8648-d5d44b04ef8f'
    'Videos'                = '18989B1D-99B5-455B-841C-AB7C74E4DDFC'
    'Windows'               = 'F38BF404-1D43-42F2-9305-67DE0B28FC23'
  }

  $guid = $KnownFolders.$("$folder")

  #https://renenyffenegger.ch/notes/Windows/dirs/_known-folders
  if ('shell32' -as [type]) {} else {
    add-type @'
    using System;
    using System.Runtime.InteropServices;

    public class shell32  {
        [DllImport("shell32.dll")]
        private static extern int SHGetKnownFolderPath(
             [MarshalAs(UnmanagedType.LPStruct)]
             Guid       rfid,
             uint       dwFlags,
             IntPtr     hToken,
             out IntPtr pszPath
         );

         public static string GetKnownFolderPath(Guid rfid)  {
            IntPtr pszPath;
            if (SHGetKnownFolderPath(rfid, 0, IntPtr.Zero, out pszPath) != 0) {
                return "Could not get folder";
            }
            string path = Marshal.PtrToStringUni(pszPath);
            Marshal.FreeCoTaskMem(pszPath);
            return path;
         }
    }
'@
  }
  # now get the folder from the GUID
  $result = $([shell32]::GetKnownFolderPath("{$($guid)}"))
  "$result"
}

function Set-KnownFolderPath {
  Param (
    [Parameter(Mandatory = $true)]
    [ValidateSet('3DObjects', 'AddNewPrograms', 'AdminTools', 'AppUpdates', 'CDBurning',
      'ChangeRemovePrograms', 'CommonAdminTools', 'CommonOEMLinks', 'CommonPrograms',
      'CommonStartMenu', 'CommonStartup', 'CommonTemplates', 'ComputerFolder',
      'ConflictFolder', 'ConnectionsFolder', 'Contacts', 'ControlPanelFolder',
      'Cookies', 'Desktop', 'Documents', 'Downloads', 'Favorites', 'Fonts', 'Games',
      'GameTasks', 'History', 'InternetCache', 'InternetFolder', 'Links',
      'LocalAppData', 'LocalAppDataLow', 'LocalizedResourcesDir', 'Music',
      'NetHood', 'NetworkFolder', 'OriginalImages', 'PhotoAlbums', 'Pictures',
      'Playlists', 'PrintersFolder', 'PrintHood', 'Profile', 'ProgramData',
      'ProgramFiles', 'ProgramFilesX64', 'ProgramFilesX86', 'ProgramFilesCommon',
      'ProgramFilesCommonX64', 'ProgramFilesCommonX86', 'Programs', 'Public',
      'PublicDesktop', 'PublicDocuments', 'PublicDownloads', 'PublicGameTasks',
      'PublicMusic', 'PublicPictures', 'PublicVideos', 'QuickLaunch', 'Recent',
      'RecycleBinFolder', 'ResourceDir', 'RoamingAppData', 'SampleMusic',
      'SamplePictures', 'SamplePlaylists', 'SampleVideos', 'SavedGames',
      'SavedSearches', 'SEARCH_CSC', 'SEARCH_MAPI', 'SearchHome', 'SendTo',
      'SidebarDefaultParts', 'SidebarParts', 'StartMenu', 'Startup',
      'SyncManagerFolder', 'SyncResultsFolder', 'SyncSetupFolder', 'System',
      'SystemX86', 'Templates', 'TreeProperties', 'UserProfiles', 'UsersFiles',
      'Videos', 'Windows')] [string]$KnownFolder,

    [Parameter(Mandatory = $true)]
    [string]$Path
  )

  # Define known folder GUIDs
  $KnownFolders = @{
    '3DObjects'             = '31C0DD25-9439-4F12-BF41-7FF4EDA38722'
    'AddNewPrograms'        = 'de61d971-5ebc-4f02-a3a9-6c82895e5c04'
    'AdminTools'            = '724EF170-A42D-4FEF-9F26-B60E846FBA4F'
    'AppUpdates'            = 'a305ce99-f527-492b-8b1a-7e76fa98d6e4'
    'CDBurning'             = '9E52AB10-F80D-49DF-ACB8-4330F5687855'
    'ChangeRemovePrograms'  = 'df7266ac-9274-4867-8d55-3bd661de872d'
    'CommonAdminTools'      = 'D0384E7D-BAC3-4797-8F14-CBA229B392B5'
    'CommonOEMLinks'        = 'C1BAE2D0-10DF-4334-BEDD-7AA20B227A9D'
    'CommonPrograms'        = '0139D44E-6AFE-49F2-8690-3DAFCAE6FFB8'
    'CommonStartMenu'       = 'A4115719-D62E-491D-AA7C-E74B8BE3B067'
    'CommonStartup'         = '82A5EA35-D9CD-47C5-9629-E15D2F714E6E'
    'CommonTemplates'       = 'B94237E7-57AC-4347-9151-B08C6C32D1F7'
    'ComputerFolder'        = '0AC0837C-BBF8-452A-850D-79D08E667CA7'
    'ConflictFolder'        = '4bfefb45-347d-4006-a5be-ac0cb0567192'
    'ConnectionsFolder'     = '6F0CD92B-2E97-45D1-88FF-B0D186B8DEDD'
    'Contacts'              = '56784854-C6CB-462b-8169-88E350ACB882'
    'ControlPanelFolder'    = '82A74AEB-AEB4-465C-A014-D097EE346D63'
    'Cookies'               = '2B0F765D-C0E9-4171-908E-08A611B84FF6'
    'Desktop'               = 'B4BFCC3A-DB2C-424C-B029-7FE99A87C641'
    'Documents'             = 'FDD39AD0-238F-46AF-ADB4-6C85480369C7'
    'Downloads'             = '374DE290-123F-4565-9164-39C4925E467B'
    'Favorites'             = '1777F761-68AD-4D8A-87BD-30B759FA33DD'
    'Fonts'                 = 'FD228CB7-AE11-4AE3-864C-16F3910AB8FE'
    'Games'                 = 'CAC52C1A-B53D-4edc-92D7-6B2E8AC19434'
    'GameTasks'             = '054FAE61-4DD8-4787-80B6-090220C4B700'
    'History'               = 'D9DC8A3B-B784-432E-A781-5A1130A75963'
    'InternetCache'         = '352481E8-33BE-4251-BA85-6007CAEDCF9D'
    'InternetFolder'        = '4D9F7874-4E0C-4904-967B-40B0D20C3E4B'
    'Links'                 = 'bfb9d5e0-c6a9-404c-b2b2-ae6db6af4968'
    'LocalAppData'          = 'F1B32785-6FBA-4FCF-9D55-7B8E7F157091'
    'LocalAppDataLow'       = 'A520A1A4-1780-4FF6-BD18-167343C5AF16'
    'LocalizedResourcesDir' = '2A00375E-224C-49DE-B8D1-440DF7EF3DDC'
    'Music'                 = '4BD8D571-6D19-48D3-BE97-422220080E43'
    'NetHood'               = 'C5ABBF53-E17F-4121-8900-86626FC2C973'
    'NetworkFolder'         = 'D20BEEC4-5CA8-4905-AE3B-BF251EA09B53'
    'OriginalImages'        = '2C36C0AA-5812-4b87-BFD0-4CD0DFB19B39'
    'PhotoAlbums'           = '69D2CF90-FC33-4FB7-9A0C-EBB0F0FCB43C'
    'Pictures'              = '33E28130-4E1E-4676-835A-98395C3BC3BB'
    'Playlists'             = 'DE92C1C7-837F-4F69-A3BB-86E631204A23'
    'PrintersFolder'        = '76FC4E2D-D6AD-4519-A663-37BD56068185'
    'PrintHood'             = '9274BD8D-CFD1-41C3-B35E-B13F55A758F4'
    'Profile'               = '5E6C858F-0E22-4760-9AFE-EA3317B67173'
    'ProgramData'           = '62AB5D82-FDC1-4DC3-A9DD-070D1D495D97'
    'ProgramFiles'          = '905e63b6-c1bf-494e-b29c-65b732d3d21a'
    'ProgramFilesX64'       = '6D809377-6AF0-444b-8957-A3773F02200E'
    'ProgramFilesX86'       = '7C5A40EF-A0FB-4BFC-874A-C0F2E0B9FA8E'
    'ProgramFilesCommon'    = 'F7F1ED05-9F6D-47A2-AAAE-29D317C6F066'
    'ProgramFilesCommonX64' = '6365D5A7-0F0D-45E5-87F6-0DA56B6A4F7D'
    'ProgramFilesCommonX86' = 'DE974D24-D9C6-4D3E-BF91-F4455120B917'
    'Programs'              = 'A77F5D77-2E2B-44C3-A6A2-ABA601054A51'
    'Public'                = 'DFDF76A2-C82A-4D63-906A-5644AC457385'
    'PublicDesktop'         = 'C4AA340D-F20F-4863-AFEF-F87EF2E6BA25'
    'PublicDocuments'       = 'ED4824AF-DCE4-45A8-81E2-FC7965083634'
    'PublicDownloads'       = '3D644C9B-1FB8-4f30-9B45-F670235F79C0'
    'PublicGameTasks'       = 'DEBF2536-E1A8-4c59-B6A2-414586476AEA'
    'PublicMusic'           = '3214FAB5-9757-4298-BB61-92A9DEAA44FF'
    'PublicPictures'        = 'B6EBFB86-6907-413C-9AF7-4FC2ABF07CC5'
    'PublicVideos'          = '2400183A-6185-49FB-A2D8-4A392A602BA3'
    'QuickLaunch'           = '52a4f021-7b75-48a9-9f6b-4b87a210bc8f'
    'Recent'                = 'AE50C081-EBD2-438A-8655-8A092E34987A'
    'RecycleBinFolder'      = 'B7534046-3ECB-4C18-BE4E-64CD4CB7D6AC'
    'ResourceDir'           = '8AD10C31-2ADB-4296-A8F7-E4701232C972'
    'RoamingAppData'        = '3EB685DB-65F9-4CF6-A03A-E3EF65729F3D'
    'SampleMusic'           = 'B250C668-F57D-4EE1-A63C-290EE7D1AA1F'
    'SamplePictures'        = 'C4900540-2379-4C75-844B-64E6FAF8716B'
    'SamplePlaylists'       = '15CA69B3-30EE-49C1-ACE1-6B5EC372AFB5'
    'SampleVideos'          = '859EAD94-2E85-48AD-A71A-0969CB56A6CD'
    'SavedGames'            = '4C5C32FF-BB9D-43b0-B5B4-2D72E54EAAA4'
    'SavedSearches'         = '7d1d3a04-debb-4115-95cf-2f29da2920da'
    'SEARCH_CSC'            = 'ee32e446-31ca-4aba-814f-a5ebd2fd6d5e'
    'SEARCH_MAPI'           = '98ec0e18-2098-4d44-8644-66979315a281'
    'SearchHome'            = '190337d1-b8ca-4121-a639-6d472d16972a'
    'SendTo'                = '8983036C-27C0-404B-8F08-102D10DCFD74'
    'SidebarDefaultParts'   = '7B396E54-9EC5-4300-BE0A-2482EBAE1A26'
    'SidebarParts'          = 'A75D362E-50FC-4fb7-AC2C-A8BEAA314493'
    'StartMenu'             = '625B53C3-AB48-4EC1-BA1F-A1EF4146FC19'
    'Startup'               = 'B97D20BB-F46A-4C97-BA10-5E3608430854'
    'SyncManagerFolder'     = '43668BF8-C14E-49B2-97C9-747784D784B7'
    'SyncResultsFolder'     = '289a9a43-be44-4057-a41b-587a76d7e7f9'
    'SyncSetupFolder'       = '0F214138-B1D3-4a90-BBA9-27CBC0C5389A'
    'System'                = '1AC14E77-02E7-4E5D-B744-2EB1AE5198B7'
    'SystemX86'             = 'D65231B0-B2F1-4857-A4CE-A8E7C6EA7D27'
    'Templates'             = 'A63293E8-664E-48DB-A079-DF759E0509F7'
    'TreeProperties'        = '5b3749ad-b49f-49c1-83eb-15370fbd4882'
    'UserProfiles'          = '0762D272-C50A-4BB0-A382-697DCD729B80'
    'UsersFiles'            = 'f3ce0f7c-4901-4acc-8648-d5d44b04ef8f'
    'Videos'                = '18989B1D-99B5-455B-841C-AB7C74E4DDFC'
    'Windows'               = 'F38BF404-1D43-42F2-9305-67DE0B28FC23'
  }

  # Define SHSetKnownFolderPath if it hasn’t been defined already
  $Type1 = ([System.Management.Automation.PSTypeName]'KnownFolders').Type
  if (-not $Type1) {
    $Signature = @'
[DllImport("shell32.dll")]
public extern static int SHSetKnownFolderPath(ref Guid folderId, uint flags, IntPtr token, [MarshalAs(UnmanagedType.LPWStr)] string path);
'@
    $Type1 = Add-Type -MemberDefinition $Signature -Name 'KnownFolders' -Namespace 'SHSetKnownFolderPath' -PassThru
  }

  $Type2 = ([System.Management.Automation.PSTypeName]'ChangeNotify').Type
  if (-not $Type2) {
    $Signature = @'
[DllImport("Shell32.dll")]
public static extern int SHChangeNotify(int eventId, int flags, IntPtr item1, IntPtr item2);
'@
    $Type2 = Add-Type -MemberDefinition $Signature -Name 'ChangeNotify' -Namespace 'SHChangeNotify' -PassThru
  }

  # Validate the path
  if (Test-Path $Path -PathType Container) {
    # Call SHSetKnownFolderPath
    $r = $Type1::SHSetKnownFolderPath([ref]$KnownFolders[$KnownFolder], 0, 0, $Path)
    $Type2::SHChangeNotify(0x8000000, 0x1000, 0, 0)
    Echo "Set [$KnownFolder] to [$Path]"
    return $r
  }
  else {
    throw New-Object System.IO.DirectoryNotFoundException "Could not find part of the path $Path."
  }
}

Set-Alias -Name 'gkf' -Value Get-KnownFolderPath -Description '🤔⁉️🤔⁉️🤔⁉️🤔⁉️'
Set-Alias -Name 'skf' -Value Set-KnownFolderPath -Description '🏄‍♂️🏄‍♂️🏄‍♂️🏄‍♂️🏄‍♂️🏄‍♂️🏄‍♂️'

function Get-BIOSInfo {
  [alias('bios')]
  param ()

  Write-Host '----------------- ' -ForegroundColor 'Yellow'
  Write-Host 'BIOS Information: ' -ForegroundColor 'Yellow'
  Write-Host '----------------- ' -ForegroundColor 'Yellow'
  $details = Get-CimInstance -ClassName Win32_BIOS
  $result = [PSCustomObject]@{
    Model        = $details.Name.Trim()
    Version      = $details.Version
    SerialNumber = $details.SerialNumber
    Manufacturer = $details.Manufacturer
    ReleaseDate  = $details.ReleaseDate
  }
  return $result | Format-List
}

function Get-CPUInfo {
  [alias('cpu')]
  param ()

  Write-Host '---------------- ' -ForegroundColor 'Yellow'
  Write-Host 'CPU Information: ' -ForegroundColor 'Yellow'
  Write-Host '---------------- ' -ForegroundColor 'Yellow'
  $details = Get-WmiObject -Class Win32_Processor
  $celsius = Get-CPUTemperature
  $result = [PSCustomObject]@{
    CpuName     = $details.Name.Trim()
    Arch        = "$env:PROCESSOR_ARCHITECTURE"
    DeviceID    = $($details.DeviceID)
    Socket      = "$($details.SocketDesignation)"
    Speed       = "$($details.MaxClockSpeed) MHz"
    Temperature = "$($celsius)°C"
  }
  return $result | Format-List
}

function Get-GPUInfo {
  [alias('gpu')]
  param ()

  Write-Host '---------------- ' -ForegroundColor 'Yellow'
  Write-Host 'GPU Information: ' -ForegroundColor 'Yellow'
  Write-Host '---------------- ' -ForegroundColor 'Yellow'
  $details = Get-WmiObject Win32_videocontroller
  $result = [PSCustomObject]@{
    Model          = $details.Caption
    RAMSize        = "$($($details.AdapterRAM) / 1MB)" + ' MB'
    Pixel          = "$($details.CurrentHorizontalResolution)" + 'x' + "$($details.CurrentVerticalResolution)" + ' pixels'
    BitsPerPixel   = "$($details.CurrentBitsPerPixel)" + '-bit'
    RefreshRate    = "$($details.CurrentRefreshRate)" + ' Hz'
    MaxRefreshRate = "$($details.MaxRefreshRate)" + ' Hz'
    DriverVersion  = $details.DriverVersion
    Status         = $details.Status
  }
  return $result | Format-List
}

function Get-MotherBoardInfo {
  [alias('motherboard')]
  param ()

  Write-Host '------------------------ ' -ForegroundColor 'Yellow'
  Write-Host 'Motherboard Information: ' -ForegroundColor 'Yellow'
  Write-Host '------------------------ ' -ForegroundColor 'Yellow'
  $details = Get-WmiObject Win32_BaseBoard
  $result = [PSCustomObject]@{
    Model        = $details.Product
    SerialNumber = $details.SerialNumber
    Manufacturer = $details.Manufacturer
  }
  return $result | Format-List
}

function Get-OSInfo {
  [alias('os')]
  param ()

  Write-Host '----------------------------- ' -ForegroundColor 'Yellow'
  Write-Host 'Operating System Information: ' -ForegroundColor 'Yellow'
  Write-Host '----------------------------- ' -ForegroundColor 'Yellow'
  $details = Get-WmiObject -Class Win32_OperatingSystem
  $result = [PSCustomObject]@{
    OSName       = $details.Caption
    Arch         = $details.OSArchitecture
    Version      = $details.Version
    BuildNo      = $details.BuildNumber
    SerialNumber = $details.SerialNumber
    InstallDate  = $details.InstallDate
    ProductKey   = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SoftwareProtectionPlatform' -Name BackupProductKeyDefault).BackupProductKeyDefault
  }
  return $result | Format-List
}

function Get-RAMInfo {
  [alias('ram')]
  param ()

  Write-Host '---------------- ' -ForegroundColor 'Yellow'
  Write-Host 'RAM Information: ' -ForegroundColor 'Yellow'
  Write-Host '---------------- ' -ForegroundColor 'Yellow'
  $objs = Get-WmiObject -Class Win32_PhysicalMemory
  $objSum = $objs | Measure-Object -Property Capacity -Sum
  foreach ($obj in $objs) {
    $result = [PSCustomObject]@{
      Type           = Get-RAMType $obj.SMBIOSMemoryType
      Size           = "$($obj.Capacity / 1GB)" + ' GB'
      TotalSize      = "$($objSum.Sum / 1GB)" + ' GB'
      InstalledSlots = "$($objSum.Count)" + '/' + "$((Get-WmiObject -Class Win32_PhysicalMemoryArray).MemoryDevices)" + ' slots'
      Speed          = "$($obj.Speed)" + ' MHz'
      Voltage        = "$($obj.ConfiguredVoltage / 1000.0)" + 'V'
      Location       = "$($obj.BankLabel) / $($obj.DeviceLocator)"
      PartNumber     = $obj.PartNumber
      Manufacturer   = $obj.Manufacturer
    }
  }
  return $result | Format-List
}

function Get-SwapSpaceInfo {
  [alias('swapspace')]
  param ()

  Write-Host '----------------------- ' -ForegroundColor 'Yellow'
  Write-Host 'Swap Space Information: ' -ForegroundColor 'Yellow'
  Write-Host '----------------------- ' -ForegroundColor 'Yellow'
  $details = Get-WmiObject -Class Win32_PageFileUsage -Namespace 'root/CIMV2' -ComputerName 'localhost'
  [int]$total = [int]$used = 0
  foreach ($item in $details) {
    $total += $item.AllocatedBaseSize
    $used += $item.CurrentUsage
  }
  [int]$free = $total - $used
  [int]$percent = ($used * 100) / $total

  $result = [PSCustomObject]@{
    TotalSize = "$total" + ' MB'
    UsedSize  = "$used" + ' MB'
  }
  $result | Format-List
  Write-Host '==> Swap Space Used: ' -ForegroundColor 'Blue' -NoNewline
  Write-Host "$percent% " -ForegroundColor 'Yellow' -NoNewline
  Write-Host '(Free: ' -ForegroundColor 'Blue' -NoNewline
  Write-Host "$free MB" -ForegroundColor 'Yellow' -NoNewline
  Write-Host ')' -ForegroundColor 'Blue'
}

function Get-CPUTemperature {
  [alias('cputemp')]
  param ()

  $objects = Get-WmiObject -Query 'SELECT * FROM Win32_PerfFormattedData_Counters_ThermalZoneInformation' -Namespace 'root/CIMV2'
  foreach ($object in $objects) {
    $highPrec = $object.HighPrecisionTemperature
    $temperature = [math]::round($highPrec / 100.0, 1)
  }
  return $temperature
}

function Get-RAMType {
  [alias('ramtype')]
  param ([int]$Type)

  switch ($Type) {
    20 { return 'DDR' }
    21 { return 'DDR2' }
    24 { return 'DDR3' }
    26 { return 'DDR4' }
    34 { return 'DDR5' }
    default { return 'RAM' }
  }
}

function Add-Path {
  param (
    [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
    [string]$Path,

    [ValidateSet('Machine', 'User', 'Session')]
    [Alias('c')][string]$Container = 'Session'
  )

  if ($Container -ne 'Session') {
    $containerMapping = @{
      Machine = [System.EnvironmentVariableTarget]::Machine
      User    = [System.EnvironmentVariableTarget]::User
    }
    $containerType = $containerMapping[$Container]
    $persistedPaths = [Environment]::GetEnvironmentVariable('Path', $containerType) -split ';'
    if ($persistedPaths -notcontains $Path) {
      $persistedPaths = $persistedPaths + $Path | Where-Object { $_ }
      [Environment]::SetEnvironmentVariable('Path', $persistedPaths -join ';', $containerType)
    }
  }
  $envPaths = $Env:Path -split ';'
  if ($envPaths -notcontains $Path) {
    $envPaths = $envPaths + $Path | Where-Object { $_ }
    $Env:Path = $envPaths -join ';'
  }
}

function Remove-Path {
  param(
    [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
    [string]$Path,

    [ValidateSet('Machine', 'User', 'Session')]
    [Alias('c')][string] $Container = 'Session'
  )

  if ($Container -ne 'Session') {
    $containerMapping = @{
      Machine = [System.EnvironmentVariableTarget]::Machine
      User    = [System.EnvironmentVariableTarget]::User
    }
    $containerType = $containerMapping[$Container]

    $persistedPaths = [Environment]::GetEnvironmentVariable('Path', $containerType) -split ';'
    if ($persistedPaths -contains $Path) {
      $persistedPaths = $persistedPaths | Where-Object { $_ -and $_ -ne $Path }
      [Environment]::SetEnvironmentVariable('Path', $persistedPaths -join ';', $containerType)
    }
  }

  $envPaths = $Env:Path -split ';'
  if ($envPaths -contains $Path) {
    $envPaths = $envPaths | Where-Object { $_ -and $_ -ne $Path }
    $Env:Path = $envPaths -join ';'
  }
}

function Get-Paths {
  [alias('paths')]
  param(
    [Parameter(Mandatory = $false)]
    [ValidateSet('Machine', 'User')]
    [Alias('c')][string]$Container
  )

  if ($PSBoundParameters.Count -eq 0) {
    return $Env:PATH -Split ';'
  }
  else {
    $containerMapping = @{
      Machine = [EnvironmentVariableTarget]::Machine
      User    = [EnvironmentVariableTarget]::User
    }
    $containerType = $containerMapping[$Container]

    [Environment]::GetEnvironmentVariable('Path', $containerType) -split ';' |
    Where-Object { $_ }
  }
}

function New-Symlink {
  [alias('symlink')]
  param (
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$Target,

    [Parameter(Mandatory = $true, Position = 1)]
    [string]$Path
  )

  Write-Host "Creating symbolic link to $Target at $Path..." -ForegroundColor 'Green'
  New-Item -Path $Path -ItemType SymbolicLink -Value $Target
}

function Get-Symlinks {
  [alias('symlinks')]
  param (
    [string]$Path = "$($(Get-Location).Path)",
    [switch]$Recurse,
    [int]$Depth
  )

  Get-ChildItem -Path $Path -Recurse:$Recurse -Depth:$Depth | `
    Where-Object { $_.LinkType -eq 'SymbolicLink' } | `
    Select-Object Mode, LastWriteTime, Name, FullName, LinkTarget, Attributes |`
    Format-Table -AutoSize
}

function Update-Modules {
  param (
    [switch]$AllowPrerelease,

    [switch]$WhatIf,

    [string]$Name = '*',

    [ValidateSet('AllUsers', 'CurrentUser')]
    [string]$Scope = 'CurrentUser'
  )

  if ($Scope -eq 'AllUsers') {
    if ((New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator) -eq $False) {
      Write-Warning "Function $($MyInvocation.MyCommand) needs admin privileges to perform actions."
      break
    }
  }

  $CurrentModules = Get-InstalledModule -Name $Name -ErrorAction SilentlyContinue | Select-Object -Property Name, Version | Sort-Object Name

  if (!$CurrentModules) { Write-Host 'No modules found.' -ForegroundColor Red; return }
  else {
    $i = 1
    $moduleCount = $CurrentModules.Count
    ''; Write-Host "$moduleCount " -ForegroundColor Yellow -NoNewline; Write-Host 'module(s) installed.' -ForegroundColor Green; ''

    if ($AllowPrerelease) { Write-Host 'Trying to update modules to latest ' -ForegroundColor Blue -NoNewline; Write-Host 'prerelease ' -NoNewline -ForegroundColor Magenta; Write-Host 'version' -ForegroundColor Blue }
    else { Write-Host 'Trying to update modules to latest ' -ForegroundColor Blue -NoNewline; Write-Host 'stable ' -NoNewline -ForegroundColor Magenta; Write-Host 'version' -ForegroundColor Blue }

    foreach ($module in $CurrentModules) {
      $OnlineVersion = (Find-Module -Name $($module.Name) -AllVersions | Sort-Object PublishedDate -Descending)[0].Version
      $CurrentVersion = (Get-InstalledModule -Name $($module.Name)).Version

      if ($CurrentVersion -ne $OnlineVersion) {
        try {
          Update-Module -Name $($module.Name) -AllowPrerelease:$AllowPrerelease -Scope:$Scope -Force:$True -WhatIf:$WhatIf.IsPresent
        }
        catch {
          Write-Error "Error occurred while updating module $($module.Name): $_"
        }
      }

      [int]$percentCompleted = ($i / $moduleCount) * 100
      Write-Progress -Activity "Updating Module $($module.Name)" -Status "$percentCompleted% Completed - $($module.Name) v$OnlineVersion" -PercentComplete $percentCompleted
      $i++
    }
    if ($?) { Write-Host 'Everything is up-to-date!' -ForegroundColor Green }
  }
}
function Get-IPAddress {
  [alias('ip')]
  param (
    [Alias('external', 'global', 'g')][switch]$Public,
    [Alias('internal', 'local', 'l')][switch]$Private,
    [Alias('i')][switch]$Interactive
  )

  $LogoPath = "$Env:PWSH\lib\Assets\global-network.png"
  $PublicIp = (Invoke-WebRequest 'http://icanhazip.com' -UseBasicParsing -DisableKeepAlive).Content.Trim()
  $PrivateIp = (Get-WmiObject -Class Win32_NetworkAdapterConfiguration | Where-Object { $null -ne $_.DHCPEnabled -and $null -ne $_.DefaultIPGateway }).IPAddress | Select-Object -First 1

  if ($Public) {
    if ($Interactive) { New-BurntToastNotification -AppLogo $LogoPath -Silent -Text 'Public IP Address: ', "`u{1F60A}  $PublicIp" }
    else { Write-Host 'Public IP Address: ' -ForegroundColor Green; Write-Host "`u{1F310}  $PublicIp" }
  }

  elseif ($Private) {
    if ($Interactive) { New-BurntToastNotification -AppLogo $LogoPath -Silent -Text 'Private IP Address: ', "`u{1F60A}  $PrivateIp" }
    else { Write-Host 'Private IP Address: ' -ForegroundColor Green; Write-Host "`u{1F310}  $PrivateIp" }
  }

  else {
    $ToastButton = New-BTButton -Dismiss -Content 'Close'
    New-BurntToastNotification -AppLogo $LogoPath -Button $ToastButton -Silent -Text "Public IP:  $PublicIp", "Private IP:  $PrivateIp"
  }
}
