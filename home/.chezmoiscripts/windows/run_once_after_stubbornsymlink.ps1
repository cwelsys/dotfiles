if (-Not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) {
 if ([int](Get-CimInstance -Class Win32_OperatingSystem | Select-Object -ExpandProperty BuildNumber) -ge 6000) {
  $CommandLine = "-File `"" + $MyInvocation.MyCommand.Path + "`" " + $MyInvocation.UnboundArguments
  Start-Process -FilePath PowerShell.exe -Verb Runas -ArgumentList $CommandLine
  Exit
 }
}

Write-Output "Running with administrator privileges."

$chezmoidir = "$env:USERPROFILE\.local\share\chezmoi"
$sourceFile = "$chezmoidir\home\dot_config\windows-terminal\settings.json"
$targetDir = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState"
$targetFile = "$targetDir\settings.json"

if (-not (Test-Path $sourceFile)) {
	Write-Error "Source file not found: $sourceFile"
	exit 1
}

if (-not (Test-Path $targetDir)) {
	New-Item -ItemType Directory -Path $targetDir -Force
	Write-Output "Created directory: $targetDir"
}

if (Test-Path $targetFile) {
	$backupFile = "$targetFile.backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
	Copy-Item -Path $targetFile -Destination $backupFile -Force
	Write-Output "Backed up existing settings to: $backupFile"

	Remove-Item -Path $targetFile -Force
	Write-Output "Removed existing settings file"
}

try {
	New-Item -ItemType SymbolicLink -Path $targetFile -Target $sourceFile -Force
	Write-Output "Successfully created symbolic link: $targetFile -> $sourceFile"
} catch {
	Write-Error "Failed to create symbolic link: $_"
	Write-Output "Attempting to use alternative method..."

	$cmdResult = cmd /c mklink "$targetFile" "$sourceFile" 2>&1
	if ($LASTEXITCODE -eq 0) {
		Write-Output "Successfully created symbolic link using cmd.exe"
	} else {
		Write-Error "Failed to create symbolic link using cmd.exe: $cmdResult"
		Write-Output "As a last resort, copying the file instead of linking"
		Copy-Item -Path $sourceFile -Destination $targetFile -Force
		Write-Output "Copied file instead of creating a symbolic link"
	}
}

Write-Output "Windows Terminal settings configuration completed"
