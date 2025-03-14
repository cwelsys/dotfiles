# Test script to demonstrate SOPS encrypted environment variables

function Test-EnvironmentVariables {
	# Set the key file location
	$env:SOPS_AGE_KEY_FILE = "C:\Users\cwel\.config\key.txt"

	Write-Host "`nTesting environment variable decryption and setting...`n" -ForegroundColor Green

	# 1. Show the encrypted content
	Write-Host "1. Encrypted content of env.json:" -ForegroundColor Yellow
	Get-Content env.json

	# 2. Show decrypted content
	Write-Host "`n2. Decrypted content:" -ForegroundColor Yellow
	$decrypted = sops -d env.json
	Write-Host $decrypted

	# 3. Set the variables
	Write-Host "`n3. Setting environment variables..." -ForegroundColor Yellow
	$envConfig = $decrypted | ConvertFrom-Json

	foreach ($variable in $envConfig.environmentVariables) {
		$variableName = $variable.name
		$variablePath = $variable.path

		# Handle absolute paths vs relative paths
		if ([System.IO.Path]::IsPathRooted($variablePath)) {
			$variableValue = $variablePath
		} else {
			$variableValue = [System.IO.Path]::Combine($env:USERPROFILE, $variablePath)
		}

		[Environment]::SetEnvironmentVariable($variableName, $variableValue, [EnvironmentVariableTarget]::Process)
		Write-Host "Set $variableName = $variableValue"
	}

	# 4. Verify the variables
	Write-Host "`n4. Verifying set environment variables:" -ForegroundColor Yellow
	foreach ($variable in $envConfig.environmentVariables) {
		$name = $variable.name
		$value = [Environment]::GetEnvironmentVariable($name, [EnvironmentVariableTarget]::Process)
		Write-Host "$name = $value"
	}
}

# Run the test
Test-EnvironmentVariables
