# Ensure PSWriteColor is installed
if (-not (Get-Module -ListAvailable -Name PSWriteColor)) {
  Write-Host 'Installing PSWriteColor module...'
  Install-Module -Name PSWriteColor -Force -Scope CurrentUser -ErrorAction SilentlyContinue
}
Import-Module PSWriteColor -ErrorAction SilentlyContinue

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
