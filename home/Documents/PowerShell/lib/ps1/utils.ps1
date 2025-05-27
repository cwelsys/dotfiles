# 🔗 Aliases
Set-Alias -Name 'whic' -Value Get-CommandInfo # intentional typo
Remove-Item Alias:rm -Force -ErrorAction SilentlyContinue
Set-Alias -Name 'rl' -Value Reload-Profile
Set-Alias -Name 'rst' -Value restart
Set-Alias -Name 'vim' -Value nvim
Set-Alias -Name 'su' -Value gsudo
Set-Alias -Name 'vi' -Value nvim
Set-Alias -Name 'c' -Value clear
Set-Alias -Name 'df' -Value Get-Volume
Set-Alias -Name 'komorel' -Value Restart-TheThings
Set-Alias -Name 'spongob' -Value Invoke-Spongebob
Set-Alias -Name 'ip -g' -Value Get-IPLocation
Set-Alias -Name 'deltmp' -Value Remove-TempData
Set-Alias -Name 'aliases' -Value Get-Aliases
Set-Alias -Name 'npm-ls' -Value 'Get-NpmGlobalPackages'
Set-Alias -Name 'bun-ls' -Value 'Get-BunGlobalPackages'
Set-Alias -Name 'pnpm-ls' -Value 'Get-PnpmGlobalPackages'
Set-Alias -Name 'dots' -Value '$env:DOTS'
Set-Alias -Name "md5" -Value Get-FileHashMD5 -Description "Calculates the MD5 hash of an input."
Set-Alias -Name "sha1" -Value Get-FileHashSHA1 -Description "Calculates the SHA1 hash of an input."
Set-Alias -Name "sha256" -Value Get-FileHashSHA256 -Description "Calculates the SHA256 hash of an input."
Set-Alias -Name "forecast" -Value Get-WeatherForecast -Description "Displays detailed weather and forecast."
Set-Alias -Name "weather" -Value Get-WeatherCurrent -Description "Displays current weather."
Set-Alias -Name "GET" -Value Invoke-RestMethodGet -Description "Sends a GET http request."
Set-Alias -Name "HEAD" -Value Invoke-RestMethodHead -Description "Sends a HEAD http request."
Set-Alias -Name "POST" -Value Invoke-RestMethodPost -Description "Sends a POST http request."
Set-Alias -Name "PUT" -Value Invoke-RestMethodPut -Description "Sends a PUT http request."
Set-Alias -Name "DELETE" -Value Invoke-RestMethodDelete -Description "Sends a DELETE http request."
Set-Alias -Name "TRACE" -Value Invoke-RestMethodTrace -Description "Sends a TRACE http request."
Set-Alias -Name "OPTIONS" -Value Invoke-RestMethodOptions -Description "Sends an OPTIONS http request."

if (Get-Command lazygit -ErrorAction SilentlyContinue) {
  Set-Alias -Name 'lg' -Value 'lazygit' -Scope Global -Force
}

if (Get-Command topgrade -ErrorAction SilentlyContinue) {
  Set-Alias -Name 'tg' -Value 'topgrade'
}

# 🏖️ Functions

function y {
  $tmp = [System.IO.Path]::GetTempFileName()
  yazi $args --cwd-file="$tmp"
  $cwd = Get-Content -Path $tmp -Encoding UTF8
  if (-not [String]::IsNullOrEmpty($cwd) -and $cwd -ne $PWD.Path) {
    Set-Location -LiteralPath ([System.IO.Path]::GetFullPath($cwd))
  }
  Remove-Item -Path $tmp
}
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
function Get-PubIp {
  (Invoke-WebRequest http://ifconfig.me/ip ).Content
}
function sysinfo { if (Get-Command fastfetch -ErrorAction SilentlyContinue) { fastfetch -c all } else { Get-ComputerInfo } }
function fortune {
  [System.IO.File]::ReadAllText("$Env:PWSH\fortune.txt") -replace "`r`n", "`n" -split "`n%`n" | Get-Random
}
function profiles { Get-PSProfile { $_.exists -eq "True" } | Format-List }

function Get-PSProfile {
  $PROFILE.PSExtended.PSObject.Properties |
  Select-Object Name, Value, @{Name = 'IsExist'; Expression = { Test-Path -Path $_.Value -PathType Leaf } }
}

function Get-Weather {
  <#
    .SYNOP
        Display the current weather and forecast.
    .DESCRIPTION
        Fetches the weather information from https://wttr.in for terminal
        display.
    .PARAMETER Request
        The full URL to the wttr request.
    .PARAMETER Timeout
        The number of seconds to wait for a response.
    .EXAMPLE
        Get-Weather nF 10
    .INPUTS
        System.String
    .OUTPUTS
        System.String
    .LINK
        https://github.com/chubin/wttr.in
    .LINK
        https://wttr.in
    #>
  [CmdletBinding()]
  param(
    [Parameter(
      Mandatory = $false,
      ValueFromPipeline = $true
    )]
    [string]$Request,

    [Parameter(Mandatory = $false)]
    [PSDefaultValue(Help = '10')]
    [int]$Timeout = 10
  )

  begin {
    if ($Request) {
      $Request = '?' + $Request
    }
    $Request = 'https://wttr.in' + $Request
  }

  process {
    $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $headers.Add("Content-Encoding", 'deflate, gzip')
        (Invoke-WebRequest -Uri "$Request" -UserAgent "curl" -Headers $headers -UseBasicParsing -TimeoutSec "$Timeout").content
  }
}

function Get-WeatherForecast {
  <#
    .SYNOPSIS
        Displays detailed weather and forecast.
    .DESCRIPTION
        Fetches the weather information from wttr.in for terminal display.
    .INPUTS
        None
    .OUTPUTS
        System.String
    .LINK
        https://wttr.in
    #>
  [CmdletBinding()]
  param()

  Get-Weather 'F'
}

function Get-WeatherCurrent {
  <#
    .SYNOPSIS
        Displays current weather.
    .DESCRIPTION
        Fetches the weather information from wttr.in for terminal display.
    .INPUTS
        None
    .OUTPUTS
        System.String
    .LINK
        https://wttr.in
    #>
  [CmdletBinding()]
  param()

  Get-Weather 'format=%l:+(%C)+%c++%t+[%h,+%w]'
}

function Remove-TempData {
  Write-ColorText "{Gray}Deleting temp data..."

  $path1 = "C" + ":\Windows\Temp"
  Get-ChildItem $path1 -Force -Recurse -ErrorAction SilentlyContinue | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue

  $path2 = "C" + ":\Windows\Prefetch"
  Get-ChildItem $path2 -Force -Recurse -ErrorAction SilentlyContinue | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue

  $path3 = "C" + ":\Users\*\AppData\Local\Temp"
  Get-ChildItem $path3 -Force -Recurse -ErrorAction SilentlyContinue | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue

  Write-ColorText "{Green}Temp data deleted successfully."
}

function fdns { ipconfig /flushdns }
function rdns { ipconfig /release }
function ddns { ipconfig /displaydns }

function Update-Powershell {
  try {
    Write-ColorText "{Cyan}Checking for PowerShell updates..."

    # Check internet connection to GitHub dynamically
    $githubTest = Test-Connection -ComputerName "github.com" -Count 1 -Quiet
    if (-not $githubTest) {
      Write-ColorText "{Yellow}Cannot connect to GitHub. Please check your internet connection."
      return
    }

    $updateNeeded = $false
    $currentVersion = $PSVersionTable.PSVersion.ToString()
    $githubAPIurl = "https://api.github.com/repos/PowerShell/PowerShell/releases/latest"
    $latestRelease = Invoke-RestMethod -Uri $githubAPIurl
    $latestVersion = $latestRelease.tag_name.Trim('v')

    if ($currentVersion -lt $latestVersion) {
      $updateNeeded = $true
    }

    if ($updateNeeded) {
      Write-ColorText "{Yellow}Updating PowerShell..."
      winget upgrade "Microsoft.PowerShell" --accept-source-agreements --accept-package-agreements
      Write-ColorText "{Magenta}PowerShell has been updated. Please restart your terminal"
    } else {
      Write-ColorText "{Green}PowerShell is up to date."
    }
  } catch {
    Write-ColorText "{Red}Failed to Update Powershell. Error = $_"
  }
}
function Reload-Profile {
  if (Test-Path -Path $PROFILE) { . $PROFILE }
  elseif (Test-Path -Path $PROFILE.CurrentUserAllHosts) { . $PROFILE.CurrentUserAllHosts }
}
function restart { Get-Process -Id $PID | Select-Object -ExpandProperty Path | ForEach-Object { Invoke-Command { & "$_" } -NoNewScope } }

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

function Invoke-Spongebob {
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

function Write-ColorText {
  param ([string]$Text, [switch]$NoNewLine)

  $hostColor = $Host.UI.RawUI.ForegroundColor

  $Text.Split( [char]"{", [char]"}" ) | ForEach-Object { $i = 0; } {
    if ($i % 2 -eq 0) {	Write-Host $_ -NoNewline }
    else {
      if ($_ -in [enum]::GetNames("ConsoleColor")) {
        $Host.UI.RawUI.ForegroundColor = ($_ -as [System.ConsoleColor])
      }
    }
    $i++
  }

  if (!$NoNewLine) { Write-Host }
  $Host.UI.RawUI.ForegroundColor = $hostColor
}

function Restart-TheThings {
  param(
    [switch]$Bar,
    [switch]$Yasb
  )

  Write-ColorText "{Magenta}Stopping Komorebi & whkd..."
  komorebic stop --whkd | Out-Null

  Write-ColorText "{Blue}Starting Komorebi & whkd..."
  if ($Bar) {
    komorebic start --whkd --bar | Out-Null
  } else {
    komorebic start --whkd | Out-Null
  }
  Write-ColorText "{Gray}Komorebi (with whkd) has been restarted successfully."
  if ($Yasb) {
    Write-ColorText "{Gray}Reloading Yasb..."
    yasbc reload
  }
}
function Get-NpmGlobalPackages { (npm ls -g | Select-Object -skip 1).Trim().Split() | ForEach-Object { if ($_ -match [regex]::Escape("@")) { Write-Output $_ } } }
function Get-BunGlobalPackages { (bun pm ls -g | Select-Object -Skip 1).Trim().Split() | ForEach-Object { if ($_ -match [regex]::Escape("@")) { Write-Output $_ } } }
function Get-PnpmGlobalPackages { (pnpm ls -g | Select-Object -Skip 5) | ForEach-Object { $name = $_.Split()[0]; $version = $_.Split()[1]; Write-Output "$name@$version" } }
function Get-IPLocation {
  param([string]$IPaddress = "")

  try {
    if ($IPaddress -eq "" ) { $IPaddress = read-host "Enter IP address to locate" }

    $result = Invoke-RestMethod -Method Get -Uri "http://ip-api.com/json/$IPaddress"
    write-output $result
    return $result
  } catch {
    "⚠️ Error in line $($_.InvocationInfo.ScriptLineNumber): $($Error[0])"
    throw
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

function Get-Aliases {
  <#
    .SYNOPSIS
        Show information of user's defined aliases. Alias: aliases
    #>
  [CmdletBinding()]
  param()

  #requires -Module PSScriptTools
  Get-MyAlias |
  Sort-Object Source, Name |
  Format-Table -Property Name, Definition, Version, Source -AutoSize
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
