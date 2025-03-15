# NOTE:
#          _.-;;-._
#   '-..-'|   ||   |
#   '-..-'|_.-;;-._|
#   '-..-'|   ||   |
#   '-..-'|_.-''-._|

Write-Host "Setting execution policy..."
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

try {
    Write-Host "Installing PowerShell, Windows Terminal and Windows PowerToys..."
    winget install --id Microsoft.WindowsTerminal -e --scope user
    winget install --id Microsoft.Powershell --source winget --scope user
    winget install Microsoft.PowerToys --source winget --scope user
} catch {
    # Prompt user to install PowerShell and Windows Terminal
    Write-Host "Please install PowerShell (https://apps.microsoft.com/detail/9mz1snwt0n5d?hl=en-US&gl=US), Windows Terminal (https://apps.microsoft.com/detail/9n0dx20hk701?hl=en-US&gl=US) and Windows PowerToys (https://apps.microsoft.com/detail/xp89dcgq3k6vld?hl=en-gb&gl=CA)."
    Write-Host "Once installed, press Enter to continue, or press Escape to exit."
    do {
        $key = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown").VirtualKeyCode
    } until ($key -eq 13 -or $key -eq 27)  # Enter key (13) or Escape key (27)

    if ($key -eq 27) {
        # User pressed Escape, exit the script
        Write-Host "Exiting the script."
        exit
    }
}

Write-Host "Installing Scoop..."
$scoopDir = "$env:USERPROFILE\scoop"
if (!(Test-Path $scoopDir)) {
    Write-Host "Installing Scoop..."
    try {
        Invoke-RestMethod -Uri "https://get.scoop.sh" -ErrorAction Stop | Invoke-Expression
    } catch {
        Write-Host "An error occurred while installing Scoop."
    }
} else {
    Write-Host "Scoop is already installed."
}

Write-Host "Installing terminal apps..."
$appsToInstall = @(
    "age", "chezmoi", "fzf", "gh", "innounp-unicode", "IosevkaTerm-NF",
    "Maple-Mono", "psfzf", "psreadline", "starship", "terminal-icons", "zoxide",
    "bitwarden-cli" # Added Bitwarden CLI
)

try {
    scoop bucket add extras
    scoop bucket add versions
    scoop bucket add nerd-fonts
    scoop update
    foreach ($app in $appsToInstall) {
        scoop install $app
    }
} catch {
    Write-Host "An error occurred while installing one or more terminal apps."
}

# Write-Host "Configuring Git..."
# try {
#     git config --global credential.helper manager
#     $regFilePath = Join-Path -Path $env:USERPROFILE -ChildPath 'scoop\apps\git\current\install-file-associations.reg'
#     if (Test-Path -Path $regFilePath -PathType Leaf) {
#         Start-Process -FilePath "regedit.exe" -ArgumentList "/s `"$regFilePath`"" -Wait
#     } else {
#         Write-Host "The file $regFilePath does not exist."
#     }
#     git config --global user.name "cwelsys"
#     git config --global user.email "cwel@cwel.sh"

#     $confirm = Read-Host "Do you want to generate a new SSH key for GitHub? (y/n)"
#     if ($confirm -eq "y") {
#         Write-Host ":: Generating a new SSH key for GitHub..."
#         try {
#             $sshDirectoryPath = Join-Path -Path $env:USERPROFILE -ChildPath ".ssh"
#             if (-not (Test-Path -Path $sshDirectoryPath)) {
#                 New-Item -ItemType Directory -Path $sshDirectoryPath -Force
#             }
#             $keyPath = Join-Path -Path $sshDirectoryPath -ChildPath "id_ed25519"
#             ssh-keygen -t ed25519 -C "94425204+joncrangle@users.noreply.github.com" -f $keyPath
#             if (Test-Path -Path $keyPath) {
#                 Write-Host "SSH key generated successfully at $keyPath"
#             } else {
#                 Write-Host "Failed to generate SSH key"
#             }
#         } catch {
#             Write-Host "An error occurred: $_"
#         }
#     } elseif ($confirm -eq "n") {
#         Write-Host ":: Skipping SSH key generation."
#     } else {
#         Write-Host "Invalid input. Please enter 'y' or 'n'."
#     }
# } catch {
#     Write-Host "An error occurred while configuring Git."
# }

# Prompt user to run gh auth login
# Read-Host "Please run 'gh auth login --web' to authenticate with GitHub. Press Enter to continue after you have completed the authentication."
# Read-Host ":: Please put key.txt in ~/.config/. Press Enter to continue"

# Setup Bitwarden
Write-Host "Setting up Bitwarden integration..."
$useBitwarden = $false
$confirm = Read-Host "Do you want to use Bitwarden for storing secrets? (y/n)"
if ($confirm -eq "y") {
    $useBitwarden = $true

    # Check if Bitwarden CLI is installed
    if (!(Get-Command bw -ErrorAction SilentlyContinue)) {
        Write-Host "Bitwarden CLI not found. Installing..."
        scoop install bitwarden-cli
    }

    # Create config directory
    $configDir = "$env:USERPROFILE\.config"
    if (!(Test-Path $configDir)) {
        New-Item -Path $configDir -ItemType Directory -Force
    }

    # Initialize Bitwarden
    Write-Host "Initializing Bitwarden..."
    try {
        # Source the Bitwarden functions
        . "$PSScriptRoot\.chezmoitemplates\bitwarden\functions.ps1"

        # Authenticate with Bitwarden
        $sessionKey = Initialize-BitwardenAuth
        if ($sessionKey) {
            Write-Host "Successfully authenticated with Bitwarden"
            $env:BW_SESSION = $sessionKey

            # Check if the Environment Variables folder exists
            $folders = bw list folders | ConvertFrom-Json
            $envVarFolder = $folders | Where-Object { $_.name -eq "Environment Variables" } | Select-Object -First 1

            if (!$envVarFolder) {
                Write-Host "Creating Environment Variables folder in Bitwarden..."
                $folderResult = bw create folder --name "Environment Variables" | ConvertFrom-Json
                if ($folderResult) {
                    Write-Host "Environment Variables folder created successfully"
                }
            }

            # Clear the session from environment
            $env:BW_SESSION = $null
        } else {
            Write-Host "Failed to authenticate with Bitwarden. Environment variables will not be set from Bitwarden."
            $useBitwarden = $false
        }
    } catch {
        Write-Host "Error setting up Bitwarden: $_"
        $useBitwarden = $false
    }
}

Write-Host "Configuring environment variables..."
function Set-UserEnvironmentVariables {
    if ($useBitwarden) {
        # Try to get environment variables from Bitwarden
        Write-Host "Getting environment variables from Bitwarden..."
        . "$PSScriptRoot\.chezmoitemplates\bitwarden\functions.ps1"
        $envVars = Get-BitwardenEnvironmentVariables

        if ($envVars -and $envVars.Count -gt 0) {
            Write-Host "Setting environment variables from Bitwarden..."

            foreach ($variable in $envVars) {
                $variableName = $variable.Name
                $variablePath = $variable.Value

                # Handle absolute paths vs relative paths
                if ([System.IO.Path]::IsPathRooted($variablePath)) {
                    $variableValue = $variablePath
                } else {
                    $variableValue = [System.IO.Path]::Combine($env:USERPROFILE, $variablePath)
                }

                [Environment]::SetEnvironmentVariable($variableName, $variableValue, [EnvironmentVariableTarget]::User)
                Write-Host "Set environment variable: $variableName = $variableValue"
            }
        } else {
            Write-Host "No environment variables found in Bitwarden or failed to retrieve them."
            $useBitwarden = $false
        }
    }

    # Fallback to env.json if Bitwarden is not used or failed
    if (!$useBitwarden) {
        if (Test-Path "env.json") {
            Write-Host "Using env.json for environment variables..."
            $env:SOPS_AGE_KEY_FILE = "C:\Users\cwel\.config\key.txt"
            $envConfig = sops -d env.json | ConvertFrom-Json

            foreach ($variable in $envConfig.environmentVariables) {
                $variableName = $variable.name
                $variablePath = $variable.path

                # Handle absolute paths vs relative paths
                if ([System.IO.Path]::IsPathRooted($variablePath)) {
                    $variableValue = $variablePath
                } else {
                    $variableValue = [System.IO.Path]::Combine($env:USERPROFILE, $variablePath)
                }

                [Environment]::SetEnvironmentVariable($variableName, $variableValue, [EnvironmentVariableTarget]::User)
                Write-Host "Set environment variable: $variableName = $variableValue"
            }
        } else {
            Write-Host "No env.json file found. Skipping environment variable setup."
        }
    }
}

# Set-UserEnvironmentVariables

Write-Host "Moving dotfiles..."
if ($useBitwarden) {
    chezmoi init --apply --data="{\"useBitwarden\": true}" https://github.com/cwelsys/.dotfiles.git
} else {
    chezmoi init --apply --data="{\"useBitwarden\": false}" https://github.com/cwelsys/.dotfiles.git
}

Write-Host "Configuring Windows Terminal..."
try {
    $windowsTerminalDir = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState"
    $settingsJson = "$env:USERPROFILE\.config\windows-terminal\settings.json"
    Copy-Item $settingsJson -Destination $windowsTerminalDir -Force
} catch {
    Write-Host "An error occurred while configuring Windows Terminal."
}

Write-Host "Configuring PowerShell..."
try {
    if (-not (Test-Path $PROFILE)) {
        New-Item -Path $PROFILE -ItemType File -Force
    }
    . $PROFILE
} catch {
    Write-Host "An error occurred while configuring PowerShell: $_"
}

# Install Scoop apps
Write-Host "Installing Scoop apps..."
$packages = @(
    "7zip", "bat", "biome", "bruno", "chafa", "charm-gum", "curl", "delta", "deno", "dbeaver", "diffutils",
    "eza", "fastfetch", "fd", "ffmpeg", "ghostscript", "glow", "go", "gzip", "imagemagick", "JetBrainsMono-NF",
    "jj", "jq", "just", "komorebi", "krita", "lazygit", "lua", "luarocks", "make", "mariadb", "Meslo-NF",
    "mingw", "neovim", "nodejs", "obsidian", "podman", "poppler", "pnpm", "postgresql", "python", "ripgrep",
    "rustup-gnu", "sqlite", "tldr", "topgrade", "tree-sitter", "unar", "unzip", "uv", "vlc", "vcredist2022",
    "vscode", "wezterm", "win32yank", "wget", "whkd", "xh", "yazi", "yq", "zebar", "zig", "zoom"
)

foreach ($package in $packages) {
    try {
        scoop install $package
    } catch {
        Write-Host "An error occurred while installing $package."
    }
}

ya pack -i
ya pack -u
rustup update
rustup component add rust-analyzer
cargo install cargo-update
cargo install cargo-cache
cargo install --locked bacon
go install github.com/jorgerojas26/lazysql@latest
komorebic fetch-asc
jj config set --user user.name "cwelsys"
jj config set --user user.email "cwel@cwel.sh"
@"
`n[ui]
pager = "delta"
editor = "nvim"
diff-editor = ["nvim", "-c", "DiffEditor `$left `$right `$output"]

[ui.diff]
format = "git"
"@ | Out-File -Append -FilePath (jj config path --user) -Encoding utf8

try {
    $regFilePath = "$env:USERPROFILE\scoop\apps\python\current\install-pep-514.reg"
    if (Test-Path $regFilePath) {
        # Import the registry file
        reg import $regFilePath
    } else {
        Write-Error "Registry file for python not found: $regFilePath"
    }
} catch {
    Write-Error "An error occurred: $_"
}

$configDestDir = "$env:USERPROFILE\scoop\persist\btop"
$themesDestDir = "$configDestDir\themes"
if (!(Test-Path -Path $configDestDir)) {
    New-Item -Path $configDestDir -ItemType Directory -Force
}
if (!(Test-Path -Path $themesDestDir)) {
    New-Item -Path $themesDestDir -ItemType Directory -Force
}
Copy-Item -Path "$env:USERPROFILE\.config\btop\btop.conf" -Destination "$configDestDir\btop.conf" -Force
Copy-Item -Path "$env:USERPROFILE\.config\btop\themes\catppuccin_mocha.theme" -Destination "$themesDestDir\catppuccin_mocha.theme" -Force
bat cache --build

$projectPath = "$env:USERPROFILE\.glzr\zebar\bar"
Write-Host "Building zebar bar..."
try {
    Set-Location -Path $projectPath
    git init
    pnpm install
    pnpm build
} catch {
    Write-Host "Failed to run pnpm commands in ${projectPath}: $_"
} finally {
    Set-Location -Path $PSScriptRoot
}

Write-Host "Configuration complete. Please restart the terminal."
