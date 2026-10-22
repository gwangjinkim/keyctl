# keyctl

CLI tool to store API keys in the OS credential store (Keychain, Secret Service,
Credential Manager) and serve them over a local HTTP API — no more hard-coding
secrets in scripts, configs, or `.env` files.

> **Keep secrets out of your source tree.** `keyctl` writes each key to your
> operating system's native credential store and reads it back on demand,
> whether you're running from the shell, Python, Node, or a Pi coding-agent
> session.

## Table of contents

- [What is keyctl?](README.md#what-is-keyctl)
- [Why use keyctl?](README.md#why-use-keyctl)
- [Installation](README.md#installation)
- [CLI reference](README.md#cli-reference)
  - [`keyctl add`](README.md#keyctl-add)
  - [`keyctl get`](README.md#keyctl-get)
  - [`keyctl list`](README.md#keyctl-list)
  - [`keyctl remove`](README.md#keyctl-remove)
  - [`keyctl daemon`](README.md#keyctl-daemon)
- [HTTP daemon mode](README.md#http-daemon-mode)
  - [Authentication](README.md#authentication)
  - [Endpoints](README.md#endpoints)
- [Integration examples](README.md#integration-examples)
  - [Pi coding-agent session](README.md#pi-coding-agent-session)
  - [Python](README.md#python)
  - [Node / JavaScript](README.md#node-javascript)
  - [Shell one-liner (pipe to pbcopy)](README.md#shell-one-liner-pipe-to-pbcopy)
- [Security](README.md#security)
- [Docker / advanced](README.md#docker-advanced)
- [License](README.md#license)

## What is keyctl?

`keyctl` is a small, dependency-free CLI (`#!/usr/bin/env python3`) that stores
API keys in your operating system's native credential store instead of in local
files:

| Platform | Backend | Storage location |
|----------|---------|------------------|
| macOS | Keychain (`security`) | `keyctl:{keyword}` generic password items |
| Linux | Secret Service DBus (`secret-tool`) | Per-item attributes in the Secret Service DB |
| Windows / WSL | Credential Manager (`cmdkey`) | Generic credentials |

Keys are never written to plaintext files on disk. Each key is stored under a
**keyword** (a short name you choose, like `gemini` or `github`), and retrieved
by that same keyword.

## Why use keyctl?

- **Never hard-code secrets.** No API keys in scripts, `models.json`,
  `.env` files, or CI configs.
- **Cross-platform.** One command works on macOS, Linux, and Windows/WSL.
- **Callable from anywhere.** Shell, Python, Node, or a Pi coding-agent tool
  can all read a key without knowing where it lives.
- **Optional HTTP daemon.** Expose keys over a local loopback API so long-running
  processes (servers, agents, IDEs) can fetch keys without spawning a subprocess.
- **Audit and rotate.** List keywords, remove individual keys, and rotate
  compromised credentials in one command.

## Installation

### Option 1: Clone and `make install` (recommended)

```bash
git clone https://github.com/your-repo/keyctl.git
cd keyctl
make install
```

`make install` copies the `keyctl` script into `~/.local/bin` (or `~/bin`).
Make sure that directory is on your `PATH`:

```bash
export PATH="$HOME/.local/bin:$PATH"
# add the line above to your ~/.bashrc, ~/.zshrc, or equivalent
```

Then verify:

```bash
keyctl --help
```

### Option 2: Manual PATH copy

If you don't have `make`, just copy the script somewhere on your `PATH`:

```bash
# macOS / Linux
cp keyctl ~/.local/bin/keyctl
chmod +x ~/.local/bin/keyctl

# Windows (Git Bash / WSL)
cp keyctl ~/bin/keyctl
chmod +x ~/bin/keyctl
```

### Optional package hints

There is no official Homebrew or Linux distro package yet. You can create one
from the single-file `keyctl` script:

- **Homebrew (macOS/Linux):** write a Ruby formula that copies `keyctl` into
  the Homebrew prefix `bin` directory.
- **Linux package:** install `keyctl` to `/usr/local/bin` and ensure
  `secret-tool` (libsecret) is available on the system.

## CLI reference

Every subcommand prints a short status message on success and exits non-zero on
failure.

### `keyctl add`

Store a key under a keyword. You can pass the value with `--value`, read it
from stdin with `--stdin`, or be prompted interactively.

```bash
# Interactive prompt (recommended — value never touches shell history)
keyctl add gemini

# Pass value inline (value appears in process list/shell history — use with care)
keyctl add github --value ghp_xxxxxxxxxxxx

# Pipe from stdin
echo "sk-..." | keyctl add openai --stdin
```

### `keyctl get`

Print the stored key for a keyword to stdout.

```bash
keyctl get gemini
```

Capture into a shell variable:

```bash
GEMINI_API_KEY=$(keyctl get gemini)
```

### `keyctl list`

List all stored keywords.

```bash
keyctl list
```

Example output:

```
gemini
github
openai
```

### `keyctl remove`

Delete the stored key for a keyword.

```bash
keyctl remove gemini
```

### `keyctl daemon`

Start the local HTTP API daemon.

```bash
# Default: binds to 127.0.0.1:9099
KEYCTL_TOKEN=my-secret-token keyctl daemon

# Custom port
KEYCTL_TOKEN=my-secret-token keyctl daemon --port 9099
```

The `--port` option sets the TCP port (default `9099`). The token is read from
the `KEYCTL_TOKEN` environment variable — see [Authentication](#authentication).

## HTTP daemon mode

The daemon is a small threaded HTTP server useful for long-running processes
that need key lookups without spawning `keyctl` on every request.

- **Default bind:** `127.0.0.1:9099` (loopback only)
- **Custom port:** `keyctl daemon --port <port>`
- **Auth:** every request must include `Authorization: Bearer <token>`, where
  `<token>` is the value of the `KEYCTL_TOKEN` environment variable seen by the
  daemon process. If `KEYCTL_TOKEN` is unset, all requests return `401`.

Start it in the background:

```bash
export KEYCTL_TOKEN=$(openssl rand -hex 16)
nohup keyctl daemon --port 9099 > keyctl-daemon.log 2>&1 &
```

### Authentication

```bash
export KEYCTL_TOKEN=my-secret-token
keyctl daemon --port 9099
```

All client requests must send:

```
Authorization: Bearer my-secret-token
```

Set `KEYCTL_TOKEN` to a strong, random value and restrict the file where you
keep it (see [Recommended file modes](#recommended-file-modes)).

### Endpoints

| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/health` | Health check |
| `GET` | `/list` | List stored keywords |
| `POST` | `/lookup` | Look up a key by keyword |
| `POST` | `/add` | Store a keyword/key pair |
| `DELETE` | `/remove` | Remove a keyword |

#### `GET /health`

```bash
curl -s -H "Authorization: Bearer $KEYCTL_TOKEN" \
  http://127.0.0.1:9099/health
```

Response:

```json
{"status": "ok"}
```

#### `GET /list`

```bash
curl -s -H "Authorization: Bearer $KEYCTL_TOKEN" \
  http://127.0.0.1:9099/list
```

Response:

```json
{"keywords": ["gemini", "github", "openai"]}
```

#### `POST /lookup`

```bash
curl -s -X POST -H "Authorization: Bearer $KEYCTL_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"keyword":"gemini"}' \
  http://127.0.0.1:9099/lookup
```

Response:

```json
{"keyword": "gemini", "key": "sk-..."}
```

#### `POST /add`

```bash
curl -s -X POST -H "Authorization: Bearer $KEYCTL_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"keyword":"gemini","key":"sk-..."}' \
  http://127.0.0.1:9099/add
```

Response:

```json
{"status": "stored"}
```

#### `DELETE /remove`

```bash
curl -s -X DELETE -H "Authorization: Bearer $KEYCTL_TOKEN" \
  "http://127.0.0.1:9099/remove?keyword=gemini"
```

Response:

```json
{"status": "removed"}
```

## Integration examples

### Pi coding-agent session

From a Pi coding-agent session you can shell out to `keyctl` to fetch a key
without hard-coding it, or inject it into the agent's model configuration.

**Shell out from a Pi tool:**

```bash
GEMINI_KEY=$(keyctl get gemini)
```

**Read the token into `$GEMINI_API_KEY`:**

```bash
export GEMINI_API_KEY=$(keyctl get gemini)
```

**Inject into `models.json`** (Pi model config):

```bash
KEY=$(keyctl get gemini)
python3 - "$KEY" <<'PY'
import json, sys
key = sys.argv[1]
with open("models.json") as f:
    cfg = json.load(f)
cfg.setdefault("models", {}).setdefault("gemini", {})["apiKey"] = key
with open("models.json", "w") as f:
    json.dump(cfg, f, indent=2)
PY
```

> Tip: keep `models.json` out of version control (add it to `.gitignore`).

### Python

**Via the HTTP daemon (`requests`):**

```python
import os
import requests

TOKEN = os.environ["KEYCTL_TOKEN"]
BASE = "http://127.0.0.1:9099"
headers = {"Authorization": f"Bearer {TOKEN}"}

# Look up a key
resp = requests.post(f"{BASE}/lookup", headers=headers,
                     json={"keyword": "gemini"})
resp.raise_for_status()
api_key = resp.json()["key"]

# List all keywords
resp = requests.get(f"{BASE}/list", headers=headers)
print(resp.json()["keywords"])
```

**Via subprocess (`keyctl get ...`):**

```python
import subprocess

def get_key(keyword: str) -> str:
    result = subprocess.run(
        ["keyctl", "get", keyword],
        capture_output=True, text=True, check=True,
    )
    return result.stdout.strip()

api_key = get_key("gemini")
```

### Node / JavaScript

**Via `fetch` to the daemon:**

```javascript
const TOKEN = process.env.KEYCTL_TOKEN;
const BASE = "http://127.0.0.1:9099";

async function getKey(keyword) {
  const res = await fetch(`${BASE}/lookup`, {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${TOKEN}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({ keyword }),
  });
  if (!res.ok) throw new Error(await res.text());
  const data = await res.json();
  return data.key;
}

const apiKey = await getKey("gemini");
console.log(apiKey);
```

### Shell one-liner (pipe to pbcopy)

Copy a key to the clipboard (macOS `pbcopy`, Linux `xclip`/`wl-copy`, Windows
`clip.exe`):

```bash
# macOS
keyctl get gemini | pbcopy

# Linux (X11)
keyctl get gemini | xclip -selection clipboard

# Linux (Wayland)
keyctl get gemini | wl-copy

# Windows / WSL
keyctl.exe get gemini | clip.exe
```

## Security

### Backend usage

| Platform | Mechanism | Item name |
|----------|-----------|-----------|
| macOS | Keychain (`security add-generic-password`) | `keyctl:{keyword}` |
| Linux | Secret Service DBus (`secret-tool store`) | attribute `keyctl:{keyword}` |
| Windows / WSL | Credential Manager (`cmdkey`) | generic credential `API:{keyword}` |

Keys are never written to plaintext files outside the OS credential store.

### Per-keyword storage model

Each key is stored independently under its keyword. There is no master vault
file. Listing (`keyctl list`) returns only keywords — never values. To read a
value you must request it by keyword.

### Recommended file modes

If you store `KEYCTL_TOKEN` in a file (e.g. for `direnv` or a systemd unit),
restrict it to owner read/write only:

```bash
chmod 600 /path/to/keyctl-token.env
```

Never put a real token or API key in a file that is world-readable or checked
into version control.

### Rotating keys

1. Remove the old credential: `keyctl remove <keyword>`
2. Store the new credential: `keyctl add <keyword>` (or via `POST /add`)
3. Restart any long-running process holding the old key so it picks up the new
   value on its next lookup.

Rotate immediately if you suspect a key was committed, logged, or exposed.

### Warning: do not commit real keys

Never add real API keys, tokens, or secrets to git:

```bash
# Do NOT do this
echo "sk-..." > key.txt
git add key.txt
```

Add secrets files to `.gitignore`:

```gitignore
*.env
keyctl-token.env
models.json
```

If a real key is accidentally committed, treat it as compromised: revoke it in
the provider's dashboard, remove it from git history, and store a fresh key via
`keyctl add`.

## Docker / advanced

A minimal Docker image is provided at `docker/Dockerfile` for running the
daemon in a container:

```bash
docker build -t keyctl -f docker/Dockerfile .
docker run -e KEYCTL_TOKEN=my-secret-token -p 9099:9099 keyctl daemon --port 9099
```

Mount your host credential store into the container if the daemon needs to
read existing keys; otherwise the container starts with an empty store.

## License

MIT