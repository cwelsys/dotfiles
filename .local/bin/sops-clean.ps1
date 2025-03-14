# Get content from stdin
$content = $input | Out-String

$keyPath = Join-Path $env:USERPROFILE ".config\key.txt"
if (Test-Path $keyPath) {
	$env:SOPS_AGE_KEY_FILE = $keyPath
	try {
		# Create a temporary file for encryption
		$tempFile = [System.IO.Path]::GetTempFileName()
		$content | Set-Content -Path $tempFile -NoNewline

		# Encrypt and output to stdout
		sops -e $tempFile

		# Clean up
		Remove-Item $tempFile -Force
	} catch {
		# If encryption fails, output original content
		$content
	}
} else {
	# If no key present, output original content
	$content
}
