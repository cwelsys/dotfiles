# Bitwarden Implementation Guide

This guide provides detailed implementation instructions for integrating Bitwarden with chezmoi.

## Prerequisites

- Bitwarden CLI (`bw`)
- PowerShell 7+
- Chezmoi
- Windows Credential Manager

## Bitwarden CLI Installation

The setup script will need to install the Bitwarden CLI if not already present:

```powershell
# Check if Bitwarden CLI is installed
if (!(Get-Command bw -ErrorAction SilentlyContinue)) {
    Write-Host "Installing Bitwarden CLI..."
    scoop install bitwarden-cli
}
```

## Bitwarden Authentication Flow

### 1. First-time Authentication

```powershell
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
            $credential = New-Object System.Management.Automation.PSCredential("BitwardenSession", (ConvertTo-SecureString $loginResult -AsPlainText -Force))
            [System.Management.Automation.PSCredential]::new("BitwardenSession", (ConvertTo-SecureString $loginResult -AsPlainText -Force)) |
                Export-Clixml -Path "$env:USERPROFILE\.config\bitwarden-session.xml"

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
            $credential = New-Object System.Management.Automation.PSCredential("BitwardenSession", (ConvertTo-SecureString $unlockResult -AsPlainText -Force))
            [System.Management.Automation.PSCredential]::new("BitwardenSession", (ConvertTo-SecureString $unlockResult -AsPlainText -Force)) |
                Export-Clixml -Path "$env:USERPROFILE\.config\bitwarden-session.xml"

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
```

### 2. Secret Retrieval Functions

```powershell
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
```

## Integration with Chezmoi Templates

Create a template function file at `.chezmoitemplates/bitwarden.tmpl`:

```
{{- /* bitwarden returns a value from Bitwarden */ -}}
{{- define "bitwarden" -}}
{{- $itemName := index . 0 -}}
{{- $fieldName := index . 1 -}}
{{- $output := onepasswordItemFields $itemName -}}
{{- if has $fieldName $output -}}
{{- index $output $fieldName -}}
{{- else -}}
{{- "" -}}
{{- end -}}
{{- end -}}
```

## Example Usage in Templates

```
# Example .gitconfig.tmpl
[user]
    email = {{ template "bitwarden" (list "Git Config" "email") }}
    name = {{ template "bitwarden" (list "Git Config" "name") }}

[github]
    token = {{ template "bitwarden" (list "GitHub" "token") }}
```

## Bitwarden Item Structure

### Folder Structure

- Create a folder named "Environment Variables" in Bitwarden
- Create a folder named "API Keys" in Bitwarden
- Create a folder named "Dotfiles" in Bitwarden

### Item Structure

For environment variables:

- Item Type: Secure Note
- Name: The environment variable name (e.g., "GITHUB_TOKEN")
- Field "value": The environment variable value

For API keys:

- Item Type: Secure Note or Login
- Name: Descriptive name (e.g., "GitHub API")
- Field "token": The API token
- Field "username": API username (if applicable)

For configuration values:

- Item Type: Secure Note
- Name: Config name (e.g., "Git Config")
- Fields for each config value (e.g., "email", "name")
