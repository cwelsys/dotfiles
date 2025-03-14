# Get content from stdin
$tempFile = New-TemporaryFile
$input | Out-String | Set-Content -Path $tempFile -NoNewline

$keyPath = Join-Path $env:USERPROFILE ".config\key.txt"
if (Test-Path $keyPath) {
	$env:SOPS_AGE_KEY_FILE = $keyPath
	try {
		# Attempt to decrypt
		sops -d $tempFile
	} catch {
		# If decryption fails, output original content
		Get-Content $tempFile -Raw
	}
} else {
	# If no key present, output original content
	Get-Content $tempFile -Raw
}

# Clean up
Remove-Item $tempFile
