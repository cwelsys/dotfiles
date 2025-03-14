# Get content from stdin
$content = $input | Out-String
$recipient = "age1tg4yymck048fyv8dh389dgh6uuhmhnz6pusevndukqlslxru8ctqvne8el"

$keyPath = Join-Path $env:USERPROFILE ".config\key.txt"
if (Test-Path $keyPath) {
	$env:SOPS_AGE_KEY_FILE = $keyPath

	try {
		# Create a temporary file for encryption
		$tempFile = [System.IO.Path]::GetTempFileName()
		$content | Set-Content -Path $tempFile -NoNewline

		# Create a simple SOPS config inline
		$sopsYaml = @"
creation_rules:
    - path_regex: .*
      age: $recipient
"@
		$configFile = [System.IO.Path]::GetTempFileName()
		$sopsYaml | Set-Content -Path $configFile -NoNewline

		# Encrypt using temp config
		$encrypted = sops --config $configFile -e $tempFile 2>&1
		if ($LASTEXITCODE -eq 0) {
			$encrypted
		} else {
			Write-Error "Encryption failed: $encrypted"
			$content
		}

		# Clean up
		Remove-Item $tempFile -Force
		Remove-Item $configFile -Force
	} catch {
		# If encryption fails, output original content
		Write-Error $_.Exception.Message
		$content
	}
} else {
	# If no key present, output original content
	$content
}
