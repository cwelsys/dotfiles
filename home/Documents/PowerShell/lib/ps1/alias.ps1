# 🔗 Aliases
Set-Alias -Name 'whicc' -Value Get-CommandInfo # intentional typo
Remove-Item Alias:rm -Force -ErrorAction SilentlyContinue
Set-Alias -Name 'rl' -Value reload
Set-Alias -Name 'rst' -Value restart
Set-Alias -Name 'vim' -Value nvim
Set-Alias -Name 'su' -Value gsudo
Set-Alias -Name 'vi' -Value nvim
Set-Alias -Name 'c' -Value clear
Set-Alias -Name 'df' -Value Get-Volume
Set-Alias -Name 'komorel' -Value Restart-TheThings
Set-Alias -Name 'spongob' -Value Invoke-Spongebob
Set-Alias -Name 'ip -geo' -Value Get-IPLocation
Set-Alias -Name 'npm-ls' -Value 'Get-NpmGlobalPackages'
Set-Alias -Name 'bun-ls' -Value 'Get-BunGlobalPackages'
Set-Alias -Name 'pnpm-ls' -Value 'Get-PnpmGlobalPackages'

if (Get-Command lazygit -ErrorAction SilentlyContinue) {
  Set-Alias -Name 'lg' -Value 'lazygit' -Scope Global -Force
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

function e { Invoke-Item . }
function dots { Set-Location $env:DOTS }
function dotp { Set-Location $env:PWSH }
function home { Set-Location $env:USERPROFILE }
function docs { Set-Location $env:USERPROFILE\Documents }
function dsktp { Set-Location $env:USERPROFILE\Desktop }
function downs { Set-Location $env:USERPROFILE\Downloads }
function HKLM { Set-Location HKLM: }
function HKCU { Set-Location HKCU: }
function fdns { ipconfig /flushdns }
function rdns { ipconfig /release }
function ddns { ipconfig /displaydns }
function yasbrel { yasbc reload }
function lock { Invoke-Command { rundll32.exe user32.dll, LockWorkStation } }
function hibernate { shutdown.exe /h }
function shutdown { Stop-Computer }
function reboot { Restart-Computer }
function sysinfo { if (Get-Command fastfetch -ErrorAction SilentlyContinue) { fastfetch -c all } else { Get-ComputerInfo } }
function paths { $env:PATH -Split ';' }
function envs { Get-ChildItem Env: }
function export($name, $value) {
  Set-Item -Path "env:$name" -Value $value
}
function profiles { Get-PSProfile { $_.exists -eq "True" } | Format-List }

function Get-PSProfile {
  $PROFILE.PSExtended.PSObject.Properties |
  Select-Object Name, Value, @{Name = 'IsExist'; Expression = { Test-Path -Path $_.Value -PathType Leaf } }
}

function fortune {
  [System.IO.File]::ReadAllText("$Env:PWSH\fortune.txt") -replace "`r`n", "`n" -split "`n%`n" | Get-Random
}

function Get-PubIp {
  (Invoke-WebRequest http://ifconfig.me/ip ).Content
}

function deltmp {
  Write-ColorText "{Gray}Deleting temp data..."

  $path1 = "C" + ":\Windows\Temp"
  Get-ChildItem $path1 -Force -Recurse -ErrorAction SilentlyContinue | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue

  $path2 = "C" + ":\Windows\Prefetch"
  Get-ChildItem $path2 -Force -Recurse -ErrorAction SilentlyContinue | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue

  $path3 = "C" + ":\Users\*\AppData\Local\Temp"
  Get-ChildItem $path3 -Force -Recurse -ErrorAction SilentlyContinue | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue

  Write-ColorText "{Green}Temp data deleted successfully."
}
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
function reload {
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

# List NPM (NodeJS) Global Packages
# To export global packages to a file, for-example: `npm-ls > global_packages.txt`
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
