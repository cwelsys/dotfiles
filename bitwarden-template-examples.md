# Bitwarden Template Examples for Chezmoi

This document provides examples of how to use Bitwarden with chezmoi templates.

## Template Helper Functions

The integration provides the following template functions:

1. `bitwardenFields` - Retrieves all fields from a Bitwarden item
2. `bitwardenSecureNote` - Retrieves a secure note from Bitwarden
3. `bitwardenAttachment` - Retrieves an attachment from a Bitwarden item

## Example: Git Configuration

```toml
# .gitconfig.tmpl
[user]
    email = {{ (bitwardenFields "Git Config").email }}
    name = {{ (bitwardenFields "Git Config").name }}
    {{- if (bitwardenFields "Git Config").signing_key }}
    signingkey = {{ (bitwardenFields "Git Config").signing_key }}
    {{- end }}

{{- if (bitwardenFields "Git Config").signing_key }}
[commit]
    gpgsign = true
{{- end }}

[github]
    {{- if (bitwardenFields "GitHub API").password }}
    token = {{ (bitwardenFields "GitHub API").password }}
    {{- end }}
```

## Example: SSH Config

```
# .ssh/config.tmpl
Host github.com
    User git
    IdentityFile {{ (bitwardenFields "SSH Config").identityFile }}
    {{- if (bitwardenFields "SSH Config").port }}
    Port {{ (bitwardenFields "SSH Config").port }}
    {{- end }}

{{- if (bitwardenFields "SSH Config").custom_hosts }}
{{ (bitwardenFields "SSH Config").custom_hosts }}
{{- end }}
```

## Example: AWS Credentials

```ini
# .aws/credentials.tmpl
[default]
aws_access_key_id = {{ (bitwardenFields "AWS").username }}
aws_secret_access_key = {{ (bitwardenFields "AWS").password }}
{{- if (bitwardenFields "AWS").region }}
region = {{ (bitwardenFields "AWS").region }}
{{- end }}
{{- if (bitwardenFields "AWS").output }}
output = {{ (bitwardenFields "AWS").output }}
{{- end }}
```

## Example: Database Configuration

```yaml
# config/database.yml.tmpl
default: &default
  adapter: postgresql
  encoding: unicode
  pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
  {{- if (bitwardenFields "Database").username }}
  username: {{ (bitwardenFields "Database").username }}
  {{- end }}
  {{- if (bitwardenFields "Database").password }}
  password: {{ (bitwardenFields "Database").password }}
  {{- end }}
  {{- if (bitwardenFields "Database").host }}
  host: {{ (bitwardenFields "Database").host }}
  {{- end }}
  {{- if (bitwardenFields "Database").port }}
  port: {{ (bitwardenFields "Database").port }}
  {{- end }}

development:
  <<: *default
  database: {{ (bitwardenFields "Database").development_db | default "app_development" }}

test:
  <<: *default
  database: {{ (bitwardenFields "Database").test_db | default "app_test" }}

production:
  <<: *default
  database: {{ (bitwardenFields "Database").production_db | default "app_production" }}
```

## Example: API Configuration

```json
# config/api.json.tmpl
{
  "apis": {
    "github": {
      "url": "https://api.github.com",
      "token": "{{ (bitwardenFields "GitHub API").password }}",
      "username": "{{ (bitwardenFields "GitHub API").username }}"
    },
    {{- if (bitwardenFields "Twitter API") }}
    "twitter": {
      "url": "https://api.twitter.com",
      "api_key": "{{ (bitwardenFields "Twitter API").api_key }}",
      "api_secret": "{{ (bitwardenFields "Twitter API").api_secret }}",
      "access_token": "{{ (bitwardenFields "Twitter API").access_token }}",
      "access_token_secret": "{{ (bitwardenFields "Twitter API").access_token_secret }}"
    }
    {{- end }}
  }
}
```

## Example: Environment Variables

```bash
# .env.tmpl
{{- range $item := (bitwarden "items" "Environment Variables") }}
{{ $item.name }}={{ $item.value }}
{{- end }}
```

## Example: NPM Configuration

```ini
# .npmrc.tmpl
{{- if (bitwardenFields "NPM").registry }}
registry={{ (bitwardenFields "NPM").registry }}
{{- end }}
{{- if (bitwardenFields "NPM").token }}
//registry.npmjs.org/:_authToken={{ (bitwardenFields "NPM").token }}
{{- end }}
```

## Example: Conditional Templates

```toml
# config.toml.tmpl
[general]
name = "{{ .name }}"
email = "{{ .email }}"

{{- if (bitwardenFields "Work Config") }}
[work]
email = "{{ (bitwardenFields "Work Config").email }}"
proxy = "{{ (bitwardenFields "Work Config").proxy | default "" }}"
{{- end }}

{{- if (bitwardenFields "Personal Config") }}
[personal]
email = "{{ (bitwardenFields "Personal Config").email }}"
{{- end }}
```

## Example: Complex Configuration

```yaml
# complex-config.yml.tmpl
{{- $config := (bitwardenFields "Application Config") -}}
app:
  name: {{ $config.name | default "My Application" }}
  version: {{ $config.version | default "1.0.0" }}

  database:
    {{- if $config.db_type }}
    type: {{ $config.db_type }}
    {{- else }}
    type: sqlite
    {{- end }}
    {{- if eq $config.db_type "postgresql" }}
    host: {{ $config.db_host | default "localhost" }}
    port: {{ $config.db_port | default "5432" }}
    username: {{ $config.db_username }}
    password: {{ $config.db_password }}
    {{- end }}

  api:
    {{- range $key, $value := $config }}
    {{- if hasPrefix "api_" $key }}
    {{ trimPrefix "api_" $key }}: {{ $value }}
    {{- end }}
    {{- end }}

  features:
    {{- range $key, $value := $config }}
    {{- if hasPrefix "feature_" $key }}
    {{ trimPrefix "feature_" $key }}: {{ $value }}
    {{- end }}
    {{- end }}
```

## Example: Multi-Environment Configuration

```yaml
# config.yml.tmpl
{{- $env := env "ENVIRONMENT" | default "development" -}}
{{- $config := (bitwardenFields (printf "%s Config" $env)) -}}

environment: {{ $env }}

database:
  url: {{ $config.database_url }}

api:
  key: {{ $config.api_key }}
  endpoint: {{ $config.api_endpoint }}

logging:
  level: {{ $config.log_level | default "info" }}

{{- if eq $env "production" }}
monitoring:
  enabled: true
  service: {{ $config.monitoring_service | default "prometheus" }}
{{- else }}
monitoring:
  enabled: false
{{- end }}
```

## Best Practices

1. **Default Values**: Always provide default values for optional fields

   ```
   {{ (bitwardenFields "Config").field | default "default value" }}
   ```

2. **Existence Checks**: Check if an item exists before using it

   ```
   {{- if (bitwardenFields "Optional Config") }}
   # Use the config
   {{- end }}
   ```

3. **Field Existence Checks**: Check if a field exists before using it

   ```
   {{- if (bitwardenFields "Config").optional_field }}
   optional_field = {{ (bitwardenFields "Config").optional_field }}
   {{- end }}
   ```

4. **Environment-Specific Configs**: Use environment variables to select different configs

   ```
   {{- $env := env "ENVIRONMENT" | default "development" -}}
   {{- $config := (bitwardenFields (printf "%s Config" $env)) -}}
   ```

5. **Reuse Variables**: Store complex lookups in variables
   ```
   {{- $git := (bitwardenFields "Git Config") -}}
   name = {{ $git.name }}
   email = {{ $git.email }}
   ```
