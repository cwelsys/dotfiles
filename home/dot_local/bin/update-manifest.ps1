$env:Path = [System.Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' + [System.Environment]::GetEnvironmentVariable('Path', 'User')

$yamlFilePath = Join-Path $env:USERPROFILE '.local\share\chezmoi\home\.chezmoidata\windows\pkgs.yml'

if (-not (Test-Path $yamlFilePath)) {
    Write-Color -Text "❌ Manifest file not found at: $yamlFilePath" -Color Red
    exit 1
}

$manifestContent = Get-Content -Path $yamlFilePath -Raw
if (-not $manifestContent) {
    Write-Color -Text '❌ Failed to read manifest file or file is empty' -Color Red
    exit 1
}

$currentPackages = @()
$registryPaths = @()
$inScoopSection = $false
$inBucketsSection = $false
$inPkgsSection = $false
$inRegistrySection = $false
$manifestLines = $manifestContent -split "`n"

# Track indentation and scoop package section boundaries
$scoopPkgsStartIndex = -1
$scoopPkgsEndIndex = -1
$packageIndentation = '        ' # Default indentation

foreach ($i in 0..($manifestLines.Count - 1)) {
    $line = $manifestLines[$i]

    if ($line -match '^\s*scoop:\s*$') {
        $inScoopSection = $true
        continue
    }

    if ($inScoopSection -and $line -match '^\s*buckets:\s*$') {
        $inBucketsSection = $true
        $inPkgsSection = $false
        continue
    }

    if ($inScoopSection -and $line -match '^\s*apps:\s*$') {
        $inBucketsSection = $false
        $inPkgsSection = $true
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
        $inPkgsSection = $false
        $inRegistrySection = $true  # NEW: Mark that we're in registry section
        continue
    }

    if ($inPkgsSection -and $line -match '^\s*-\s+''([^'']+)''') {
        $pkg = $Matches[1]
        $currentPackages += $pkg
        $scoopPkgsEndIndex = $i
    }
    elseif ($inRegistrySection -and $line -match '^\s*-\s+''([^'']+)''') {
        $regPath = $Matches[1]
        $registryPaths += $regPath  # NEW: Store registry paths separately
    }

    if ($inScoopSection -and
        ($line -match '^\s*\w+:\s*$' -and $line -notmatch '^\s*apps:\s*$' -and $line -notmatch '^\s*buckets:\s*$' -and $line -notmatch '^\s*importRegistry:\s*$') ||
        ($line -match '^\s*winget:\s*$')) {
        $inScoopSection = $false
        $inBucketsSection = $false
        $inPkgsSection = $false
        $inRegistrySection = $false
        if ($scoopPkgsEndIndex -eq -1) {
            $scoopPkgsEndIndex = $i - 1
        }
    }
}

# Parse the YAML to extract current winget packages
$currentWingetPackages = @()
$inWingetSection = $false
$wingetPkgsStartIndex = -1
$wingetPkgsEndIndex = -1
$wingetIndentation = '      ' # Default indentation

foreach ($i in 0..($manifestLines.Count - 1)) {
    $line = $manifestLines[$i]
    if ($line -match '^\s*winget:\s*$') {
        $inWingetSection = $true
        $wingetPkgsStartIndex = $i

        # Find the indentation level from the next line if available
        if ($i + 1 -lt $manifestLines.Count) {
            $nextLine = $manifestLines[$i + 1]
            if ($nextLine -match '^(\s+)-\s+') {
                $wingetIndentation = $Matches[1]
            }
        }
        continue
    }

    # Capture winget package entries
    if ($inWingetSection -and $line -match '^\s*-\s+''([^'']+)''') {
        $pkg = $Matches[1]
        $currentWingetPackages += $pkg

        $wingetPkgsEndIndex = $i
    }

    if ($inWingetSection -and $wingetPkgsStartIndex -ne -1 -and
        $line -match '^\s*\w+:\s*$') {
        $inWingetSection = $false
        if ($wingetPkgsEndIndex -eq -1) {
            $wingetPkgsEndIndex = $i - 1
        }
    }
}

$timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$backupDir = Join-Path $env:USERPROFILE '.config\chezmoi\backups'
if (-not (Test-Path $backupDir)) {
    New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
}
$backupPath = Join-Path $backupDir "win_pkgs.yml.bak.$timestamp"
Copy-Item -Path $yamlFilePath -Destination $backupPath -Force
Write-Color -Text "💾 Created backup at $backupPath" -Color Gray

Write-Color -Text '🔍 Getting installed Scoop packages...' -Color Blue
$installedPackages = @()

try {
    # Force scoop list to output text, not objects
    $scoopList = scoop list | Out-String -Stream

    # Parse the output as text - but skip header and separator lines
    $installedApps = @()
    $skipNextLine = $true  # Skip the first line (header)

    foreach ($line in $scoopList) {
        # Skip empty lines
        if ([string]::IsNullOrWhiteSpace($line)) { continue }

        # Skip the header line (contains "Name")
        if ($line -match '^\s*Name\s+Version\s+') {
            $skipNextLine = $true  # Next line is usually a separator
            continue
        }

        # Skip separator lines (contains "----")
        if ($line -match '^\s*-+\s+-+\s*') {
            continue
        }

        # Parse actual app lines - they should start with a valid app name
        if ($line -match '^\s*([a-zA-Z0-9._-]+)\s+') {
            $appName = $Matches[1].Trim()
            # Remove any * that indicates outdated packages
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
            Write-Color -Text "⚠️ Could not determine bucket for $appName, will use 'main'" -Color Yellow
            $installedPackages += "main/$appName"
        }
    }

    # Filter out any malformed entries
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
    exit 1
}

Write-Color -Text '🔍 Getting installed Winget packages...' -Color Blue
$installedWingetPackages = @()

try {
    $wingetOutput = winget list

    # Skip first few lines (headers)
    $capturePackages = $false
    $seenIds = @{}  # Track IDs we've already added

    foreach ($line in $wingetOutput) {
        # Skip empty lines
        if ([string]::IsNullOrWhiteSpace($line)) { continue }

        # Skip until we find the header line with "Name" and "ID"
        if (-not $capturePackages -and $line -match 'Name' -and $line -match 'ID') {
            $capturePackages = $true
            continue
        }

        # Skip the separator line after header
        if ($capturePackages -and $line -match '^-+\s+-+') {
            continue
        }

        # Process package lines
        if ($capturePackages) {
            # Split by whitespace, but be smart about it
            # Most reliable way: The ID is typically the second-to-last column
            $parts = $line -split '\s\s+' | Where-Object { $_ -ne '' }

            if ($parts.Count -ge 3) {
                # Must have at least Name, ID, and Source
                # The ID is typically the second-to-last or third-to-last item
                $potentialId = $null

                # Try to identify the ID by looking for a pattern with dots (vendor.product format)
                foreach ($part in $parts) {
                    if ($part -match '^[A-Za-z0-9_-]+(\.[A-Za-z0-9_-]+)+$') {
                        $potentialId = $part.Trim()
                        break
                    }
                }

                # If we found an ID and haven't seen it yet
                if ($potentialId -and -not $seenIds.ContainsKey($potentialId)) {
                    $seenIds[$potentialId] = $true
                    $installedWingetPackages += $potentialId
                }
            }
        }
    }

    # Filter out incorrect entries and version numbers
    $cleanWingetPackages = @()
    foreach ($pkg in $installedWingetPackages) {
        # Skip standalone version numbers
        if ($pkg -match '^[\d\.]+(\.\d+)*(\+\d+)*(…)?$' -or
            $pkg -match '^v\d+\.\d+(\.\d+)*$') {
            continue
        }

        # Skip entries that don't look like package IDs
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
        # Skip standalone version numbers (matches typical version patterns)
        if ($pkg -match '^[\d\.]+(\.\d+)*(\+\d+)*(…)?$' -or
            $pkg -match '^v\d+\.\d+(\.\d+)*$' -or
            $pkg -match '^\d+\.\d+\.\d+\.\d+$') {

            Write-Color -Text "  Filtering version number: $pkg" -Color Gray
            continue
        }

        # Skip MSIX packages unless in whitelist
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

        # Add the package to our filtered list
        $filtered += $pkg
    }

    return $filtered
}

# Filter the installed and current winget packages
$filteredInstalledWinget = Filter-WingetPackages -Packages $installedWingetPackages
Write-Color -Text "Filtered to $($filteredInstalledWinget.Count) relevant winget apps" -Color Cyan

$filteredCurrentWinget = Filter-WingetPackages -Packages $currentWingetPackages

# Use the filtered lists for comparison
$newWingetPackages = $filteredInstalledWinget | Where-Object { $_ -notin $filteredCurrentWinget }
$wingetPackagesToRemove = $filteredCurrentWinget | Where-Object { $_ -notin $filteredInstalledWinget }

# Find new packages that aren't in the manifest
$newPackages = $installedPackages | Where-Object { $_ -notin $currentPackages }

# Find packages in the manifest that are no longer installed
$packagesToRemove = $currentPackages | Where-Object {
    $_ -notin $installedPackages -and
    $_ -notin $registryPaths  # NEW: Exclude registry paths from removal
}

# Find new winget packages that aren't in the manifest
$newWingetPackages = $filteredInstalledWinget | Where-Object { $_ -notin $filteredCurrentWinget }

# Find winget packages in the manifest that are no longer installed
$wingetPackagesToRemove = $filteredCurrentWinget | Where-Object { $_ -notin $filteredInstalledWinget }

$wingetPackagesToRemove = $wingetPackagesToRemove | Where-Object {
    $pkg = $_
    -not ($manifestLines | Where-Object { $_ -match "- '$pkg'.*#" })
}

if ($newPackages.Count -eq 0 -and $packagesToRemove.Count -eq 0 -and $newWingetPackages.Count -eq 0 -and $wingetPackagesToRemove.Count -eq 0) {
    Write-Color -Text '✅ No changes needed - manifest is up to date' -Color Green
    exit 0
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

# Update the manifest by inserting new packages and removing uninstalled ones
if ($scoopPkgsEndIndex -ne -1 || $wingetPkgsEndIndex -ne -1) {
    $updatedContent = @()

    $currentSection = ''
    $currentSubSection = ''

    for ($i = 0; $i -lt $manifestLines.Count; $i++) {
        $line = $manifestLines[$i]

        if ($line -match '^\s*scoop:\s*$') {
            $currentSection = 'scoop'
            $currentSubSection = ''
        }
        elseif ($currentSection -eq 'scoop' && $line -match '^\s*buckets:\s*$') {
            $currentSubSection = 'buckets'
        }
        elseif ($currentSection -eq 'scoop' && $line -match '^\s*pkgs:\s*$') {
            $currentSubSection = 'pkgs'
        }
        elseif ($currentSection -eq 'scoop' && $line -match '^\s*importRegistry:\s*$') {
            $currentSubSection = 'importRegistry'
        }
        elseif ($line -match '^\s*winget:\s*$') {
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
            $currentSubSection -eq 'pkgs' &&
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
                # Check if it has a comment (we want to preserve those)
                if ($line -notmatch '#') {
                    $shouldSkipLine = $true
                }
            }
        }

        if (-not $shouldSkipLine) {
            $updatedContent += $line
        }

        # If we're at the end of the existing packages section, add new packages
        if ($i -eq $scoopPkgsEndIndex) {
            # Add all new packages with proper indentation
            foreach ($pkg in $newPackages) {
                $updatedContent += "$packageIndentation- '$pkg'"
            }
        }

        if ($i -eq $wingetPkgsEndIndex) {
            # Add all new winget packages with proper indentation
            foreach ($pkg in $newWingetPackages) {
                $updatedContent += "$wingetIndentation- '$pkg'"
            }
        }
    }

    # Write the updated content back to the file
    Set-Content -Path $yamlFilePath -Value ($updatedContent -join "`n")
}
else {
    # If we couldn't find the section, warn the user
    Write-Color -Text '⚠️ Could not determine where to insert new packages. No changes made.' -Color Yellow
    Write-Color -Text '   You may need to add these packages manually:' -Color Yellow
    foreach ($pkg in $newPackages) {
        Write-Color -Text "  - $pkg" -Color Cyan
    }
    foreach ($pkg in $newWingetPackages) {
        Write-Color -Text "  - $pkg" -Color Cyan
    }
    exit 1
}

# Report on the changes made
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
