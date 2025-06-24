# Ensure PSWriteColor is installed
if (-not (Get-Module -ListAvailable -Name PSWriteColor)) {
	Write-Host 'Installing PSWriteColor module...'
	Install-Module -Name PSWriteColor -Force -Scope CurrentUser -ErrorAction SilentlyContinue
}
Import-Module PSWriteColor -ErrorAction SilentlyContinue

Write-Host ''
Write-Color -Text '***********************************' -Color DarkRed
Write-Color -Text '**   CONFIGURING WINGET CLIENT   **' -Color DarkRed
Write-Color -Text '***********************************' -Color DarkRed
Write-Host ''

# --- WinGet Installation Check ---
Write-Color -Text 'Checking WinGet installation status...' -Color DarkRed
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
	Write-Color -Text 'ℹ️ ', 'winget: ', 'Not found. Attempting installation...' -Color Yellow, White, Gray
	try {
		# Use external script to install WinGet and all of its requirements
		# Source: - https://github.com/asheroto/winget-install
		Write-Color -Text '🔄 ', 'winget: ', 'Running installer script from asheroto.com/winget...' -Color Blue, White, Gray
		& ([ScriptBlock]::Create((Invoke-RestMethod asheroto.com/winget))) -Force -ErrorAction Stop

		if (Get-Command winget -ErrorAction SilentlyContinue) {
			Write-Color -Text '✅ ', 'winget: ', 'Installation successful.' -Color Green, White, Gray
		}
		else {
			Write-Color -Text '❌ ', 'winget: ', 'Installation script ran, but winget command still not found.' -Color Red, White, Gray
			# Optionally, exit here if winget is critical for subsequent steps
			# exit 1
		}
	}
 catch {
		Write-Color -Text '❌ ', 'winget: ', "Installation failed. Error: $($_.Exception.Message)" -Color Red, White, Gray
		# Optionally, exit here
		# exit 1
	}
}
else {
	Write-Color -Text '✅ ', 'winget: ', 'Already installed.' -Color Green, White, Gray
}
Write-Host ''

# --- WinGet Configuration ---
# Proceed with configuration only if winget command is now available
if (Get-Command winget -ErrorAction SilentlyContinue) {
	Write-Color -Text 'Configuring WinGet settings...' -Color DarkRed
	$settingsPath = "$env:LOCALAPPDATA\Packages\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe\LocalState\settings.json"
	$settingsJson = @'
{
    "$schema": "https://aka.ms/winget-settings.schema.json",

    // For documentation on these settings, see: https://aka.ms/winget-settings
    // "source": {
    //    "autoUpdateIntervalInMinutes": 5
    // },
    "visual": {
        "enableSixels": true,
        "progressBar": "rainbow"
    },
    "telemetry": {
        "disable": true
    },
    "experimentalFeatures": {
        "configuration03": true,
        "configureExport": true,
        "configureSelfElevate": true,
        "experimentalCMD": true
    },
    "network": {
        "downloader": "wininet"
    }
}
'@
	try {
		# Ensure the directory exists
		$settingsDir = Split-Path $settingsPath -Parent
		if (-not (Test-Path $settingsDir)) {
			Write-Color -Text 'ℹ️ ', 'winget: ', "Creating settings directory: $settingsDir" -Color Yellow, White, Gray
			New-Item -Path $settingsDir -ItemType Directory -Force -ErrorAction Stop | Out-Null
		}

		Write-Color -Text '🔄 ', 'winget: ', "Writing settings to $settingsPath" -Color Blue, White, Gray
		$settingsJson | Out-File $settingsPath -Encoding utf8 -ErrorAction Stop
		Write-Color -Text '✅ ', 'winget: ', 'Settings file written successfully.' -Color Green, White, Gray
	}
 catch {
		Write-Color -Text '❌ ', 'winget: ', "Failed to write settings file. Error: $($_.Exception.Message)" -Color Red, White, Gray
	}
}
else {
	Write-Color -Text '⚠️ ', 'winget: ', 'Command not found. Skipping settings configuration.' -Color Yellow, White, Gray
}
Write-Host ''

Write-Color -Text "`n👍 ", 'WinGet configuration process completed.', "`n" -Color White, DarkRed, White
