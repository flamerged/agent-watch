# Security Policy

## Supported Versions

Security fixes target the latest version on the default branch.

## Reporting A Vulnerability

Please report security issues privately through GitHub Security Advisories if available, or by opening a minimal issue that does not include secrets.

## Local Data Handling

Agent Watch inspects local process metadata, selected local configuration files, and local HTTP endpoints. It does not transmit telemetry. Process command output is hidden by default. If command output is enabled, it is redacted before display, but redaction should be treated as a guardrail rather than a guarantee.
