# Bitwarden Integration for Chezmoi

This repository contains documentation and implementation guides for integrating Bitwarden with chezmoi to securely store and retrieve sensitive information such as API keys, environment variables, and configuration values.

## Documentation

1. [**Integration Plan**](bitwarden-integration-plan.md) - Overview of the integration plan and architecture
2. [**Implementation Guide**](bitwarden-implementation-guide.md) - Detailed implementation instructions for the Bitwarden helper functions
3. [**Chezmoi Configuration**](chezmoi-bitwarden-config.md) - How to modify the `.chezmoi.toml.tmpl` file to integrate with Bitwarden
4. [**Setup Script**](setup-script-bitwarden.md) - How to modify the `setup_win.ps1` script to integrate with Bitwarden
5. [**Item Structure**](bitwarden-item-structure.md) - How to structure your Bitwarden vault for use with the integration
6. [**Template Examples**](bitwarden-template-examples.md) - Examples of how to use Bitwarden with chezmoi templates
7. [**Integration Summary**](bitwarden-integration-summary.md) - Summary of the integration and step-by-step guide for implementation

## Quick Start

1. Install Bitwarden CLI: `scoop install bitwarden-cli`
2. Create Bitwarden account at [bitwarden.com](https://bitwarden.com)
3. Set up Bitwarden vault structure (see [Item Structure](bitwarden-item-structure.md))
4. Add helper functions to `~/.config/bitwarden/functions.ps1`
5. Update `.chezmoi.toml.tmpl` (see [Chezmoi Configuration](chezmoi-bitwarden-config.md))
6. Update `setup_win.ps1` (see [Setup Script](setup-script-bitwarden.md))
7. Create templates using Bitwarden (see [Template Examples](bitwarden-template-examples.md))

## Features

- Secure storage of sensitive information in Bitwarden's encrypted vault
- Seamless integration with chezmoi's template system
- Automatic setting of environment variables from Bitwarden
- Fallback mechanism for backward compatibility with `env.json`
- Cross-platform support for Windows, macOS, and Linux

## Security Considerations

- Bitwarden credentials are stored securely using PowerShell's `Export-Clixml`
- Session keys are stored in memory only when needed
- Secure strings are used for passwords
- Plain text passwords are cleared from memory as soon as possible

## Requirements

- Bitwarden CLI (`bw`)
- PowerShell 7+
- Chezmoi
- Windows Credential Manager (for Windows)

## License

This project is licensed under the MIT License - see the LICENSE file for details.
