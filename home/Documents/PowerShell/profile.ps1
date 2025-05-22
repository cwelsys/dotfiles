# 👾 Encoding
$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# 🚌 Tls
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# 🌐 Env
$env:DOTS = "$HOME\.local\share\chezmoi\home"
$Env:PWSH = Split-Path (Get-ChildItem $PSScriptRoot | Where-Object FullName -EQ $PROFILE.CurrentUserAllHosts).Target
$Env:LIBS = Join-Path -Path "$Env:PWSH" -ChildPath "lib"

# 🐶 FastFetch
if (Get-Command fastfetch -ErrorAction SilentlyContinue) {
  if ([Environment]::GetCommandLineArgs().Contains("-NonInteractive") -or $Env:TERM_PROGRAM -eq "vscode") {
    Return
  }
  fastfetch
}

# 📝 Editor
if (Get-Command code -ErrorAction SilentlyContinue) { $Env:EDITOR = "code" }
else {
  if (Get-Command nvim -ErrorAction SilentlyContinue) { $Env:EDITOR = "nvim" }
  else { $Env:EDITOR = "notepad" }
}


# 🐚 Prompt
if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
		oh-my-posh init pwsh --config "$HOME\.config\zen.toml" | Invoke-Expression
    $Env:PWSH_GIT_ENABLED = $true
}

# 🤓 git
if (Get-Module -ListAvailable -Name posh-git -ErrorAction SilentlyContinue) {
    Set-Alias -Name 'g' -Value 'git' -Scope Global -Force
    Import-Module posh-git -Global

if (Get-Module -ListAvailable -Name git-aliases -ErrorAction SilentlyContinue) {
  Import-Module git-aliases -Global -DisableNameChecking
}

# 🥣 scoop
if (Get-Command scoop -ErrorAction SilentlyContinue) {
    if ((scoop info scoop-search).Installed) {
        New-Module -Name scoop-search -ScriptBlock { Invoke-Expression (&scoop-search --hook) } | Import-Module -Global
    }
    if ((scoop info scoop-completion).Installed) {
        Import-Module scoop-completion -Global
		}
}

if (Get-InstalledModule -Name "Terminal-Icons" -ErrorAction SilentlyContinue) {
    Import-Module -Name Terminal-Icons -Global
}

# 🦆 yazi
if (Get-Command yazi -ErrorAction SilentlyContinue) {
    New-Module -ScriptBlock {
        function y {
            $tmp = [System.IO.Path]::GetTempFileName()
            yazi $args --cwd-file="$tmp"
            if (-not [String]::IsNullOrEmpty($cwd) -and $cwd -ne $PWD.Path) {
            	Set-Location -LiteralPath $cwd
            }
            Remove-Item -Path $tmp
        }
    } | Import-Module -Global
}

# 🚬 source
foreach ($module in $((Get-ChildItem -Path "$env:LIBS\psm1\*" -Include *.psm1).FullName )) {
    Import-Module "$module" -Global
}
foreach ($file in $((Get-ChildItem -Path "$env:LIBS\ps1\*" -Include *.ps1).FullName)) {
    . "$file"
}

# 🐢 completion
if (Test-Path "$env:LIBS\completions\init.ps1" -PathType Leaf) {
    . "$env:LIBS\completions\init.ps1"
}

# 💤 zoxide
if (Get-Command zoxide -ErrorAction SilentlyContinue) {
$Env:_ZO_DATA_DIR = "$Env:PWSH"
Invoke-Expression (& { (zoxide init powershell --cmd cd | Out-String) })
}
