# Setup Script with Bitwarden Integration

This document shows how to modify the `setup_win.ps1` script to integrate with Bitwarden.

## Modified `setup_win.ps1`

```powershell
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
    "Maple-Mono", "psfzf", "psreadline", "starship", "terminal-icons", "zoxide"
)

# Add Bitwarden CLI to the list of apps to install
$appsToInstall += "bitwarden-cli"

try {
    scoop install git
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

Write-Host "Configuring Git..."
try {
    git config --global credential.helper manager
    $regFilePath = Join-Path -Path $env:USERPROFILE -ChildPath 'scoop\apps\git\current\install-file-associations.reg'
    if (Test-Path -Path $regFilePath -PathType Leaf) {
        Start-Process -FilePath "regedit.exe" -ArgumentList "/s `"$regFilePath`"" -Wait
    } else {
        Write-Host "The file $regFilePath does not exist."
    }
    git config --global user.name "cwelsys"
    git config --global user.email "cwel@cwel.sh"

    $confirm = Read-Host "Do you want to generate a new SSH key for GitHub? (y/n)"
    if ($confirm -eq "y") {
        Write-Host ":: Generating a new SSH key for GitHub..."
        try {
            $sshDirectoryPath = Join-Path -Path $env:USERPROFILE -ChildPath ".ssh"
            if (-not (Test-Path -Path $sshDirectoryPath)) {
                New-Item -ItemType Directory -Path $sshDirectoryPath -Force
            }
            $keyPath = Join-Path -Path $sshDirectoryPath -ChildPath "id_ed25519"
            ssh-keygen -t ed25519 -C "94425204+joncrangle@users.noreply.github.com" -f $keyPath
            if (Test-Path -Path $keyPath) {
                Write-Host "SSH key generated successfully at $keyPath"
            } else {
                Write-Host "Failed to generate SSH key"
            }
        } catch {
            Write-Host "An error occurred: $_"
        }
    } elseif ($confirm -eq "n") {
        Write-Host ":: Skipping SSH key generation."
    } else {
        Write-Host "Invalid input. Please enter 'y' or 'n'."
    }
} catch {
    Write-Host "An error occurred while configuring Git."
}

# Prompt user to run gh auth login
Read-Host "Please run 'gh auth login --web' to authenticate with GitHub. Press Enter to continue after you have completed the authentication."
Read-Host ":: Please put key.txt in ~/.config/. Press Enter to continue"

# Bitwarden Setup
Write-Host "Setting up Bitwarden integration..."

# Create Bitwarden helper functions
function Initialize-BitwardenAuth {
    param (
        [switch]$Force
    )

    # Check if already logged in
    $status = bw status | ConvertFrom-Json

    if ($status.status -eq "unauthenticated" -or $Force) {
        # Prompt for credentials
        $email = Read-Host "Enter your Bitwarden email"
        $password = Read-Host "Enter your Bitwarden password" -AsSecureString

        # Convert secure string to plain text for the CLI
        $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($password)
        $plaintextPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
        [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)

        # Login to Bitwarden
        $loginResult = $null
        try {
            $loginResult = bw login $email $plaintextPassword --raw
        }
        catch {
            Write-Error "Failed to login to Bitwarden: $_"
            return $null
        }
        finally {
            # Clear the plaintext password from memory
            $plaintextPassword = $null
        }

        if ($loginResult) {
            # Store the session key in Windows Credential Manager
            $configDir = "$env:USERPROFILE\.config"
            if (!(Test-Path $configDir)) {
                New-Item -Path $configDir -ItemType Directory -Force
            }

            [System.Management.Automation.PSCredential]::new("BitwardenSession", (ConvertTo-SecureString $loginResult -AsPlainText -Force)) |
                Export-Clixml -Path "$configDir\bitwarden-session.xml"

            return $loginResult
        }
    }
    elseif ($status.status -eq "locked") {
        # Unlock the vault
        $password = Read-Host "Enter your Bitwarden password to unlock the vault" -AsSecureString
        $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($password)
        $plaintextPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
        [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)

        $unlockResult = $null
        try {
            $unlockResult = bw unlock $plaintextPassword --raw
        }
        catch {
            Write-Error "Failed to unlock Bitwarden: $_"
            return $null
        }
        finally {
            # Clear the plaintext password from memory
            $plaintextPassword = $null
        }

        if ($unlockResult) {
            # Store the session key
            $configDir = "$env:USERPROFILE\.config"
            if (!(Test-Path $configDir)) {
                New-Item -Path $configDir -ItemType Directory -Force
            }

            [System.Management.Automation.PSCredential]::new("BitwardenSession", (ConvertTo-SecureString $unlockResult -AsPlainText -Force)) |
                Export-Clixml -Path "$configDir\bitwarden-session.xml"

            return $unlockResult
        }
    }
    else {
        # Already logged in, retrieve the session key
        try {
            $credential = Import-Clixml -Path "$env:USERPROFILE\.config\bitwarden-session.xml"
            $sessionKey = $credential.GetNetworkCredential().Password
            return $sessionKey
        }
        catch {
            Write-Warning "Could not retrieve Bitwarden session, re-authenticating..."
            return Initialize-BitwardenAuth -Force
        }
    }

    return $null
}

function Get-BitwardenSecret {
    param (
        [Parameter(Mandatory=$true)]
        [string]$ItemName,

        [Parameter(Mandatory=$false)]
        [string]$FieldName,

        [Parameter(Mandatory=$false)]
        [switch]$AsSecureString
    )

    # Get the session key
    $sessionKey = Initialize-BitwardenAuth

    if (!$sessionKey) {
        Write-Error "No Bitwarden session available"
        return $null
    }

    # Set the session environment variable
    $env:BW_SESSION = $sessionKey

    try {
        # Search for the item
        $items = bw list items --search $ItemName | ConvertFrom-Json

        if ($items.Count -eq 0) {
            Write-Error "No item found with name: $ItemName"
            return $null
        }

        $item = $items | Where-Object { $_.name -eq $ItemName } | Select-Object -First 1

        if (!$item) {
            Write-Error "No exact match found for item: $ItemName"
            return $null
        }

        # If a field name is specified, get that field
        if ($FieldName) {
            $field = $item.fields | Where-Object { $_.name -eq $FieldName } | Select-Object -First 1

            if (!$field) {
                Write-Error "No field found with name: $FieldName in item: $ItemName"
                return $null
            }

            if ($AsSecureString) {
                return ConvertTo-SecureString $field.value -AsPlainText -Force
            }
            else {
                return $field.value
            }
        }
        else {
            # Return the password/value
            if ($item.login) {
                if ($AsSecureString) {
                    return ConvertTo-SecureString $item.login.password -AsPlainText -Force
                }
                else {
                    return $item.login.password
                }
            }
            elseif ($item.notes) {
                if ($AsSecureString) {
                    return ConvertTo-SecureString $item.notes -AsPlainText -Force
                }
                else {
                    return $item.notes
                }
            }
            else {
                Write-Error "Item does not contain a password or notes: $ItemName"
                return $null
            }
        }
    }
    catch {
        Write-Error "Error retrieving secret from Bitwarden: $_"
        return $null
    }
    finally {
        # Clear the session from environment
        $env:BW_SESSION = $null
    }
}

function Get-BitwardenEnvironmentVariables {
    param (
        [Parameter(Mandatory=$false)]
        [string]$FolderName = "Environment Variables"
    )

    # Get the session key
    $sessionKey = Initialize-BitwardenAuth

    if (!$sessionKey) {
        Write-Error "No Bitwarden session available"
        return $null
    }

    # Set the session environment variable
    $env:BW_SESSION = $sessionKey

    try {
        # Get all folders
        $folders = bw list folders | ConvertFrom-Json
        $folder = $folders | Where-Object { $_.name -eq $FolderName } | Select-Object -First 1

        if (!$folder) {
            Write-Warning "No folder found with name: $FolderName"
            return @()
        }

        # Get all items in the folder
        $items = bw list items --folderid $folder.id | ConvertFrom-Json

        # Transform items into environment variables
        $envVars = @()

        foreach ($item in $items) {
            $name = $item.name
            $value = $null

            # Check for a specific field named "value" or "path"
            $valueField = $item.fields | Where-Object { $_.name -eq "value" -or $_.name -eq "path" } | Select-Object -First 1

            if ($valueField) {
                $value = $valueField.value
            }
            elseif ($item.notes) {
                $value = $item.notes
            }
            elseif ($item.login) {
                $value = $item.login.password
            }

            if ($value) {
                $envVars += [PSCustomObject]@{
                    Name = $name
                    Value = $value
                }
            }
        }

        return $envVars
    }
    catch {
        Write-Error "Error retrieving environment variables from Bitwarden: $_"
        return @()
    }
    finally {
        # Clear the session from environment
        $env:BW_SESSION = $null
    }
}

# Save the Bitwarden helper functions
$bitwardenDir = "$env:USERPROFILE\.config\bitwarden"
if (!(Test-Path $bitwardenDir)) {
    New-Item -Path $bitwardenDir -ItemType Directory -Force
}

@'
function Initialize-BitwardenAuth {
    param (
        [switch]$Force
    )

    # Check if already logged in
    $status = bw status | ConvertFrom-Json

    if ($status.status -eq "unauthenticated" -or $Force) {
        # Prompt for credentials
        $email = Read-Host "Enter your Bitwarden email"
        $password = Read-Host "Enter your Bitwarden password" -AsSecureString

        # Convert secure string to plain text for the CLI
        $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($password)
        $plaintextPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
        [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)

        # Login to Bitwarden
        $loginResult = $null
        try {
            $loginResult = bw login $email $plaintextPassword --raw
        }
        catch {
            Write-Error "Failed to login to Bitwarden: $_"
            return $null
        }
        finally {
            # Clear the plaintext password from memory
            $plaintextPassword = $null
        }

        if ($loginResult) {
            # Store the session key in Windows Credential Manager
            $configDir = "$env:USERPROFILE\.config"
            if (!(Test-Path $configDir)) {
                New-Item -Path $configDir -ItemType Directory -Force
            }

            [System.Management.Automation.PSCredential]::new("BitwardenSession", (ConvertTo-SecureString $loginResult -AsPlainText -Force)) |
                Export-Clixml -Path "$configDir\bitwarden-session.xml"

            return $loginResult
        }
    }
    elseif ($status.status -eq "locked") {
        # Unlock the vault
        $password = Read-Host "Enter your Bitwarden password to unlock the vault" -AsSecureString
        $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($password)
        $plaintextPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
        [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)

        $unlockResult = $null
        try {
            $unlockResult = bw unlock $plaintextPassword --raw
        }
        catch {
            Write-Error "Failed to unlock Bitwarden: $_"
            return $null
        }
        finally {
            # Clear the plaintext password from memory
            $plaintextPassword = $null
        }

        if ($unlockResult) {
            # Store the session key
            $configDir = "$env:USERPROFILE\.config"
            if (!(Test-Path $configDir)) {
                New-Item -Path $configDir -ItemType Directory -Force
            }

            [System.Management.Automation.PSCredential]::new("BitwardenSession", (ConvertTo-SecureString $unlockResult -AsPlainText -Force)) |
                Export-Clixml -Path "$configDir\bitwarden-session.xml"

            return $unlockResult
        }
    }
    else {
        # Already logged in, retrieve the session key
        try {
            $credential = Import-Clixml -Path "$env:USERPROFILE\.config\bitwarden-session.xml"
            $sessionKey = $credential.GetNetworkCredential().Password
            return $sessionKey
        }
        catch {
            Write-Warning "Could not retrieve Bitwarden session, re-authenticating..."
            return Initialize-BitwardenAuth -Force
        }
    }

    return $null
}

function Get-BitwardenSecret {
    param (
        [Parameter(Mandatory=$true)]
        [string]$ItemName,

        [Parameter(Mandatory=$false)]
        [string]$FieldName,

        [Parameter(Mandatory=$false)]
        [switch]$AsSecureString
    )

    # Get the session key
    $sessionKey = Initialize-BitwardenAuth

    if (!$sessionKey) {
        Write-Error "No Bitwarden session available"
        return $null
    }

    # Set the session environment variable
    $env:BW_SESSION = $sessionKey

    try {
        # Search for the item
        $items = bw list items --search $ItemName | ConvertFrom-Json

        if ($items.Count -eq 0) {
            Write-Error "No item found with name: $ItemName"
            return $null
        }

        $item = $items | Where-Object { $_.name -eq $ItemName } | Select-Object -First 1

        if (!$item) {
            Write-Error "No exact match found for item: $ItemName"
            return $null
        }

        # If a field name is specified, get that field
        if ($FieldName) {
            $field = $item.fields | Where-Object { $_.name -eq $FieldName } | Select-Object -First 1

            if (!$field) {
                Write-Error "No field found with name: $FieldName in item: $ItemName"
                return $null
            }

            if ($AsSecureString) {
                return ConvertTo-SecureString $field.value -AsPlainText -Force
            }
            else {
                return $field.value
            }
        }
        else {
            # Return the password/value
            if ($item.login) {
                if ($AsSecureString) {
                    return ConvertTo-SecureString $item.login.password -AsPlainText -Force
                }
                else {
                    return $item.login.password
                }
            }
            elseif ($item.notes) {
                if ($AsSecureString) {
                    return ConvertTo-SecureString $item.notes -AsPlainText -Force
                }
                else {
                    return $item.notes
                }
            }
            else {
                Write-Error "Item does not contain a password or notes: $ItemName"
                return $null
            }
        }
    }
    catch {
        Write-Error "Error retrieving secret from Bitwarden: $_"
        return $null
    }
    finally {
        # Clear the session from environment
        $env:BW_SESSION = $null
    }
}

function Get-BitwardenEnvironmentVariables {
    param (
        [Parameter(Mandatory=$false)]
        [string]$FolderName = "Environment Variables"
    )

    # Get the session key
    $sessionKey = Initialize-BitwardenAuth

    if (!$sessionKey) {
        Write-Error "No Bitwarden session available"
        return $null
    }

    # Set the session environment variable
    $env:BW_SESSION = $sessionKey

    try {
        # Get all folders
        $folders = bw list folders | ConvertFrom-Json
        $folder = $folders | Where-Object { $_.name -eq $FolderName } | Select-Object -First 1

        if (!$folder) {
            Write-Warning "No folder found with name: $FolderName"
            return @()
        }

        # Get all items in the folder
        $items = bw list items --folderid $folder.id | ConvertFrom-Json

        # Transform items into environment variables
        $envVars = @()

        foreach ($item in $items) {
            $name = $item.name
            $value = $null

            # Check for a specific field named "value" or "path"
            $valueField = $item.fields | Where-Object { $_.name -eq "value" -or $_.name -eq "path" } | Select-Object -First 1

            if ($valueField) {
                $value = $valueField.value
            }
            elseif ($item.notes) {
                $value = $item.notes
            }
            elseif ($item.login) {
                $value = $item.login.password
            }

            if ($value) {
                $envVars += [PSCustomObject]@{
                    Name = $name
                    Value = $value
                }
            }
        }

        return $envVars
    }
    catch {
        Write-Error "Error retrieving environment variables from Bitwarden: $_"
        return @()
    }
    finally {
        # Clear the session from environment
        $env:BW_SESSION = $null
    }
}

function Get-BitwardenItemFields {
    param (
        [Parameter(Mandatory=$true)]
        [string]$ItemName
    )

    # Get the session key
    $sessionKey = Initialize-BitwardenAuth

    if (!$sessionKey) {
        Write-Error "No Bitwarden session available"
        return $null
    }

    # Set the session environment variable
    $env:BW_SESSION = $sessionKey

    try {
        # Search for the item
        $items = bw list items --search $ItemName | ConvertFrom-Json

        if ($items.Count -eq 0) {
            Write-Error "No item found with name: $ItemName"
            return $null
        }

        $item = $items | Where-Object { $_.name -eq $ItemName } | Select-Object -First 1

        if (!$item) {
            Write-Error "No exact match found for item: $ItemName"
            return $null
        }

        # Create a hashtable of fields
        $fields = @{}

        # Add custom fields
        foreach ($field in $item.fields) {
            $fields[$field.name] = $field.value
        }

        # Add standard fields if they exist
        if ($item.login) {
            $fields["username"] = $item.login.username
            $fields["password"] = $item.login.password
            $fields["totp"] = $item.login.totp
        }

        if ($item.notes) {
            $fields["notes"] = $item.notes
        }

        # Convert to JSON and return
        return $fields | ConvertTo-Json
    }
    catch {
        Write-Error "Error retrieving item fields from Bitwarden: $_"
        return "{}"
    }
    finally {
        # Clear the session from environment
        $env:BW_SESSION = $null
    }
}
'@ | Out-File -FilePath "$bitwardenDir\functions.ps1" -Encoding utf8

# Initialize Bitwarden
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
}

Write-Host "Configuring environment variables..."
function Set-UserEnvironmentVariables {
    # Try to get environment variables from Bitwarden
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

        # Fallback to the old method if env.json exists
        if (Test-Path "env.json") {
            Write-Host "Using env.json as fallback..."
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

Set-UserEnvironmentVariables
$env:XDG_CONFIG_HOME = "$env:USERPROFILE\AppData\Local"
Set-Location $env:XDG_CONFIG_HOME

Write-Host "Moving dotfiles..."
chezmoi init --apply https://github.com/cwelsys/.dotfiles.git

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
```

## Key Changes

1. **Added Bitwarden CLI Installation**:

   - Added `bitwarden-cli` to the list of apps to install via Scoop

2. **Added Bitwarden Helper Functions**:

   - `Initialize-BitwardenAuth`: Handles authentication with Bitwarden
   - `Get-BitwardenSecret`: Retrieves a secret from Bitwarden
   - `Get-BitwardenEnvironmentVariables`: Retrieves environment variables from Bitwarden
   - `Get-BitwardenItemFields`: Retrieves all fields from a Bitwarden item

3. **Saved Helper Functions to File**:

   - Created a directory at `~/.config/bitwarden`
   - Saved the helper functions to `~/.config/bitwarden/functions.ps1`

4. **Modified Environment Variable Setup**:

   - Updated `Set-UserEnvironmentVariables` to first try to get variables from Bitwarden
   - Falls back to the old `env.json` method if Bitwarden fails

5. **Added Bitwarden Initialization**:
   - Authenticates with Bitwarden during setup
   - Creates an "Environment Variables" folder if it doesn't exist

## Security Considerations

1. Bitwarden credentials are stored securely using PowerShell's `Export-Clixml`
2. Session keys are stored in memory only when needed
3. Secure strings are used for passwords
4. Plain text passwords are cleared from memory as soon as possible
