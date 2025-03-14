# Get content from stdin
$content = $input | Out-String

$keyPath = Join-Path $env:USERPROFILE ".config\key.txt"
if (Test-Path $keyPath) {
	$env:SOPS_AGE_KEY_FILE = $keyPath
	try {
		# Create a temporary file for decryption
		$tempFile = [System.IO.Path]::GetTempFileName()
		$content | Set-Content -Path $tempFile -NoNewline

		# Attempt to decrypt
		$decrypted = sops -d $tempFile 2>&1
		if ($LASTEXITCODE -eq 0) {
			$decrypted
		} else {
			Write-Error "Decryption failed: $decrypted"
			$content
		}

		# Clean up
		Remove-Item $tempFile -Force
	} catch {
		# If decryption fails, output original content
		Write-Error $_.Exception.Message
		$content
	}
} else {
	# If no key present, output original content
	$content
}
