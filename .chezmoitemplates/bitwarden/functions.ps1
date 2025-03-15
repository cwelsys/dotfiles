# Bitwarden Helper Functions for Chezmoi

function Initialize-BitwardenAuth {
	param (
		[switch]$Force
	)

	# Check if already logged in
	$status = bw status | ConvertFrom-Json

	if ($status.status -eq "unauthenticated" -or $Force) {
		# Prompt for credentials
		$email = Read-Host "Enter your Bitwarden email"
		$password = Read-Host "Enter your Bitwarden password" -AsSecureString

		# Convert secure string to plain text for the CLI
		$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($password)
		$plaintextPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
		[System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)

		# Login to Bitwarden
		$loginResult = $null
		try {
			$loginResult = bw login $email $plaintextPassword --raw
		} catch {
			Write-Error "Failed to login to Bitwarden: $_"
			return $null
		} finally {
			# Clear the plaintext password from memory
			$plaintextPassword = $null
		}

		if ($loginResult) {
			# Store the session key in Windows Credential Manager
			$configDir = "$env:USERPROFILE\.config"
			if (!(Test-Path $configDir)) {
				New-Item -Path $configDir -ItemType Directory -Force
			}

			[System.Management.Automation.PSCredential]::new("BitwardenSession", (ConvertTo-SecureString $loginResult -AsPlainText -Force)) |
			Export-Clixml -Path "$configDir\bitwarden-session.xml"

			return $loginResult
		}
	} elseif ($status.status -eq "locked") {
		# Unlock the vault
		$password = Read-Host "Enter your Bitwarden password to unlock the vault" -AsSecureString
		$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($password)
		$plaintextPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
		[System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)

		$unlockResult = $null
		try {
			$unlockResult = bw unlock $plaintextPassword --raw
		} catch {
			Write-Error "Failed to unlock Bitwarden: $_"
			return $null
		} finally {
			# Clear the plaintext password from memory
			$plaintextPassword = $null
		}

		if ($unlockResult) {
			# Store the session key
			$configDir = "$env:USERPROFILE\.config"
			if (!(Test-Path $configDir)) {
				New-Item -Path $configDir -ItemType Directory -Force
			}

			[System.Management.Automation.PSCredential]::new("BitwardenSession", (ConvertTo-SecureString $unlockResult -AsPlainText -Force)) |
			Export-Clixml -Path "$configDir\bitwarden-session.xml"

			return $unlockResult
		}
	} else {
		# Already logged in, retrieve the session key
		try {
			$credential = Import-Clixml -Path "$env:USERPROFILE\.config\bitwarden-session.xml"
			$sessionKey = $credential.GetNetworkCredential().Password
			return $sessionKey
		} catch {
			Write-Warning "Could not retrieve Bitwarden session, re-authenticating..."
			return Initialize-BitwardenAuth -Force
		}
	}

	return $null
}

function Get-BitwardenSecret {
	param (
		[Parameter(Mandatory = $true)]
		[string]$ItemName,

		[Parameter(Mandatory = $false)]
		[string]$FieldName,

		[Parameter(Mandatory = $false)]
		[switch]$AsSecureString
	)

	# Get the session key
	$sessionKey = Initialize-BitwardenAuth

	if (!$sessionKey) {
		Write-Error "No Bitwarden session available"
		return $null
	}

	# Set the session environment variable
	$env:BW_SESSION = $sessionKey

	try {
		# Search for the item
		$items = bw list items --search $ItemName | ConvertFrom-Json

		if ($items.Count -eq 0) {
			Write-Error "No item found with name: $ItemName"
			return $null
		}

		$item = $items | Where-Object { $_.name -eq $ItemName } | Select-Object -First 1

		if (!$item) {
			Write-Error "No exact match found for item: $ItemName"
			return $null
		}

		# If a field name is specified, get that field
		if ($FieldName) {
			$field = $item.fields | Where-Object { $_.name -eq $FieldName } | Select-Object -First 1

			if (!$field) {
				Write-Error "No field found with name: $FieldName in item: $ItemName"
				return $null
			}

			if ($AsSecureString) {
				return ConvertTo-SecureString $field.value -AsPlainText -Force
			} else {
				return $field.value
			}
		} else {
			# Return the password/value
			if ($item.login) {
				if ($AsSecureString) {
					return ConvertTo-SecureString $item.login.password -AsPlainText -Force
				} else {
					return $item.login.password
				}
			} elseif ($item.notes) {
				if ($AsSecureString) {
					return ConvertTo-SecureString $item.notes -AsPlainText -Force
				} else {
					return $item.notes
				}
			} else {
				Write-Error "Item does not contain a password or notes: $ItemName"
				return $null
			}
		}
	} catch {
		Write-Error "Error retrieving secret from Bitwarden: $_"
		return $null
	} finally {
		# Clear the session from environment
		$env:BW_SESSION = $null
	}
}

function Get-BitwardenEnvironmentVariables {
	param (
		[Parameter(Mandatory = $false)]
		[string]$FolderName = "Environment Variables"
	)

	# Get the session key
	$sessionKey = Initialize-BitwardenAuth

	if (!$sessionKey) {
		Write-Error "No Bitwarden session available"
		return $null
	}

	# Set the session environment variable
	$env:BW_SESSION = $sessionKey

	try {
		# Get all folders
		$folders = bw list folders | ConvertFrom-Json
		$folder = $folders | Where-Object { $_.name -eq $FolderName } | Select-Object -First 1

		if (!$folder) {
			Write-Warning "No folder found with name: $FolderName"
			return @()
		}

		# Get all items in the folder
		$items = bw list items --folderid $folder.id | ConvertFrom-Json

		# Transform items into environment variables
		$envVars = @()

		foreach ($item in $items) {
			$name = $item.name
			$value = $null

			# Check for a specific field named "value" or "path"
			$valueField = $item.fields | Where-Object { $_.name -eq "value" -or $_.name -eq "path" } | Select-Object -First 1

			if ($valueField) {
				$value = $valueField.value
			} elseif ($item.notes) {
				$value = $item.notes
			} elseif ($item.login) {
				$value = $item.login.password
			}

			if ($value) {
				$envVars += [PSCustomObject]@{
					Name  = $name
					Value = $value
				}
			}
		}

		return $envVars
	} catch {
		Write-Error "Error retrieving environment variables from Bitwarden: $_"
		return @()
	} finally {
		# Clear the session from environment
		$env:BW_SESSION = $null
	}
}

function Get-BitwardenItemFields {
	param (
		[Parameter(Mandatory = $true)]
		[string]$ItemName
	)

	# Get the session key
	$sessionKey = Initialize-BitwardenAuth

	if (!$sessionKey) {
		Write-Error "No Bitwarden session available"
		return "{}"
	}

	# Set the session environment variable
	$env:BW_SESSION = $sessionKey

	try {
		# Search for the item
		$items = bw list items --search $ItemName | ConvertFrom-Json

		if ($items.Count -eq 0) {
			Write-Error "No item found with name: $ItemName"
			return "{}"
		}

		$item = $items | Where-Object { $_.name -eq $ItemName } | Select-Object -First 1

		if (!$item) {
			Write-Error "No exact match found for item: $ItemName"
			return "{}"
		}

		# Create a hashtable of fields
		$fields = @{}

		# Add custom fields
		foreach ($field in $item.fields) {
			$fields[$field.name] = $field.value
		}

		# Add standard fields if they exist
		if ($item.login) {
			$fields["username"] = $item.login.username
			$fields["password"] = $item.login.password
			$fields["totp"] = $item.login.totp
		}

		if ($item.notes) {
			$fields["notes"] = $item.notes
		}

		# Convert to JSON and return
		return $fields | ConvertTo-Json
	} catch {
		Write-Error "Error retrieving item fields from Bitwarden: $_"
		return "{}"
	} finally {
		# Clear the session from environment
		$env:BW_SESSION = $null
	}
}

function Get-BitwardenAttachment {
	param (
		[Parameter(Mandatory = $true)]
		[string]$ItemName,

		[Parameter(Mandatory = $true)]
		[string]$AttachmentName,

		[Parameter(Mandatory = $false)]
		[string]$OutputPath
	)

	# Get the session key
	$sessionKey = Initialize-BitwardenAuth

	if (!$sessionKey) {
		Write-Error "No Bitwarden session available"
		return $null
	}

	# Set the session environment variable
	$env:BW_SESSION = $sessionKey

	try {
		# Search for the item
		$items = bw list items --search $ItemName | ConvertFrom-Json

		if ($items.Count -eq 0) {
			Write-Error "No item found with name: $ItemName"
			return $null
		}

		$item = $items | Where-Object { $_.name -eq $ItemName } | Select-Object -First 1

		if (!$item) {
			Write-Error "No exact match found for item: $ItemName"
			return $null
		}

		# Find the attachment
		$attachment = $item.attachments | Where-Object { $_.fileName -eq $AttachmentName } | Select-Object -First 1

		if (!$attachment) {
			Write-Error "No attachment found with name: $AttachmentName in item: $ItemName"
			return $null
		}

		# If no output path is specified, return the attachment content
		if (!$OutputPath) {
			$tempFile = [System.IO.Path]::GetTempFileName()
			bw get attachment $attachment.id --itemid $item.id --output $tempFile
			$content = Get-Content -Path $tempFile -Raw
			Remove-Item -Path $tempFile -Force
			return $content
		} else {
			# Save the attachment to the specified path
			bw get attachment $attachment.id --itemid $item.id --output $OutputPath
			return $OutputPath
		}
	} catch {
		Write-Error "Error retrieving attachment from Bitwarden: $_"
		return $null
	} finally {
		# Clear the session from environment
		$env:BW_SESSION = $null
	}
}

function Get-BitwardenSecureNote {
	param (
		[Parameter(Mandatory = $true)]
		[string]$ItemName
	)

	# Get the session key
	$sessionKey = Initialize-BitwardenAuth

	if (!$sessionKey) {
		Write-Error "No Bitwarden session available"
		return $null
	}

	# Set the session environment variable
	$env:BW_SESSION = $sessionKey

	try {
		# Search for the item
		$items = bw list items --search $ItemName | ConvertFrom-Json

		if ($items.Count -eq 0) {
			Write-Error "No item found with name: $ItemName"
			return $null
		}

		$item = $items | Where-Object { $_.name -eq $ItemName } | Select-Object -First 1

		if (!$item) {
			Write-Error "No exact match found for item: $ItemName"
			return $null
		}

		# Return the notes
		if ($item.notes) {
			return $item.notes
		} else {
			Write-Error "Item does not contain notes: $ItemName"
			return $null
		}
	} catch {
		Write-Error "Error retrieving secure note from Bitwarden: $_"
		return $null
	} finally {
		# Clear the session from environment
		$env:BW_SESSION = $null
	}
}

# Export functions
Export-ModuleMember -Function Initialize-BitwardenAuth, Get-BitwardenSecret, Get-BitwardenEnvironmentVariables, Get-BitwardenItemFields, Get-BitwardenAttachment, Get-BitwardenSecureNote
