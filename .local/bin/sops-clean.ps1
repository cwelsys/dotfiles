# Get content from stdin
$content = $input | Out-String

$keyPath = Join-Path $env:USERPROFILE ".config\key.txt"
if (Test-Path $keyPath) {
	$env:SOPS_AGE_KEY_FILE = $keyPath
	try {
		# Create a temporary file for encryption
		$tempFile = [System.IO.Path]::GetTempFileName()
		$content | Set-Content -Path $tempFile -NoNewline

		# Encrypt with explicit age recipient
		$recipient = "age1tg4yymck048fyv8dh389dgh6uuhmhnz6pusevndukqlslxru8ctqvne8el"
		sops --age $recipient -e $tempFile

		# Clean up
		Remove-Item $tempFile -Force
	} catch {
		# If encryption fails, output original content
		Write-Error $_.Exception.Message
		$content
	}
} else {
	# If no key present, output original content
	$content
}
