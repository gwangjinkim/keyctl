# Security

## Encryption

keyctl stores API keys directly in the OS credential store rather than in local plaintext files:

- **macOS**: Keychain (`security` command) — `keyctl:{keyword}` generic password items
- **Linux**: Secret Service DBus (`secret-tool`) — per-item attributes
- **Windows**: Credential Manager (`cmdkey`) — generic credentials

Keys are never written to disk outside the OS store.

## Authentication

The optional HTTP daemon requires `KEYCTL_TOKEN` environment variable.
All endpoints validate `Authorization: Bearer <token>`.

## Revocation

Use `keyctl remove <keyword>` to delete a credential item immediately.
Rotate compromised credentials after removal.

## Binding

The daemon binds to `127.0.0.1:9099` (loopback only).