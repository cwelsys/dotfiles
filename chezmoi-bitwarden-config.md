# Chezmoi Bitwarden Configuration

This document shows how to modify the `.chezmoi.toml.tmpl` file to integrate with Bitwarden.

## Modified `.chezmoi.toml.tmpl`

```toml
{{- $email := promptStringOnce . "email" "Email address" -}}
{{- $name := promptStringOnce . "name" "Username" -}}
{{- $useBitwarden := promptBoolOnce . "useBitwarden" "Use Bitwarden for secrets?" -}}

encryption = "age"

[age]
    identity = "~/.config/key.txt"
    recipient = "age1tg4yymck048fyv8dh389dgh6uuhmhnz6pusevndukqlslxru8ctqvne8el"

[git]
    autoCommit = true
    autoPush = true

[data]
    email = {{ $email | quote }}
    name = {{ $name | quote }}
    useBitwarden = {{ $useBitwarden }}

{{- if $useBitwarden }}
[scriptEnv]
    BW_SESSION = "{{ (bitwardenFields "chezmoi" "session").value }}"
{{- end }}

[templateFuncs]
    bitwardenFields = ["pwsh", "-NoProfile", "-Command", ". \"{{ .chezmoi.sourceDir }}/.chezmoitemplates/bitwarden/functions.ps1\"; Get-BitwardenItemFields"]
    bitwardenAttachment = ["pwsh", "-NoProfile", "-Command", ". \"{{ .chezmoi.sourceDir }}/.chezmoitemplates/bitwarden/functions.ps1\"; Get-BitwardenAttachment"]
    bitwardenSecureNote = ["pwsh", "-NoProfile", "-Command", ". \"{{ .chezmoi.sourceDir }}/.chezmoitemplates/bitwarden/functions.ps1\"; Get-BitwardenSecureNote"]
```

## Explanation

1. **User Prompts**:

   - Added a prompt to ask if the user wants to use Bitwarden
   - Keeps existing prompts for email and username

2. **Bitwarden Integration**:

   - Added `useBitwarden` to the data section
   - Added conditional `scriptEnv` section to set the Bitwarden session
   - Added template functions for retrieving Bitwarden data

3. **Template Functions**:
   - `bitwardenFields`: Retrieves fields from a Bitwarden item
   - `bitwardenAttachment`: Retrieves an attachment from a Bitwarden item
   - `bitwardenSecureNote`: Retrieves a secure note from Bitwarden

## PowerShell Helper Functions

These template functions call PowerShell scripts that will be stored in `.chezmoitemplates/bitwarden/functions.ps1`. The implementation of these functions is detailed in the implementation guide.

## Usage in Templates

With this configuration, you can use Bitwarden in your templates like this:

```
# Example .gitconfig.tmpl
[user]
    email = {{ .email }}
    name = {{ .name }}

{{- if .useBitwarden }}
[github]
    token = {{ (bitwardenFields "GitHub" "token").value }}
{{- end }}
```

## Security Considerations

1. The Bitwarden session key is stored in the chezmoi configuration but is not committed to the repository
2. The session key is only valid for the current session
3. The PowerShell functions handle secure strings properly
4. No secrets are stored in plain text in the repository
