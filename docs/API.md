# API

The HTTP daemon listens on `127.0.0.1:9099`.

All requests require a Bearer token. Set `KEYCTL_TOKEN` environment variable.

## Endpoints

### GET /health

Health check.

```bash
curl -H "Authorization: Bearer $KEYCTL_TOKEN" http://127.0.0.1:9099/health
```

### GET /list

List stored keywords.

```bash
curl -H "Authorization: Bearer $KEYCTL_TOKEN" http://127.0.0.1:9099/list
```

### POST /lookup

Lookup a keyword.

```bash
curl -X POST -H "Authorization: Bearer $KEYCTL_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"keyword":"myapi"}' \
  http://127.0.0.1:9099/lookup
```

### POST /add

Add a keyword/key pair.

```bash
curl -X POST -H "Authorization: Bearer $KEYCTL_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"keyword":"myapi","key":"secret"}' \
  http://127.0.0.1:9099/add
```

### DELETE /remove

Remove a keyword.

```bash
curl -X DELETE -H "Authorization: Bearer $KEYCTL_TOKEN" \
  http://127.0.0.1:9099/remove?keyword=myapi
```
