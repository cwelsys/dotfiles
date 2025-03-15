function Set-BitwardenPermanentAuth {
    param (
        [string]$SessionKeyPath = "$env:USERPROFILE\.bw_session"
    )

    # Ensure Bitwarden CLI is installed
    if (-not (Get-Command "bw" -ErrorAction SilentlyContinue)) {
        Write-Error "Bitwarden CLI (bw) is not installed. Please install it first."
        return $false
    }

    # Handle existing session file with permission issues
    if (Test-Path $SessionKeyPath) {
        Write-Host "Found existing session file. Checking access..." -ForegroundColor Cyan
        try {
            $sessionKey = Get-Content -Path $SessionKeyPath -Raw -ErrorAction Stop

            # Set the session key and test if it's still valid
            $env:BW_SESSION = $sessionKey
            $status = bw status | ConvertFrom-Json

            if ($status.status -eq "unlocked") {
                Write-Host "Existing Bitwarden session is valid. Using existing session." -ForegroundColor Green

                # Still set the environment variable for persistence
                [System.Environment]::SetEnvironmentVariable("BW_SESSION", $sessionKey, [System.EnvironmentVariableTarget]::User)

                # Verify access
                $testResult = bw list items --limit 1 2>$null
                if ($testResult) {
                    Write-Host "Bitwarden authentication is working correctly." -ForegroundColor Green
                    return $true
                }
            }
        } catch {
            Write-Host "Cannot access session file: $_" -ForegroundColor Red
            Write-Host "Removing old session file and creating a new one..." -ForegroundColor Yellow

            try {
                # Try to take ownership and delete
                takeown /F $SessionKeyPath /A
                icacls $SessionKeyPath /grant:r "$env:USERNAME:(F)"
                Remove-Item -Path $SessionKeyPath -Force -ErrorAction SilentlyContinue
            } catch {
                Write-Host "Failed to remove old session file. Please delete it manually: $SessionKeyPath" -ForegroundColor Red
            }
        }
    }

    # Check current login status
    $status = bw status | ConvertFrom-Json

    # If already logged in, try to get a new session key directly
    if ($status.status -ne "unauthenticated") {
        Write-Host "Already logged in as $($status.userEmail). Requesting new session key..." -ForegroundColor Cyan

        # Prompt for master password to unlock
        $securePassword = Read-Host "Enter your Bitwarden master password" -AsSecureString
        $bstrPassword = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePassword)
        $masterPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstrPassword)
        [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstrPassword)

        # Get a new session key by unlocking
        $sessionKey = bw unlock $masterPassword --raw

        if ($sessionKey) {
            # Success! Save the session key
            $env:BW_SESSION = $sessionKey

            # Save to file with proper permissions
            try {
                $sessionKey | Out-File -FilePath $SessionKeyPath -Encoding utf8 -Force -ErrorAction Stop

                # Set restrictive permissions
                icacls $SessionKeyPath /inheritance:r
                icacls $SessionKeyPath /grant:r "$env:USERNAME:(R)"

                # Save in environment variable
                [System.Environment]::SetEnvironmentVariable("BW_SESSION", $sessionKey, [System.EnvironmentVariableTarget]::User)

                Write-Host "Bitwarden session saved and configured successfully!" -ForegroundColor Green
                return $true
            } catch {
                Write-Host "Failed to save session file: $_" -ForegroundColor Red
                Write-Host "Session is active for this session only." -ForegroundColor Yellow
            }
        } else {
            Write-Host "Failed to unlock vault. Trying to log out and in again..." -ForegroundColor Yellow
            bw logout
            Start-Sleep -Seconds 2
        }
    }

    # If we get here, we need to log in from scratch
    Write-Host "Logging in to Bitwarden..." -ForegroundColor Cyan

    # Interactive login (no hardcoded credentials)
    bw login

    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to log in to Bitwarden."
        return $false
    }

    # Unlock the vault and get the session key
    Write-Host "Unlocking Bitwarden vault..." -ForegroundColor Cyan
    $securePassword = Read-Host "Enter your master password again to unlock the vault" -AsSecureString
    $bstrPassword = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePassword)
    $masterPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstrPassword)
    [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstrPassword)

    $sessionKey = bw unlock $masterPassword --raw

    if (-not $sessionKey) {
        Write-Error "Failed to unlock Bitwarden vault."
        return $false
    }

    # Save the session key to a secure file
    try {
        $sessionKey | Out-File -FilePath $SessionKeyPath -Encoding utf8 -Force -ErrorAction Stop

        # Set restrictive permissions
        icacls $SessionKeyPath /inheritance:r
        icacls $SessionKeyPath /grant:r "$env:USERNAME:(R)"

        # Add the session key to the environment variables
        [System.Environment]::SetEnvironmentVariable("BW_SESSION", $sessionKey, [System.EnvironmentVariableTarget]::User)
        $env:BW_SESSION = $sessionKey

        # Verify the setup
        $items = bw list items --limit 1

        if ($items) {
            Write-Host "Bitwarden authentication is now persistent! You can use 'bw' commands without re-authenticating." -ForegroundColor Green
            return $true
        }
    } catch {
        Write-Host "Failed to save session file: $_" -ForegroundColor Red
    }

    Write-Error "Failed to verify Bitwarden setup. Please check your configuration."
    return $false
}

# Call the function
Set-BitwardenPermanentAuth
