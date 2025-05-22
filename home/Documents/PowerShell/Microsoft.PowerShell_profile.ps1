# 👾 Encoding
$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
# 🚌 Tls
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# 📝 Editor
if (Get-Command code -ErrorAction SilentlyContinue) { $Env:EDITOR = "code" }
else {
  if (Get-Command nvim -ErrorAction SilentlyContinue) { $Env:EDITOR = "nvim" }
  else { $Env:EDITOR = "notepad" }
}

# 📦 Imports
Import-Module PSFzf
Import-Module CompletionPredictor
Import-Module Catppuccin

# 😎 Stolye
$Flavor = $Catppuccin['Mocha']

$PSStyle.Formatting.Debug = $Flavor.Sky.Foreground()
$PSStyle.Formatting.Error = $Flavor.Red.Foreground()
$PSStyle.Formatting.ErrorAccent = $Flavor.Blue.Foreground()
$PSStyle.Formatting.FormatAccent = $Flavor.Teal.Foreground()
$PSStyle.Formatting.TableHeader = $Flavor.Rosewater.Foreground()
$PSStyle.Formatting.Verbose = $Flavor.Yellow.Foreground()
$PSStyle.Formatting.Warning = $Flavor.Peach.Foreground()


# 🛠️ Include
foreach ($module in $((Get-ChildItem -Path "C:\Users\cwel\Documents\PowerShell\lib\psm\*" -Include *.psm1).FullName )) {
  Import-Module "$module" -Global
}
foreach ($file in $((Get-ChildItem -Path "C:\Users\cwel\Documents\PowerShell\lib\ps1\*" -Include *.ps1).FullName)) {
  . "$file"
}


# 🦆 yazi
function y {
  $tmp = [System.IO.Path]::GetTempFileName()
  yazi $args --cwd-file="$tmp"
  $cwd = Get-Content -Path $tmp -Encoding UTF8
  if (-not [String]::IsNullOrEmpty($cwd) -and $cwd -ne $PWD.Path) {
    Set-Location -LiteralPath ([System.IO.Path]::GetFullPath($cwd))
  }
  Remove-Item -Path $tmp
}

# 🥣 scoop
Invoke-Expression (&scoop-search --hook)

# git aliases
if (Get-Module -ListAvailable -Name git-aliases -ErrorAction SilentlyContinue) {
  Import-Module git-aliases -Global -DisableNameChecking
}

# 💤 zoxide
Invoke-Expression (& { (zoxide init powershell --cmd cd | Out-String) })

Invoke-Expression (&starship init powershell)

# 🐶 FastFetch
if (Get-Command fastfetch -ErrorAction SilentlyContinue) {
  if ([Environment]::GetCommandLineArgs().Contains("-NonInteractive") -or $Env:TERM_PROGRAM -eq "vscode") {
    Return
  }
  fastfetch
}
