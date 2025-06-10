Remove-Item Alias:rm -Force -ErrorAction SilentlyContinue

Set-Alias -Name 'whic' -Value Get-CommandInfo -Description "Shows command information (intentional typo to avoid conflict with 'which' command)"

Set-Alias -Name 'rl' -Value Import-Profile -Description "Reloads PowerShell profile"

Set-Alias -Name 'rst' -Value restart -Description "Restarts current PowerShell session"

Set-Alias -Name 'vim' -Value nvim -Description "Opens Neovim editor"

Set-Alias -Name 'su' -Value gsudo -Description "Runs command with admin privileges"

Set-Alias -Name 'vi' -Value nvim -Description "Opens Neovim editor (alternative)"

Set-Alias -Name 'c' -Value clear -Description "Clears the console screen"

Set-Alias -Name 'df' -Value Get-Volume -Description "Displays volume information"

Set-Alias -Name 'cat' -Value Invoke-Bat -Option AllScope -Force -Description "Uses bat as cat replacement with options"

Set-Alias -Name 'komorel' -Value Invoke-Komorebirl -Description "Restarts Komorebi window manager"

Set-Alias -Name 'sarc' -Value Invoke-Sarcastaball -Description "Converts text to Spongebob-case"

Set-Alias -Name 'ipg' -Value Get-IPLocation -Description "Gets location information for an IP address"

Set-Alias -Name 'mg' -Value magick -Description "Shortcut for ImageMagick's magick command"

Set-Alias -Name 'deltmp' -Value Remove-TempData -Description "Cleans temporary file directories"

Set-Alias -Name 'npm-ls' -Value Get-NpmGlobalPackages -Description "Lists globally installed NPM packages"

Set-Alias -Name 'bun-ls' -Value Get-BunGlobalPackages -Description "Lists globally installed Bun packages"

Set-Alias -Name 'pnpm-ls' -Value Get-PnpmGlobalPackages -Description "Lists globally installed PNPM packages"

Set-Alias -Name 'cm' -Value chezmoi -Description "Shortcut for chezmoi dotfiles manager"

Set-Alias -Name "md5" -Value Get-FileHashMD5 -Description "Calculates the MD5 hash of an input."

Set-Alias -Name "sha1" -Value Get-FileHashSHA1 -Description "Calculates the SHA1 hash of an input."

Set-Alias -Name "sha256" -Value Get-FileHashSHA256 -Description "Calculates the SHA256 hash of an input."

Set-Alias -Name "GET" -Value Invoke-RestMethodGet -Description "Sends a GET http request."

Set-Alias -Name "HEAD" -Value Invoke-RestMethodHead -Description "Sends a HEAD http request."

Set-Alias -Name "POST" -Value Invoke-RestMethodPost -Description "Sends a POST http request."

Set-Alias -Name "PUT" -Value Invoke-RestMethodPut -Description "Sends a PUT http request."

Set-Alias -Name "DELETE" -Value Invoke-RestMethodDelete -Description "Sends a DELETE http request."

Set-Alias -Name "TRACE" -Value Invoke-RestMethodTrace -Description "Sends a TRACE http request."

Set-Alias -Name "OPTIONS" -Value Invoke-RestMethodOptions -Description "Sends an OPTIONS http request."

Set-Alias -Name "keys" -value Get-PSReadLineKeyHandler

Set-Alias -Name 'lg' -Value lazygit

Set-Alias -Name 'lzd' -Value lazydocker

Set-Alias -Name 'tg' -Value topgrade
function dots { Set-Location $env:DOTFILES }
function qq { exit }
function cdcm { Set-Location $env:DOTFILES }
function cdc { Set-Location $env:XDG_CONFIG_HOME }
function export($name, $value) {
  Set-Item -Path "env:$name" -Value $value
}
function lock { Invoke-Command { rundll32.exe user32.dll, LockWorkStation } }
function hibernate { shutdown.exe /h }
function shutdown { Stop-Computer }
function reboot { Restart-Computer }
function HKLM { Set-Location HKLM: }
function HKCU { Set-Location HKCU: }
function envs { Get-ChildItem Env: }
function paths { $env:PATH -Split ';' }
function e { Invoke-Item . }
function fdns { ipconfig /flushdns }
function rdns { ipconfig /release }
function ddns { ipconfig /displaydns }
function sysinfo { if (Get-Command fastfetch -ErrorAction SilentlyContinue) { fastfetch -c all } else { Get-ComputerInfo } }
function profiles { Get-PSProfile { $_.exists -eq "True" } | Format-List }
function restart { Get-Process -Id $PID | Select-Object -ExpandProperty Path | ForEach-Object { Invoke-Command { & "$_" } -NoNewScope } }
function getnf { Invoke-NerdFontInstaller }
function Invoke-Bat {
  param([Parameter(ValueFromRemainingArguments = $true)]$args)
  & (Get-Command bat).Source --paging=never --style=plain @args
}
function Get-NpmGlobalPackages { (npm ls -g | Select-Object -skip 1).Trim().Split() | ForEach-Object { if ($_ -match [regex]::Escape("@")) { Write-Output $_ } } }
function Get-BunGlobalPackages { (bun pm ls -g | Select-Object -Skip 1).Trim().Split() | ForEach-Object { if ($_ -match [regex]::Escape("@")) { Write-Output $_ } } }
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
  } else {
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
  [System.IO.File]::ReadAllText("$Env:PWSH\fortune.txt") -replace "`r`n", "`n" -split "`n%`n" | Get-Random
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
  Write-Color "Deleting temp data..." -Color Gray

  $path1 = "C" + ":\Windows\Temp"
  Get-ChildItem $path1 -Force -Recurse -ErrorAction SilentlyContinue | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue

  $path2 = "C" + ":\Windows\Prefetch"
  Get-ChildItem $path2 -Force -Recurse -ErrorAction SilentlyContinue | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue

  $path3 = "C" + ":\Users\*\AppData\Local\Temp"
  Get-ChildItem $path3 -Force -Recurse -ErrorAction SilentlyContinue | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue

  Write-Color "Temp data deleted successfully." -Color Green
}

function Update-PowerShell {
  try {
    Write-Host "Checking for PowerShell updates..." -ForegroundColor Cyan
    $updateNeeded = $false
    $currentVersion = $PSVersionTable.PSVersion.ToString()
    $gitHubApiUrl = "https://api.github.com/repos/PowerShell/PowerShell/releases/latest"
    $latestReleaseInfo = Invoke-RestMethod -Uri $gitHubApiUrl
    $latestVersion = $latestReleaseInfo.tag_name.Trim('v')
    if ($currentVersion -lt $latestVersion) {
      $updateNeeded = $true
    }

    if ($updateNeeded) {
      Write-Host "Updating PowerShell..." -ForegroundColor Yellow
      Start-Process powershell.exe -ArgumentList "-NoProfile -Command winget upgrade Microsoft.PowerShell --accept-source-agreements --accept-package-agreements" -Wait -NoNewWindow
      Write-Host "PowerShell has been updated. Please restart your shell to reflect changes" -ForegroundColor Magenta
    } else {
      Write-Host "Your PowerShell is up to date." -ForegroundColor Green
    }
  } catch {
    Write-Error "Failed to update PowerShell. Error: $_"
  }
}

function Import-Profile {
  if (Test-Path -Path $PROFILE) { . $PROFILE }
  elseif (Test-Path -Path $PROFILE.CurrentUserAllHosts) { . $PROFILE.CurrentUserAllHosts }
}

function Get-CommandInfo {
  [CmdletBinding()]
  param (
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$Name
  )
  $commandExists = Get-Command $Name -ErrorAction SilentlyContinue
  if ($commandExists) {
    return $commandExists | Select-Object -ExpandProperty Definition
  } else {
    Write-Warning "Command not found: $Name."
    break
  }
}

function Invoke-Sarcastaball {
  [cmdletbinding()]
  param(
    [Parameter(HelpMessage = "provide string" , Mandatory = $true)]
    [string]$Message
  )
  $charArray = $Message.ToCharArray()

  foreach ($char in $charArray) {
    $Var = $(Get-Random) % 2
    if ($var -eq 0) {
      $string = $char.ToString()
      $Upper = $string.ToUpper()
      $output = $output + $Upper
    } else {
      $lower = $char.ToString()
      $output = $output + $lower
    }
  }
  $output
  $output = $null
}

function Invoke-Komorebirl {
  param(
    [switch]$Bar,
    [switch]$Yasb
  )

  Write-Color "Stopping Komorebi & whkd..." -Color Magenta
  komorebic stop --whkd | Out-Null

  Write-Color "Starting Komorebi & whkd..." -Color Blue
  if ($Bar) {
    komorebic start --whkd --bar | Out-Null
  } else {
    komorebic start --whkd | Out-Null
  }
  Write-Color "Komorebi (with whkd) has been restarted successfully." -Color Gray
  if ($Yasb) {
    Write-Color "Reloading Yasb..." -Color Gray
    yasbc reload
  }
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


