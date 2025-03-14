# Read from stdin
$content = $input | Out-String

$keyPath = Join-Path $env:USERPROFILE ".config\key.txt"
if (Test-Path $keyPath) {
	$env:SOPS_AGE_KEY_FILE = $keyPath
	try {
		# Write content to a temporary file since SOPS needs a file
		$tempFile = New-TemporaryFile
		$content | Set-Content $tempFile -NoNewline

		# Attempt to decrypt
		$decrypted = sops -d $tempFile

		# Clean up temp file
		Remove-Item $tempFile

		# Output decrypted content
		$decrypted
	} catch {
		# If decryption fails, return the content as-is
		$content
	}
} else {
	# If no key is present, return the content as-is
	$content
}
