# keyctl

CLI tool to store API keys in the OS credential store (Keychain, Secret Service, Credential Manager).

## Installation

```bash
git clone https://github.com/your-repo/keyctl.git
cd keyctl
make install
```

Or copy the `keyctl` script to a directory in your PATH.

## Usage

```bash
# Add a key
keyctl add myapi github_pat

# Get a key
keyctl get myapi

# List keys
keyctl list

# Remove a key
keyctl remove myapi

# Start HTTP daemon (requires KEYCTL_TOKEN env var)
keyctl daemon --port 9099
```

## Security Notes

- Keys are stored in the OS credential store using platform-appropriate APIs.
- For HTTP daemon mode, set `KEYCTL_TOKEN` environment variable for authentication.
- The daemon binds to `127.0.0.1:9099` by default.

## License

MIT