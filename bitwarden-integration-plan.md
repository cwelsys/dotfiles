# Bitwarden Integration Plan for Chezmoi

## Overview

This document outlines the plan for integrating Bitwarden with chezmoi to securely store and retrieve API keys and other sensitive information. The integration will allow chezmoi to fetch secrets from Bitwarden during template rendering and setup.

## Current Setup

- Chezmoi is configured with age encryption
- Environment variables are currently defined in `env.json` (which is encrypted with SOPS)
- The setup script (`setup_win.ps1`) decrypts this file and sets environment variables

## Proposed Solution

We'll implement a Bitwarden-based approach that:

1. Prompts for Bitwarden credentials during first-time setup
2. Securely stores credentials in Windows Credential Manager
3. Uses Bitwarden CLI to retrieve secrets during template rendering
4. Integrates with chezmoi's template system

## Implementation Steps

### 1. Modify `.chezmoi.toml.tmpl`

Add Bitwarden configuration to the chezmoi config template:

```toml
[bitwarden]
    enabled = true
    # Store the session key securely
```

### 2. Create Bitwarden Helper Functions

Create a PowerShell module with Bitwarden helper functions:

```powershell
# .chezmoitemplates/bitwarden/functions.ps1
function Get-BitwardenSecret {
    param (
        [string]$ItemId,
        [string]$Field
    )
    # Retrieve secret from Bitwarden
}

function Initialize-BitwardenSession {
    # Login to Bitwarden and create session
}
```

### 3. Update Setup Script

Modify `setup_win.ps1` to:

- Check if Bitwarden CLI is installed
- Install it if missing
- Prompt for Bitwarden credentials
- Store credentials securely
- Initialize a Bitwarden session

### 4. Create Template Functions

Create template functions for chezmoi to use in templates:

```
{{ bitwarden "item-name" "field-name" }}
```

### 5. Update Environment Variable Handling

Replace the current environment variable setup with Bitwarden-based retrieval:

```powershell
function Set-UserEnvironmentVariables {
    # Get environment variables from Bitwarden
    $envVars = Get-BitwardenEnvironmentVariables

    foreach ($variable in $envVars) {
        # Set environment variables
    }
}
```

### 6. Document Bitwarden Item Structure

Create documentation for how to structure Bitwarden items:

- Create a "Dotfiles" folder in Bitwarden
- Store API keys as secure notes with specific field names
- Use consistent naming conventions

## Security Considerations

- Bitwarden credentials will be stored in Windows Credential Manager
- Session keys will be short-lived
- No secrets will be stored in plain text
- All template rendering happens locally

## Testing Plan

1. Test Bitwarden CLI installation
2. Test credential storage and retrieval
3. Test template rendering with Bitwarden secrets
4. Test environment variable setup

## Rollout Plan

1. Implement and test locally
2. Create documentation
3. Update the repository
4. Test on a fresh Windows installation

## Fallback Mechanism

If Bitwarden integration fails, the script will fall back to:

1. Prompting the user for required secrets
2. Storing them temporarily for the current session
