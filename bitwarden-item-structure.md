# Bitwarden Item Structure for Chezmoi Integration

This document explains how to structure your Bitwarden vault for use with the chezmoi integration.

## Folder Structure

Create the following folders in your Bitwarden vault:

1. **Environment Variables** - For storing environment variables
2. **API Keys** - For storing API keys and tokens
3. **Dotfiles** - For storing configuration values used in dotfiles

## Item Types

### Environment Variables

Environment variables should be stored in the "Environment Variables" folder as Secure Notes.

**Item Structure:**

- **Type:** Secure Note
- **Name:** The environment variable name (e.g., `GITHUB_TOKEN`)
- **Custom Fields:**
  - **Name:** `value`
  - **Type:** Text
  - **Value:** The environment variable value

**Example:**

- **Name:** `EDITOR`
- **Custom Field:** `value` = `nvim`

For path variables, you can use either:

- Absolute paths: `/usr/local/bin`
- Relative paths: `.local/bin` (will be combined with `$HOME`)

### API Keys

API keys should be stored in the "API Keys" folder as Login items.

**Item Structure:**

- **Type:** Login
- **Name:** Descriptive name (e.g., `GitHub API`)
- **Username:** API username or client ID (if applicable)
- **Password:** API key or token
- **Custom Fields:**
  - **Name:** `token_type`
  - **Type:** Text
  - **Value:** Type of token (e.g., `Bearer`)

**Example:**

- **Name:** `GitHub API`
- **Username:** `git@github.com`
- **Password:** `ghp_1234567890abcdefghijklmnopqrstuvwxyz`
- **Custom Field:** `token_type` = `Bearer`

### Configuration Values

Configuration values should be stored in the "Dotfiles" folder as Secure Notes.

**Item Structure:**

- **Type:** Secure Note
- **Name:** Config name (e.g., `Git Config`)
- **Custom Fields:**
  - One field for each configuration value

**Example:**

- **Name:** `Git Config`
- **Custom Fields:**
  - `name` = `cwelsys`
  - `email` = `cwel@cwel.sh`
  - `signing_key` = `1234567890ABCDEF`

## Accessing Items in Chezmoi Templates

### Environment Variables

Environment variables are automatically set during the setup script.

### API Keys in Templates

To access API keys in templates:

```
{{ (bitwardenFields "GitHub API").password }}
```

Or for a specific field:

```
{{ (bitwardenFields "GitHub API").token_type }}
```

### Configuration Values in Templates

To access configuration values in templates:

```
[user]
    name = {{ (bitwardenFields "Git Config").name }}
    email = {{ (bitwardenFields "Git Config").email }}
```

## Example Items

### Example: SSH Config

**Item Name:** `SSH Config`
**Folder:** Dotfiles
**Type:** Secure Note
**Custom Fields:**

- `identityFile` = `~/.ssh/id_ed25519`
- `port` = `22`
- `user` = `cwelsys`

### Example: AWS Credentials

**Item Name:** `AWS`
**Folder:** API Keys
**Type:** Login
**Username:** `AKIAIOSFODNN7EXAMPLE`
**Password:** `wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY`
**Custom Fields:**

- `region` = `us-west-2`
- `output` = `json`

### Example: Database Connection

**Item Name:** `DATABASE_URL`
**Folder:** Environment Variables
**Type:** Secure Note
**Custom Fields:**

- `value` = `postgresql://username:password@localhost:5432/mydb`

## Security Considerations

1. **Master Password:** Use a strong, unique master password for your Bitwarden account
2. **Two-Factor Authentication:** Enable 2FA on your Bitwarden account
3. **Session Management:** The integration stores session keys securely but temporarily
4. **Vault Timeout:** Configure Bitwarden to lock automatically after a period of inactivity
5. **Sensitive Data:** Consider which data truly needs to be in Bitwarden vs. which can be stored in plain text

## Troubleshooting

If you encounter issues with the Bitwarden integration:

1. **Authentication Issues:**

   - Run `bw login` manually to verify your credentials
   - Check if your Bitwarden account is locked with `bw status`

2. **Item Retrieval Issues:**

   - Verify the exact item name with `bw list items --search "Item Name"`
   - Check field names with `bw get item "Item Name"`

3. **Session Issues:**
   - Clear the stored session with `rm ~/.config/bitwarden-session.xml`
   - Re-authenticate with `bw login`
