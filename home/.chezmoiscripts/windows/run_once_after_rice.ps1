$colors = @{
	Info    = 'Cyan'
	Success = 'Green'
	Error   = 'Red'
	Warning = 'Yellow'
	Details = 'DarkGray'
}

Write-Host "🍙🍙🍙🍙🍙🍙🍙🍙🍙🍙" -ForegroundColor $colors.Info

$soundsRepo = "https://github.com/cwelsys/beeps.git"
$soundsPath = Join-Path $env:USERPROFILE "Music\sound"

if (Test-Path -Path $soundsPath) {
	Write-Host "✅ Sounds repository already exists at $soundsPath" -ForegroundColor $colors.Success
} else {
	Write-Host "🔄 Cloning..." -ForegroundColor $colors.Info
	try {
		New-Item -ItemType Directory -Path (Split-Path -Path $soundsPath) -Force -ErrorAction SilentlyContinue | Out-Null
		git clone $soundsRepo $soundsPath
		Write-Host "✅ Successfully cloned to $soundsPath" -ForegroundColor $colors.Success
	} catch {
		Write-Host "❌ Failed to clone repository: $_" -ForegroundColor $colors.Error
	}
}

Write-Host "`n📝 Cursor theme manual installation:" -ForegroundColor $colors.Info
Write-Host "  1. Download the cursor theme: https://github.com/cwelsys/clicks/raw/refs/heads/main/Bibata/Bibata-Modern.zip" -ForegroundColor $colors.Info
Write-Host "  2. Extract the ZIP file" -ForegroundColor $colors.Details
Write-Host "  3. Find and right-click the .inf file in the extracted folder" -ForegroundColor $colors.Details
Write-Host "  4. Select 'Install' from the context menu" -ForegroundColor $colors.Details
Write-Host "  5. Open Control Panel → Mouse → Pointers tab" -ForegroundColor $colors.Details
Write-Host "  6. Select 'Bibata Modern' from the Scheme dropdown" -ForegroundColor $colors.Details
Write-Host "  7. Click Apply and OK" -ForegroundColor $colors.Details
