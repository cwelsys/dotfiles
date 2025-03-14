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
		$decrypted = sops -d $tempFile

		# Clean up and output
		Remove-Item $tempFile -Force
		$decrypted
	} catch {
		# If decryption fails, output original content
		$content
	}
} else {
	# If no key present, output original content
	$content
}
