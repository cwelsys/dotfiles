function Update-ChezmoiManifest {
	[Alias('cmpack')]
	[CmdletBinding()]
	param()

	$env:Path = [System.Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' + [System.Environment]::GetEnvironmentVariable('Path', 'User')

	$yamlFilePath = Join-Path $env:DOTS '.chezmoidata\pkgs.yml'

	if (-not (Test-Path $yamlFilePath)) {
		Write-Color -Text "❌ Manifest file not found at: $yamlFilePath" -Color Red
		return 1
	}

	$manifestContent = Get-Content -Path $yamlFilePath -Raw
	if (-not $manifestContent) {
		Write-Color -Text '❌ Failed to read manifest file or file is empty' -Color Red
		return 1
	}

	$currentPackages = @()
	$registryPaths = @()
	$inPkgsSection = $false
	$inWindowsSection = $false
	$inScoopSection = $false
	$inBucketsSection = $false
	$inAppsSection = $false
	$inRegistrySection = $false
	$manifestLines = $manifestContent -split "`n"
	$scoopPkgsStartIndex = -1
	$scoopPkgsEndIndex = -1
	$packageIndentation = '        '

	foreach ($i in 0..($manifestLines.Count - 1)) {
		$line = $manifestLines[$i]
		
		# Navigate through the new pkgs.windows.scoop structure
		if ($line -match '^\s*pkgs:\s*$') {
			$inPkgsSection = $true
			continue
		}
		
		if ($inPkgsSection -and $line -match '^\s*windows:\s*$') {
			$inWindowsSection = $true
			continue
		}
		
		if ($inWindowsSection -and $line -match '^\s*scoop:\s*$') {
			$inScoopSection = $true
			continue
		}

		if ($inScoopSection -and $line -match '^\s*buckets:\s*$') {
			$inBucketsSection = $true
			$inAppsSection = $false
			continue
		}

		if ($inScoopSection -and $line -match '^\s*apps:\s*$') {
			$inBucketsSection = $false
			$inAppsSection = $true
			$scoopPkgsStartIndex = $i

			if ($i + 1 -lt $manifestLines.Count) {
				$nextLine = $manifestLines[$i + 1]
				if ($nextLine -match '^(\s+)-\s+') {
					$packageIndentation = $Matches[1]
				}
			}
			continue
		}

		if ($inScoopSection -and $line -match '^\s*importRegistry:\s*$') {
			$inBucketsSection = $false
			$inAppsSection = $false
			$inRegistrySection = $true
			continue
		}

		if ($inAppsSection -and $line -match '^\s*-\s+''([^'']+)''') {
			$pkg = $Matches[1]
			$currentPackages += $pkg
			$scoopPkgsEndIndex = $i
		}
		elseif ($inRegistrySection -and $line -match '^\s*-\s+''([^'']+)''') {
			$regPath = $Matches[1]
			$registryPaths += $regPath
		}

		# Handle section transitions - need to account for new nested structure
		if ($line -match '^\s*winget:\s*$') {
			# Moving from scoop to winget within windows section
			$inScoopSection = $false
			$inBucketsSection = $false
			$inAppsSection = $false
			$inRegistrySection = $false
			if ($scoopPkgsEndIndex -eq -1) {
				$scoopPkgsEndIndex = $i - 1
			}
		}
		elseif ($line -match '^\s*[a-zA-Z]+:\s*$' -and 
			$line -notmatch '^\s*apps:\s*$' -and 
			$line -notmatch '^\s*buckets:\s*$' -and 
			$line -notmatch '^\s*importRegistry:\s*$' -and
			$line -notmatch '^\s*scoop:\s*$' -and
			$line -notmatch '^\s*winget:\s*$') {
			# We've hit a different top-level section
			if ($inWindowsSection) {
				$inPkgsSection = $false
				$inWindowsSection = $false
				$inScoopSection = $false
				$inBucketsSection = $false
				$inAppsSection = $false
				$inRegistrySection = $false
				if ($scoopPkgsEndIndex -eq -1) {
					$scoopPkgsEndIndex = $i - 1
				}
			}
		}
	}

	$currentWingetPackages = @()
	$inWingetPkgsSection = $false
	$inWingetWindowsSection = $false
	$inWingetSection = $false
	$wingetPkgsStartIndex = -1
	$wingetPkgsEndIndex = -1
	$wingetIndentation = '      '

	foreach ($i in 0..($manifestLines.Count - 1)) {
		$line = $manifestLines[$i]
		
		# Navigate through the new pkgs.windows.winget structure  
		if ($line -match '^\s*pkgs:\s*$') {
			$inWingetPkgsSection = $true
			continue
		}
		
		if ($inWingetPkgsSection -and $line -match '^\s*windows:\s*$') {
			$inWingetWindowsSection = $true
			continue
		}
		
		if ($inWingetWindowsSection -and $line -match '^\s*winget:\s*$') {
			$inWingetSection = $true
			$wingetPkgsStartIndex = $i

			if ($i + 1 -lt $manifestLines.Count) {
				$nextLine = $manifestLines[$i + 1]
				if ($nextLine -match '^(\s+)-\s+') {
					$wingetIndentation = $Matches[1]
				}
			}
			continue
		}

		if ($inWingetSection -and $line -match '^\s*-\s+''([^'']+)''') {
			$pkg = $Matches[1]
			$currentWingetPackages += $pkg
			$wingetPkgsEndIndex = $i
		}

		# Handle section transitions for winget
		if ($line -match '^\s*[a-zA-Z]+:\s*$' -and 
			$line -notmatch '^\s*winget:\s*$' -and
			$line -notmatch '^\s*pkgs:\s*$' -and  
			$line -notmatch '^\s*windows:\s*$') {
			# We've hit a different section
			if ($inWingetSection -and $wingetPkgsStartIndex -ne -1) {
				$inWingetSection = $false
				$inWingetWindowsSection = $false
				$inWingetPkgsSection = $false
				if ($wingetPkgsEndIndex -eq -1) {
					$wingetPkgsEndIndex = $i - 1
				}
			}
		}
	}

	$timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
	$backupDir = Join-Path $env:USERPROFILE '.config\chezmoi\backups'
	if (-not (Test-Path $backupDir)) {
		New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
	}
	$backupPath = Join-Path $backupDir "pkgs.yml.bak.$timestamp"
	Copy-Item -Path $yamlFilePath -Destination $backupPath -Force
	Write-Color -Text "💾 Created backup at $backupPath" -Color Gray

	Write-Color -Text '🔍 Getting installed Scoop packages...' -Color Blue
	$installedPackages = @()

	try {
		$scoopList = scoop list | Out-String -Stream
		$installedApps = @()
		$skipNextLine = $true

		foreach ($line in $scoopList) {
			if ([string]::IsNullOrWhiteSpace($line)) { continue }

			if ($line -match '^\s*Name\s+Version\s+') {
				$skipNextLine = $true
				continue
			}

			if ($line -match '^\s*-+\s+-+\s*') {
				continue
			}

			if ($line -match '^\s*([a-zA-Z0-9._-]+)\s+') {
				$appName = $Matches[1].Trim()
				$appName = $appName -replace '^\*', ''
				if (-not [string]::IsNullOrWhiteSpace($appName)) {
					$installedApps += $appName
				}
			}
		}

		Write-Color -Text "Found $($installedApps.Count) installed apps" -Color Cyan

		foreach ($appName in $installedApps) {
			$scoopDir = "$env:USERPROFILE\scoop"
			$bucketFound = $false
			$buckets = Get-ChildItem "$scoopDir\buckets" -Directory -ErrorAction SilentlyContinue |
			Select-Object -ExpandProperty Name

			foreach ($bucket in $buckets) {
				$appManifestPath = "$scoopDir\buckets\$bucket\bucket\$appName.json"
				if (Test-Path $appManifestPath) {
					$installedPackages += "$bucket/$appName"
					$bucketFound = $true
					break
				}
			}

			if (-not $bucketFound) {
				$bucketFilePath = "$scoopDir\apps\$appName\.bucket"
				if (Test-Path $bucketFilePath) {
					$bucketInfo = Get-Content $bucketFilePath -Raw
					$bucketInfo = $bucketInfo.Trim()
					if (-not [string]::IsNullOrWhiteSpace($bucketInfo)) {
						$installedPackages += "$bucketInfo/$appName"
						$bucketFound = $true
					}
				}
			}

			if (-not $bucketFound) {
				$installJsonPath = "$scoopDir\apps\$appName\current\install.json"
				if (Test-Path $installJsonPath) {
					try {
						$installJson = Get-Content $installJsonPath -Raw | ConvertFrom-Json
						if ($installJson.PSObject.Properties.Name -contains 'bucket') {
							$bucketInfo = $installJson.bucket
							$installedPackages += "$bucketInfo/$appName"
							$bucketFound = $true
						}
					}
					catch {
					}
				}
			}

			if (-not $bucketFound) {
				# Write-Color -Text "⚠️ Could not determine bucket for $appName, will use 'main'" -Color Yellow
				# $installedPackages += "main/$appName"
				Write-Color -Text "⚠️ Could not determine bucket for $appName, skipping..." -Color Yellow
			}
		}

		$cleanPackages = @()
		foreach ($pkg in $installedPackages) {
			if ($pkg -notmatch '@\{' -and $pkg -match '^[a-zA-Z0-9_-]+/[a-zA-Z0-9_.-]+$') {
				$cleanPackages += $pkg
			}
			else {
				Write-Color -Text "⚠️ Skipping malformed package entry: $pkg" -Color Yellow
			}
		}
		$installedPackages = $cleanPackages

	}
	catch {
		Write-Color -Text "❌ Failed to get list of installed Scoop packages: $_" -Color Red
		return 1
	}

	Write-Color -Text '🔍 Getting installed Winget packages...' -Color Blue
	$installedWingetPackages = @()

	try {
		$wingetOutput = winget list
		$capturePackages = $false
		$seenIds = @{}

		foreach ($line in $wingetOutput) {
			if ([string]::IsNullOrWhiteSpace($line)) { continue }
			if (-not $capturePackages -and $line -match 'Name' -and $line -match 'ID') {
				$capturePackages = $true
				continue
			}

			if ($capturePackages -and $line -match '^-+\s+-+') {
				continue
			}

			if ($capturePackages) {
				$parts = $line -split '\s\s+' | Where-Object { $_ -ne '' }

				if ($parts.Count -ge 3) {
					$potentialId = $null
					foreach ($part in $parts) {
						if ($part -match '^[A-Za-z0-9_-]+(\.[A-Za-z0-9_-]+)+$') {
							$potentialId = $part.Trim()
							break
						}
					}
					if ($potentialId -and -not $seenIds.ContainsKey($potentialId)) {
						$seenIds[$potentialId] = $true
						$installedWingetPackages += $potentialId
					}
				}
			}
		}

		$cleanWingetPackages = @()
		foreach ($pkg in $installedWingetPackages) {
			if ($pkg -match '^[\d\.]+(\.\d+)*(\+\d+)*(…)?$' -or
				$pkg -match '^v\d+\.\d+(\.\d+)*$') {
				continue
			}

			if ($pkg -notmatch '\.') {
				continue
			}

			$cleanWingetPackages += $pkg
		}

		$installedWingetPackages = $cleanWingetPackages

		Write-Color -Text "Found $($installedWingetPackages.Count) installed winget apps" -Color Cyan
	}
	catch {
		Write-Color -Text "❌ Failed to get list of installed Winget packages: $_" -Color Red
	}

	function Filter-WingetPackages {
		param (
			[Parameter(Mandatory = $true)]
			[array]$Packages
		)

		$filtered = @()
		$msixWhitelist = @('WinRAR.ShellExtension')  # Add any MSIX packages you want to keep

		foreach ($pkg in $Packages) {
			if ($pkg -match '^[\d\.]+(\.\d+)*(\+\d+)*(…)?$' -or
				$pkg -match '^v\d+\.\d+(\.\d+)*$' -or
				$pkg -match '^\d+\.\d+\.\d+\.\d+$') {

				Write-Color -Text "  Filtering version number: $pkg" -Color Gray
				continue
			}

			if ($pkg -match '^MSIX\\') {
				$isWhitelisted = $false
				foreach ($whitelistItem in $msixWhitelist) {
					if ($pkg -match $whitelistItem) {
						$isWhitelisted = $true
						break
					}
				}

				if (-not $isWhitelisted) {
					Write-Color -Text "  Filtering MSIX package: $pkg" -Color Gray
					continue
				}
			}
			$filtered += $pkg
		}

		return $filtered
	}

	$filteredInstalledWinget = Filter-WingetPackages -Packages $installedWingetPackages
	Write-Color -Text "Filtered to $($filteredInstalledWinget.Count) relevant winget apps" -Color Cyan

	$filteredCurrentWinget = Filter-WingetPackages -Packages $currentWingetPackages
	$newWingetPackages = $filteredInstalledWinget | Where-Object { $_ -notin $filteredCurrentWinget }
	$wingetPackagesToRemove = $filteredCurrentWinget | Where-Object { $_ -notin $filteredInstalledWinget }
	$newPackages = $installedPackages | Where-Object { $_ -notin $currentPackages }

	$packagesToRemove = $currentPackages | Where-Object {
		$_ -notin $installedPackages -and
		$_ -notin $registryPaths
	}

	$newWingetPackages = $filteredInstalledWinget | Where-Object { $_ -notin $filteredCurrentWinget }
	$wingetPackagesToRemove = $filteredCurrentWinget | Where-Object { $_ -notin $filteredInstalledWinget }

	$wingetPackagesToRemove = $wingetPackagesToRemove | Where-Object {
		$pkg = $_
		-not ($manifestLines | Where-Object { $_ -match "- '$pkg'.*#" })
	}

	if ($newPackages.Count -eq 0 -and $packagesToRemove.Count -eq 0 -and $newWingetPackages.Count -eq 0 -and $wingetPackagesToRemove.Count -eq 0) {
		Write-Color -Text '✅ No changes needed - manifest is up to date' -Color Green
		return 0
	}

	if ($newPackages.Count -gt 0) {
		Write-Color -Text "📝 Adding $($newPackages.Count) new packages to manifest..." -Color Blue
	}

	if ($packagesToRemove.Count -gt 0) {
		Write-Color -Text "🗑️ Removing $($packagesToRemove.Count) uninstalled packages from manifest..." -Color Yellow
	}

	if ($newWingetPackages.Count -gt 0) {
		Write-Color -Text "📝 Adding $($newWingetPackages.Count) new winget packages to manifest..." -Color Blue
	}

	if ($wingetPackagesToRemove.Count -gt 0) {
		Write-Color -Text "🗑️ Removing $($wingetPackagesToRemove.Count) uninstalled winget packages from manifest..." -Color Yellow
	}

	if ($scoopPkgsEndIndex -ne -1 || $wingetPkgsEndIndex -ne -1) {
		$updatedContent = @()

		$currentSection = ''
		$currentSubSection = ''

		for ($i = 0; $i -lt $manifestLines.Count; $i++) {
			$line = $manifestLines[$i]

			if ($line -match '^\s*pkgs:\s*$') {
				$currentSection = 'pkgs'
				$currentSubSection = ''
			}
			elseif ($currentSection -eq 'pkgs' && $line -match '^\s*windows:\s*$') {
				$currentSection = 'windows'
				$currentSubSection = ''
			}
			elseif ($currentSection -eq 'windows' && $line -match '^\s*scoop:\s*$') {
				$currentSection = 'scoop'
				$currentSubSection = ''
			}
			elseif ($currentSection -eq 'scoop' && $line -match '^\s*buckets:\s*$') {
				$currentSubSection = 'buckets'
			}
			elseif ($currentSection -eq 'scoop' && $line -match '^\s*apps:\s*$') {
				$currentSubSection = 'apps'
			}
			elseif ($currentSection -eq 'scoop' && $line -match '^\s*importRegistry:\s*$') {
				$currentSubSection = 'importRegistry'
			}
			elseif ($currentSection -eq 'windows' && $line -match '^\s*winget:\s*$') {
				$currentSection = 'winget'
				$currentSubSection = ''
			}
			elseif ($line -match '^\s*psGallery:\s*$') {
				$currentSection = 'psGallery'
				$currentSubSection = ''
			}
			elseif ($line -match '^\s*addons:\s*$') {
				$currentSection = 'addons'
				$currentSubSection = ''
			}

			$shouldSkipLine = $false
			if ($packagesToRemove.Count -gt 0 &&
				$currentSection -eq 'scoop' &&
				$currentSubSection -eq 'apps' &&
				$line -match '^\s*-\s+''([^'']+)''') {
				$packageInLine = $Matches[1]
				if ($packageInLine -in $packagesToRemove) {
					$shouldSkipLine = $true
				}
			}

			if ($wingetPackagesToRemove.Count -gt 0 &&
				$currentSection -eq 'winget' &&
				$line -match '^\s*-\s+''([^'']+)''') {
				$packageInLine = $Matches[1]
				if ($packageInLine -in $wingetPackagesToRemove) {
					if ($line -notmatch '#') {
						$shouldSkipLine = $true
					}
				}
			}

			if (-not $shouldSkipLine) {
				$updatedContent += $line
			}
			if ($i -eq $scoopPkgsEndIndex) {
				foreach ($pkg in $newPackages) {
					$updatedContent += "$packageIndentation- '$pkg'"
				}
			}

			if ($i -eq $wingetPkgsEndIndex) {
				foreach ($pkg in $newWingetPackages) {
					$updatedContent += "$wingetIndentation- '$pkg'"
				}
			}
		}
		Set-Content -Path $yamlFilePath -Value ($updatedContent -join "`n")
	}
	else {
		Write-Color -Text '⚠️ Could not determine where to insert new packages. No changes made.' -Color Yellow
		Write-Color -Text '   You may need to add these packages manually:' -Color Yellow
		foreach ($pkg in $newPackages) {
			Write-Color -Text "  - $pkg" -Color Cyan
		}
		foreach ($pkg in $newWingetPackages) {
			Write-Color -Text "  - $pkg" -Color Cyan
		}
		return 1
	}

	if ($newPackages.Count -gt 0) {
		Write-Color -Text '✅ Successfully added new packages:' -Color Green
		foreach ($pkg in $newPackages) {
			Write-Color -Text "  + $pkg" -Color Cyan
		}
	}

	if ($packagesToRemove.Count -gt 0) {
		Write-Color -Text '✅ Successfully removed uninstalled packages:' -Color Green
		foreach ($pkg in $packagesToRemove) {
			Write-Color -Text "  - $pkg" -Color Red
		}
	}

	if ($newWingetPackages.Count -gt 0) {
		Write-Color -Text '✅ Successfully added new winget packages:' -Color Green
		foreach ($pkg in $newWingetPackages) {
			Write-Color -Text "  + $pkg" -Color Cyan
		}
	}

	if ($wingetPackagesToRemove.Count -gt 0) {
		Write-Color -Text '✅ Successfully removed uninstalled winget packages:' -Color Green
		foreach ($pkg in $wingetPackagesToRemove) {
			Write-Color -Text "  - $pkg" -Color Red
		}
	}

	Write-Host ''
	Write-Color -Text "✨ DONE! Run 'chezmoi apply' to apply your changes." -Color Green
}

function Invoke-WindhawkBackup {
	[Alias('windhawk-backup')]
	[CmdletBinding()]
	param()
	# Self-elevate
	if (-Not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) {
		if ([int](Get-CimInstance -Class Win32_OperatingSystem | Select-Object -ExpandProperty BuildNumber) -ge 6000) {
			$CommandLine = "-File `"" + $MyInvocation.MyCommand.Path + "`" " + $MyInvocation.UnboundArguments
			Start-Process -Wait -FilePath PowerShell.exe -Verb Runas -ArgumentList $CommandLine
		}
	}

	$backupZipPath = Join-Path $env:USERPROFILE 'Downloads\windhawk-backup.zip'
	$windhawkRoot = 'C:\ProgramData\Windhawk'
	$registryKey = 'HKLM:\SOFTWARE\Windhawk'

	function Test-WindhawkInstalled {
		param(
			[string]$WindhawkFolder
		)
		if (Test-Path $WindhawkFolder) {
			return $true
		}
		else {
			return $false
		}
	}

	function Do-Backup {
		param(
			[string]$WindhawkFolder,
			[string]$BackupPath,
			[string]$RegistryKey
		)

		Write-Host "`n--- Starting Windhawk backup ---" -ForegroundColor Cyan

		# Create a temporary folder to stage the backup contents
		$timeStamp = (Get-Date -Format 'yyyyMMddHHmmss')
		$backupFolder = Join-Path $env:TEMP ("WindhawkBackup_$timeStamp")
		New-Item -ItemType Directory -Path $backupFolder -Force | Out-Null

		# Prepare Engine folder structure inside the backup
		$engineFolder = Join-Path $backupFolder 'Engine'
		New-Item -ItemType Directory -Path $engineFolder -Force | Out-Null

		# Define the paths to copy from
		$modsSourceFolder = Join-Path $WindhawkFolder 'ModsSource'
		$modsFolder = Join-Path $WindhawkFolder 'Engine\Mods'

		# Copy ModsSource if it exists
		if (Test-Path $modsSourceFolder) {
			Write-Host 'Copying ModsSource folder...'
			Copy-Item -Path $modsSourceFolder -Destination $backupFolder -Recurse -Force
		}
		else {
			Write-Warning "ModsSource folder not found at: $modsSourceFolder"
		}

		# Copy Mods folder if it exists
		if (Test-Path $modsFolder) {
			Write-Host 'Copying Engine\Mods folder...'
			Copy-Item -Path $modsFolder -Destination $engineFolder -Recurse -Force
		}
		else {
			Write-Warning "Mods folder not found at: $modsFolder"
		}

		# Export registry key
		Write-Host 'Exporting Windhawk registry key...'
		$regExportFile = Join-Path $backupFolder 'Windhawk.reg'
		# Using reg.exe for consistent export. /y overwrites without prompt.
		reg export 'HKLM\SOFTWARE\Windhawk' $regExportFile /y | Out-Null

		# Create/overwrite the existing backup zip
		if (Test-Path $BackupPath) {
			Write-Host "Removing existing backup zip at: $BackupPath"
			Remove-Item $BackupPath -Force
		}

		Write-Host "Compressing backup to: $BackupPath"
		Compress-Archive -Path (Join-Path $backupFolder '*') -DestinationPath $BackupPath -Force

		Write-Host "`nBackup completed successfully!"
		Write-Host "Backup archive saved to: $BackupPath"
	}

	function Do-Restore {
		param(
			[string]$WindhawkFolder,
			[string]$BackupPath,
			[string]$RegistryKey
		)

		Write-Host "`n--- Starting Windhawk restore ---" -ForegroundColor Cyan

		# Check if the backup zip exists
		if (!(Test-Path $BackupPath)) {
			Write-Warning "Backup zip not found at: $BackupPath"
			return
		}

		# Create a temporary folder to extract contents
		$timeStamp = (Get-Date -Format 'yyyyMMddHHmmss')
		$extractFolder = Join-Path $env:TEMP ("WindhawkRestore_$timeStamp")
		New-Item -ItemType Directory -Path $extractFolder -Force | Out-Null

		Write-Host "Extracting backup zip: $BackupPath"
		Expand-Archive -Path $BackupPath -DestinationPath $extractFolder -Force

		# After extraction, we expect:
		#   ModsSource in the root of $extractFolder
		#   Engine\Mods in $extractFolder\Engine
		#   Windhawk.reg also in $extractFolder

		$modsSourceBackup = Join-Path $extractFolder 'ModsSource'
		$modsBackup = Join-Path $extractFolder 'Engine\Mods'
		$regBackup = Join-Path $extractFolder 'Windhawk.reg'

		# Copy ModsSource back if present
		if (Test-Path $modsSourceBackup) {
			Write-Host 'Copying ModsSource to Windhawk folder...'
			Copy-Item -Path $modsSourceBackup -Destination $WindhawkFolder -Recurse -Force
		}
		else {
			Write-Warning 'ModsSource not found in backup.'
		}

		# Copy Mods back if present
		if (Test-Path $modsBackup) {
			Write-Host 'Copying Engine\Mods to Windhawk folder...'
			# Ensure Engine folder exists
			$engineFolder = Join-Path $WindhawkFolder 'Engine'
			if (!(Test-Path $engineFolder)) {
				New-Item -ItemType Directory -Path $engineFolder -Force | Out-Null
			}
			Copy-Item -Path $modsBackup -Destination $engineFolder -Recurse -Force
		}
		else {
			Write-Warning 'Mods folder not found in backup.'
		}

		# Import registry if present
		if (Test-Path $regBackup) {
			Write-Host 'Importing Windhawk registry settings...'
			reg import $regBackup | Out-Null
		}
		else {
			Write-Warning 'Windhawk registry file not found in backup.'
		}

		Write-Host "`nRestore completed successfully!"
	}

	Write-Host "Checking if Windhawk is installed at: $windhawkRoot"

	if (!(Test-WindhawkInstalled -WindhawkFolder $windhawkRoot)) {
		Write-Warning "`nWindhawk folder not found at: $windhawkRoot"
		$choice = Read-Host 'Windhawk might not be installed. Continue anyway? (y/n)'
		if ($choice -notmatch '^(y|Y)$') {
			Write-Host 'Exiting.'
			return
		}
	}

	Write-Host "`nWould you like to (B)ackup or (R)estore or (E)xit?"
	$action = Read-Host 'Enter your choice (B/R/E)'

	switch ($action.ToUpper()) {
		'B' {
			Do-Backup -WindhawkFolder $windhawkRoot -BackupPath $backupZipPath -RegistryKey $registryKey
		}
		'R' {
			Do-Restore -WindhawkFolder $windhawkRoot -BackupPath $backupZipPath -RegistryKey $registryKey
		}
		'E' {
			Write-Host 'Exiting script.'
		}
		Default {
			Write-Host 'Unrecognized choice. Exiting.'
		}
	}

	Write-Host "`nDone."
}
