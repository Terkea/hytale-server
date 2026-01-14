---
title: Authentication
layout: default
parent: Installation
nav_order: 3
---

# Server Authentication

Hytale requires **two separate OAuth authorizations** on first run. This is a Hytale security requirement - both flows are handled automatically by the container.

## Why Two Logins?

Hytale uses separate OAuth clients with different scopes:

| Client | Scope | Purpose |
|--------|-------|---------|
| `hytale-downloader` | `auth:downloader` | Downloads game files |
| `hytale-server` | `auth:server` | Authenticates server for player connections |

These cannot be combined (Hytale security restriction). **But both credentials are saved** - all future restarts require **zero logins**.

## First-Time Setup

### 1. Start the Container

```bash
docker compose up -d
docker logs -f hytale-server
```

### 2. First OAuth - Download Authorization

You'll see:
```
========================================
  HYTALE DOWNLOADER
========================================
Please visit the following URL to authenticate:
https://oauth.accounts.hytale.com/oauth2/device/verify?user_code=XXXX
Authorization code: XXXX
```

1. Visit the URL shown
2. Log in with your Hytale account
3. Click **Approve**

The download will start automatically after authorization.

### 3. Second OAuth - Server Authorization

After download completes, you'll see:
```
========================================
  SERVER AUTHENTICATION REQUIRED
========================================
  Visit: https://oauth.accounts.hytale.com/oauth2/device/verify?user_code=YYYY
  Code:  YYYY

  Waiting for authorization...
========================================
```

1. Visit the URL shown
2. Log in with your Hytale account (same account)
3. Click **Approve**

### 4. Server Starts

After both authorizations, the server will:
1. Create a game session
2. Start in `AUTHENTICATED` mode
3. Accept player connections

You'll see:
```
[SUCCESS] Server authenticated and ready!
[HytaleServer] Authentication mode: AUTHENTICATED
```

## Credential Persistence

Both credentials are automatically saved and refreshed:

| File | Purpose |
|------|---------|
| `.hytale-downloader-credentials.json` | Download OAuth tokens |
| `.hytale-server-credentials.json` | Server OAuth tokens |

These files are stored in your data volume (`/data/`).

{: .important }
On subsequent restarts, **zero OAuth prompts** - the container automatically refreshes and uses saved tokens.

## Machine ID for Auth Persistence

For reliable token persistence, mount a machine-id file:

```yaml
volumes:
  - ./hytale-data:/data
  - ./machine-id:/etc/machine-id:ro  # Required for auth persistence
```

Create the machine-id file:

```bash
# Linux
cp /etc/machine-id ./machine-id

# Windows/macOS - generate a UUID
uuidgen | tr -d '-' > machine-id
# Or use: echo "$(cat /proc/sys/kernel/random/uuid | tr -d '-')" > machine-id
```

## Skip Download OAuth

If you have server files from your local Hytale installation, you can skip the download OAuth:

```yaml
environment:
  - SKIP_DOWNLOAD=true
volumes:
  - ./hytale-data:/data
  # Copy these files to ./hytale-data/:
  # - HytaleServer.jar
  # - HytaleServer.aot (optional)
  # - Assets.zip
```

This reduces first-time setup to just **one OAuth** (server auth only).

## Token Passthrough (Advanced)

For automated deployments, you can provide pre-generated tokens:

```yaml
environment:
  - HYTALE_SERVER_SESSION_TOKEN=your_session_token
  - HYTALE_SERVER_IDENTITY_TOKEN=your_identity_token
  - OWNER_UUID=your_owner_uuid
```

{: .warning }
Keep your tokens secure. Never commit them to version control.

## Troubleshooting

### Server shows "No server tokens configured"

This means the server OAuth flow failed. Check:
- Did you complete the second OAuth prompt?
- Check logs for API errors
- Delete `.hytale-server-credentials.json` and restart to retry

### OAuth keeps prompting on restart

- Ensure data volume is mounted correctly
- Check if credential files exist in `/data/`
- Verify `machine-id` is mounted for auth persistence

### "Authorization code expired"

- Codes expire after a few minutes
- Restart the container to get a new code

### Download works but server auth fails

- These are separate OAuth flows with different clients
- Server auth requires `auth:server` scope
- Check your Hytale account has game access

## Manual Re-Authentication

If you need to force re-authentication:

```bash
# Remove saved credentials
docker exec hytale-server rm -f /data/.hytale-server-credentials.json
docker exec hytale-server rm -f /data/.hytale-downloader-credentials.json

# Restart container
docker compose restart
```

Or use the in-game console (after server starts):

```
/auth login device
```
