# PowerShell Aliases and Functions
# This file is sourced by profile.ps1

# ============================================================================
# Navigation
# ============================================================================
function .. { Set-Location .. }
function … { Set-Location ../.. }
function …. { Set-Location ../../.. }
function ….. { Set-Location ../../../.. }

# ============================================================================
# Quick Commands
# ============================================================================
Set-Alias -Name c -Value Clear-Host
function qq { exit }

if (Get-Command fastfetch -ErrorAction SilentlyContinue) {
    function cl { Clear-Host; fastfetch }
    function fet { fastfetch }
    function cpu { fastfetch --logo none --structure cpu }
    function gpu { fastfetch --logo none --structure gpu }
    function ram { fastfetch --logo none --structure memory }
    function osinfo { fastfetch --logo none --structure os }
    function sysinfo { fastfetch -c all }
    function mobo { fastfetch --logo none --structure board }
}

# ============================================================================
# Editor
# ============================================================================
if (Get-Command nvim -ErrorAction SilentlyContinue) {
    Set-Alias -Name v -Value nvim
    Set-Alias -Name vi -Value nvim
    Set-Alias -Name vim -Value nvim
}

# ============================================================================
# Common Tool Shortcuts
# ============================================================================
if (Get-Command lazydocker -ErrorAction SilentlyContinue) {
    Set-Alias -Name ld -Value lazydocker
}

if (Get-Command lazygit -ErrorAction SilentlyContinue) {
    Set-Alias -Name lg -Value lazygit
}

if (Get-Command lazyjournal -ErrorAction SilentlyContinue) {
    Set-Alias -Name lj -Value lazyjournal
}

if (Get-Command doggo -ErrorAction SilentlyContinue) {
    Set-Alias -Name dog -Value doggo
    Set-Alias -Name dig -Value doggo
}

if (Get-Command btop -ErrorAction SilentlyContinue) {
    Set-Alias -Name top -Value btop
}

if (Get-Command magick -ErrorAction SilentlyContinue) {
    Set-Alias -Name mg -Value magick
}

if (Get-Command wiremix -ErrorAction SilentlyContinue) {
    Set-Alias -Name wmx -Value wiremix
}

if (Get-Command topgrade -ErrorAction SilentlyContinue) {
    Set-Alias -Name tg -Value topgrade
}

if (Get-Command yt-dlp -ErrorAction SilentlyContinue) {
    Set-Alias -Name yt -Value yt-dlp
}

if (Get-Command claude -ErrorAction SilentlyContinue) {
    Set-Alias -Name cc -Value claude
    function cr { claude --resume }
}

if (Get-Command ghostty -ErrorAction SilentlyContinue) {
    function boo { ghostty +boo }
    function fonts { ghostty +list-fonts }
}

# ============================================================================
# File Operations
# ============================================================================
# Interactive copy/move (confirm before overwrite)
function cp { Copy-Item -Confirm @args }
function mv { Move-Item -Confirm @args }

# rsync-like copy/move with progress
function rcp {
    param([string]$Source, [string]$Destination)
    Copy-Item -Path $Source -Destination $Destination -Recurse -Force -Verbose
}

function rmv {
    param([string]$Source, [string]$Destination)
    Move-Item -Path $Source -Destination $Destination -Force -Verbose
}

# Make file executable (remove read-only flag on Windows)
function x {
    param([string]$File)
    if (Test-Path $File) {
        Set-ItemProperty $File -Name IsReadOnly -Value $false
    }
}

function e { Invoke-Item . }
Set-Alias -Name xo -Value Invoke-Item

# ============================================================================
# Listing (eza)
# ============================================================================
if (Get-Command eza -ErrorAction SilentlyContinue) {
    $ezaParams = '--git --hyperlink --color=always --group-directories-first --icons'
    $ezaIgnore = '-I "NTUSER*|ntuser*|.DS_Store|.idea|.venv|.vs|__pycache__|cache|debug|.git|node_modules|venv"'

    function l { eza $ezaParams.Split() @args }
    function ls { eza $ezaParams.Split() @args }
    function la { eza -a $ezaParams.Split() @args }
    function ll { eza -l $ezaParams.Split() $ezaIgnore.Split() @args }
    function lla { eza -al --header $ezaParams.Split() $ezaIgnore.Split() @args }
    function lo { eza --oneline $ezaParams.Split() @args }
    function l. { eza -a $ezaParams.Split() @args | Select-String "^\." }
}

if (Get-Command tree -ErrorAction SilentlyContinue) {
    Set-Alias -Name lt -Value tree
}

if (Get-Command bat -ErrorAction SilentlyContinue) {
    function cat { bat --paging=never @args }
}

# ============================================================================
# Process Management
# ============================================================================
function psg {
    param([string]$Pattern)
    if (-not $Pattern) {
        Write-Host "Usage: psg <process_name_pattern>"
        return
    }
    Get-Process | Where-Object { $_.ProcessName -match $Pattern }
}

# ============================================================================
# Package Managers
# ============================================================================

# Chezmoi
if (Get-Command chezmoi -ErrorAction SilentlyContinue) {
    Set-Alias -Name cm -Value chezmoi
    function cma { chezmoi add @args }
    function cme { chezmoi edit @args }
    function cmu { chezmoi update @args }
    function cmapl { chezmoi apply @args }
    function cmra { chezmoi re-add @args }
}

function cdc { Set-Location "$HOME/.config" }
function cdcm {
    $dotfiles = if ($env:DOTFILES) { $env:DOTFILES } else { "$HOME\.local\share\chezmoi\home" }
    Set-Location $dotfiles
}

# Python
if (Get-Command python3 -ErrorAction SilentlyContinue) {
    Set-Alias -Name py -Value python3
    function venv { python3 -m venv @args }
} elseif (Get-Command python -ErrorAction SilentlyContinue) {
    Set-Alias -Name py -Value python
    function venv { python -m venv @args }
}

if (Get-Command pip3 -ErrorAction SilentlyContinue) {
    if (-not (Get-Command pip -ErrorAction SilentlyContinue)) {
        Set-Alias -Name pip -Value pip3
    }
}

# Node.js package managers
if (Get-Command npm -ErrorAction SilentlyContinue) {
    function npm-ls { npm list -g }
}

if (Get-Command pnpm -ErrorAction SilentlyContinue) {
    function pnpm-ls { pnpm list -g }
}

if (Get-Command bun -ErrorAction SilentlyContinue) {
    function bun-ls { bun pm ls -g }
}

if (Get-Command go-global-update -ErrorAction SilentlyContinue) {
    function go-ls { go-global-update --dry-runs }
}

# Cargo
if (Get-Command cargo -ErrorAction SilentlyContinue) {
    function cargols { cargo install --list }
}

if (Get-Command cargo-binstall -ErrorAction SilentlyContinue) {
    Set-Alias -Name cargob -Value cargo-binstall
}

# Scoop (Windows package manager)
if (Get-Command scoop -ErrorAction SilentlyContinue) {
    function update { scoop update * }
    function clean { scoop cleanup * }
    function search { scoop search @args }

    function info {
        param([string]$Package)
        if (-not $Package) {
            Write-Host "Usage: info <package_name>"
            return
        }
        scoop info $Package
    }

    function list {
        if ($args.Count -eq 0) {
            scoop list
        } else {
            scoop list | Where-Object { $_.Name -match $args[0] }
        }
    }

    function files {
        param([string]$Package)
        if (-not $Package) {
            Write-Host "Usage: files <package_name>"
            return
        }
        $scoopDir = if ($env:SCOOP) { $env:SCOOP } else { "$HOME\scoop" }
        $appDir = "$scoopDir\apps\$Package\current"
        if (Test-Path $appDir) {
            Get-ChildItem -Path $appDir -Recurse -File | Select-Object -ExpandProperty FullName
        } else {
            Write-Host "Package '$Package' not found or not installed"
        }
    }

    function remove {
        param(
            [string]$Package,
            [switch]$a,  # Remove all matching pattern
            [switch]$p   # Purge (remove with --purge flag)
        )

        if (-not $Package) {
            Write-Host "Usage: remove <package>           - Remove package"
            Write-Host "       remove -a <pattern>        - Remove all packages matching pattern"
            Write-Host "       remove -p <package>        - Purge package (remove persistent data)"
            Write-Host "       remove -a -p <pattern>     - Purge all packages matching pattern"
            return
        }

        if ($a) {
            # Remove all packages matching pattern
            $packages = scoop list | Where-Object { $_.Name -match $Package } | Select-Object -ExpandProperty Name
            if ($packages) {
                foreach ($pkg in $packages) {
                    if ($p) {
                        scoop uninstall --purge $pkg
                    } else {
                        scoop uninstall $pkg
                    }
                }
            } else {
                Write-Host "No packages found matching: $Package"
            }
        } else {
            # Remove single package
            if ($p) {
                scoop uninstall --purge $Package
            } else {
                scoop uninstall $Package
            }
        }
    }

    # Bucket management (like brew tap/untap)
    function bucket {
        param([string]$BucketName, [string]$Repo)
        if (-not $BucketName) {
            scoop bucket list
            return
        }
        if ($Repo) {
            scoop bucket add $BucketName $Repo
        } else {
            scoop bucket add $BucketName
        }
    }

    function unbucket {
        param([string]$BucketName)
        if (-not $BucketName) {
            Write-Host "Usage: unbucket <bucket_name>"
            return
        }
        scoop bucket rm $BucketName
    }

    # Interactive installer with fzf (if available)
    if (Get-Command fzf -ErrorAction SilentlyContinue) {
        function in {
            $installed = scoop list | Select-Object -ExpandProperty Name
            scoop search | Out-String | ForEach-Object {
                $_ -split "`n" | Where-Object { $_ -match '\S' } | ForEach-Object {
                    $name = ($_ -split '\s+')[0]
                    if ($installed -contains $name) {
                        "$_ [32m[installed][0m"
                    } else {
                        $_
                    }
                }
            } | fzf --ansi --multi | ForEach-Object {
                $pkg = ($_ -split '\s+')[0]
                scoop install $pkg
            }
        }

        function re {
            scoop list | Select-Object -ExpandProperty Name | fzf --multi --preview "scoop info {}" | ForEach-Object {
                scoop uninstall $_
            }
        }
    }
}

# ============================================================================
# Docker
# ============================================================================
if (Get-Command docker -ErrorAction SilentlyContinue) {
    Set-Alias -Name d -Value docker
    function dc { docker compose @args }
    function dcu { docker compose up -d --remove-orphans @args }
    function dcd { docker compose down @args }
    function dcs { docker compose stop @args }
    function dcr { docker compose restart @args }
    function dcp { docker compose pull @args }
    function dcre { docker compose down; docker compose up -d --remove-orphans }

    # Docker-based tool shortcuts
    function cscli { docker exec crowdsec cscli @args }
    function occ { docker exec --user www-data nextcloud-aio-nextcloud php occ @args }
    function nc-clear { docker exec -it nextcloud-aio-database psql -U oc_nextcloud -d nextcloud_database -c "TRUNCATE oc_activity;" }

    # Docker inspect IP
    function dip {
        param([string]$ContainerName)
        if (-not $ContainerName) {
            Write-Host "Usage: dip <container_name_or_id>"
            return
        }
        docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $ContainerName
    }
}

if (Get-Command nerdctl -ErrorAction SilentlyContinue) {
    Set-Alias -Name n -Value nerdctl
}

# ============================================================================
# Utilities
# ============================================================================
if (Get-Command jq -ErrorAction SilentlyContinue) {
    function jq { & jq.exe -C @args }
    function jl { & jq.exe -C @args | less }
}

# ============================================================================
# PowerShell-specific Aliases
# ============================================================================
Set-Alias -Name os -Value Out-String
function keys { Get-PSReadLineKeyHandler }
Set-Alias -Name clip -Value Set-Clipboard
Set-Alias -Name psget -Value Install-Module
Set-Alias -Name json -Value ConvertTo-Json
Set-Alias -Name unjson -Value ConvertFrom-Json

# HTTP REST Methods
function GET { Invoke-RestMethod -Method Get @args }
function HEAD { Invoke-RestMethod -Method Head @args }
function POST { Invoke-RestMethod -Method Post @args }
function PUT { Invoke-RestMethod -Method Put @args }
function DELETE { Invoke-RestMethod -Method Delete @args }
function TRACE { Invoke-RestMethod -Method Trace @args }
function OPTIONS { Invoke-RestMethod -Method Options @args }

# ============================================================================
# Windows-specific Shortcuts
# ============================================================================

# Launch WSL shells
if (Get-Command wsl.exe -ErrorAction SilentlyContinue) {
    function zsh { wsl.exe -e zsh }
    function fish { wsl.exe -e fish }
}

# Sudo equivalent (gsudo)
if (Get-Command gsudo -ErrorAction SilentlyContinue) {
    Set-Alias -Name s -Value gsudo
    Set-Alias -Name su -Value gsudo

    function se {
        param([string]$File)
        if (-not $File) {
            Write-Host "Usage: se <file>"
            return
        }
        gsudo nvim $File
    }
}

# Windows utilities
function winutil { iwr -useb https://christitus.com/win | iex }
function getnf { & ([scriptblock]::Create((iwr 'https://to.loredo.me/Install-NerdFont.ps1'))) }
function ms-activate { irm https://get.activated.win | iex }

# ============================================================================
# Shell Reload
# ============================================================================
function rl {
    Import-Profile
}
