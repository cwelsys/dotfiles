# make sure we have colors
if (-not (Get-Module -ListAvailable -Name PSWriteColor)) {
    Write-Host 'PSWriteColor module not found. Installing...' -ForegroundColor Yellow
    try {
        Install-Module -Name PSWriteColor -Force -Scope CurrentUser -ErrorAction Stop
        Write-Host 'PSWriteColor module installed successfully.' -ForegroundColor Green
    }
    catch {
        Write-Host "Failed to install PSWriteColor module: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host 'Script will continue with basic Write-Host commands.' -ForegroundColor Yellow
    }
}

if (Get-Module -ListAvailable -Name PSWriteColor) {
    Import-Module PSWriteColor -ErrorAction SilentlyContinue
}

Write-Host ''
Write-Color -Text '***********************************' -Color Cyan
Write-Color -Text '**       INSTALLING SCOOP        **' -Color Cyan
Write-Color -Text '***********************************' -Color Cyan
Write-Host ''

if (Get-Command 'scoop' -ErrorAction SilentlyContinue) {
  Write-Color -Text '✅ ', 'scoop: ', 'Already installed.' -Color Green, White, Gray
  Write-Color -Text "`n👍 ", 'Scoop installation check completed.', "`n" -Color White, Cyan, White
  exit 0
}

Write-Color -Text '🔄 ', 'scoop: ', 'Attempting to install Scoop...' -Color Blue, White, Gray

# Set execution policy for the current process to allow script execution if needed
# This is often required for the Scoop installation script
try {
  Set-ExecutionPolicy RemoteSigned -Scope Process -Force -ErrorAction Stop
  Write-Color -Text 'ℹ️ ', 'scoop: ', 'Execution policy set to RemoteSigned for current process.' -Color Yellow, White, Gray
}
catch {
  Write-Color -Text '⚠️ ', 'scoop: ', "Failed to set execution policy. Scoop installation might fail. Error: $($_.Exception.Message)" -Color Red, White, Gray
  # Optionally, exit here if setting execution policy is critical
  # exit 1
}

$installCommand = { Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression }
$success = $false
$errorMessage = ''

try {
  Invoke-Command -ScriptBlock $installCommand -ErrorAction Stop
  # Check for scoop command again after attempting install
  if (Get-Command 'scoop' -ErrorAction SilentlyContinue) {
    $success = $true
  }
  else {
    $errorMessage = 'Scoop command still not found after installation attempt.'
  }
}
catch {
  $errorMessage = $_.Exception.Message
}

if ($success) {
  Write-Color -Text '✅ ', 'scoop: ', 'Installation successful.' -Color Green, White, Gray
  # Verify by running a simple scoop command
  scoop --version
}
else {
  Write-Color -Text '❌ ', 'scoop: ', "Installation failed. Error: $errorMessage" -Color Red, White, Gray
}

Write-Color -Text "`n👍 ", 'Scoop installation process completed.', "`n" -Color White, Cyan, White

Write-Host ''
Write-Color -Text '***********************************' -Color DarkRed
Write-Color -Text '**       CONFIGURING WINGET      **' -Color DarkRed
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
		}
	}
 catch {
		Write-Color -Text '❌ ', 'winget: ', "Installation failed. Error: $($_.Exception.Message)" -Color Red, White, Gray
	}
}
else {
	Write-Color -Text '✅ ', 'winget: ', 'Already installed.' -Color Green, White, Gray
}
Write-Host ''

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

scoop bucket add nerd-fonts
scoop install gpg yazi fzf oh-my-posh scoop-search FantasqueSansMono-NF resvg imagemagick ffmpeg
scoop install 7zip jq poppler fd ripgrep
