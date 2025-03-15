# Bitwarden Integration for Chezmoi

This document provides instructions for using the Bitwarden integration with chezmoi.

## Overview

The Bitwarden integration allows you to securely store and retrieve sensitive information such as API keys, environment variables, and configuration values using Bitwarden's secure vault. This integration replaces the previous approach of storing encrypted environment variables in an `env.json` file.

## Setup

The integration is set up automatically when you run the `setup_win.ps1` script. The script will:

1. Install Bitwarden CLI (`bw`) if it's not already installed
2. Prompt you to authenticate with Bitwarden
3. Create the necessary folders in your Bitwarden vault
4. Configure chezmoi to use Bitwarden for templates

## Usage

### Storing Secrets in Bitwarden

Follow these guidelines for storing secrets in Bitwarden:

1. **Environment Variables**:

   - Create a folder named "Environment Variables" in Bitwarden
   - Create secure notes with the name of the environment variable
   - Add a custom field named "value" with the value of the environment variable

2. **API Keys**:

   - Create a folder named "API Keys" in Bitwarden
   - Create login items with the name of the API
   - Store the API key in the password field
   - Add custom fields for additional information

3. **Configuration Values**:
   - Create a folder named "Dotfiles" in Bitwarden
   - Create secure notes with descriptive names (e.g., "Git Config")
   - Add custom fields for each configuration value

### Using Secrets in Templates

You can use Bitwarden secrets in your chezmoi templates using the following methods:

#### Direct PowerShell Command

```
{{- with (output "pwsh" "-NoProfile" "-Command" (printf ". \"%s/.chezmoitemplates/bitwarden/functions.ps1\"; Get-BitwardenItemFields -ItemName \"Item Name\"" .chezmoi.sourceDir) | fromJson) }}
{{- if .field_name }}
field_name = {{ .field_name }}
{{- end }}
{{- end }}
```

#### Environment Variables

Environment variables stored in the "Environment Variables" folder in Bitwarden will be automatically set by the setup script.

### Example Templates

The following example templates demonstrate how to use Bitwarden with chezmoi:

- `dot_gitconfig.tmpl`: Git configuration with GitHub and GitLab tokens
- `dot_ssh/config.tmpl`: SSH configuration with custom hosts
- `dot_env.tmpl`: Environment variables for shell sessions
- `dot_config/powershell/Microsoft.PowerShell_profile.ps1.tmpl`: PowerShell profile with Bitwarden helper functions

## PowerShell Helper Functions

The integration includes several PowerShell helper functions for working with Bitwarden:

- `Initialize-BitwardenAuth`: Authenticates with Bitwarden and returns a session key
- `Get-BitwardenSecret`: Retrieves a secret from Bitwarden
- `Get-BitwardenEnvironmentVariables`: Retrieves environment variables from Bitwarden
- `Get-BitwardenItemFields`: Retrieves all fields from a Bitwarden item
- `Get-BitwardenAttachment`: Retrieves an attachment from a Bitwarden item
- `Get-BitwardenSecureNote`: Retrieves a secure note from Bitwarden

These functions are available in your PowerShell profile if you use the provided template.

## Troubleshooting

If you encounter issues with the Bitwarden integration:

1. **Authentication Issues**:

   - Run `bw login` manually to verify your credentials
   - Check if your Bitwarden account is locked with `bw status`

2. **Item Retrieval Issues**:

   - Verify the exact item name with `bw list items --search "Item Name"`
   - Check field names with `bw get item "Item Name"`

3. **Session Issues**:
   - Clear the stored session with `rm ~/.config/bitwarden-session.xml`
   - Re-authenticate with `bw login`

## Security Considerations

1. **Master Password**: Use a strong, unique master password for your Bitwarden account
2. **Two-Factor Authentication**: Enable 2FA on your Bitwarden account
3. **Session Management**: The integration stores session keys securely but temporarily
4. **Vault Timeout**: Configure Bitwarden to lock automatically after a period of inactivity

## Fallback Mechanism

If Bitwarden integration fails, the setup script includes a fallback mechanism that will use `env.json` if it exists, allowing for a smooth transition.

## Additional Resources

- [Bitwarden CLI Documentation](https://bitwarden.com/help/cli/)
- [Chezmoi Documentation](https://www.chezmoi.io/docs/reference/)
- [Bitwarden Integration Guide](bitwarden-implementation-guide.md)
