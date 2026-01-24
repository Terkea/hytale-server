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

## Technical Reference

### Token Types

The container manages three types of tokens:

| Token Type | Source | Purpose | Lifetime |
|------------|--------|---------|----------|
| **OAuth Access Token** | `oauth.accounts.hytale.com` | API authentication | ~1 hour |
| **OAuth Refresh Token** | `oauth.accounts.hytale.com` | Refreshes access token | Long-lived |
| **Session Token** | `sessions.hytale.com` | Server game session | ~1 hour |
| **Identity Token** | `sessions.hytale.com` | Player identity verification | ~1 hour |

### UUID Relationships

Hytale uses two different UUIDs that must be understood:

| UUID Type | Description | Example |
|-----------|-------------|---------|
| **Account UUID** | Your Hytale account (the `.owner` field) | `33f0a7f6-2832-494e-91e0-606583f62cb9` |
| **Profile UUID** | Your in-game profile (`.profiles[0].uuid`) | `39ba683d-f53e-43df-82ee-ee104690ee05` |

**Important**: The `--owner-uuid` argument passed to the server must match the **Profile UUID** (not the Account UUID), because:
- Session tokens are created for a specific profile
- The server validates that the token UUID matches the owner UUID

### Credential File Structure

#### `.hytale-downloader-credentials.json`

```json
{
    "access_token": "eyJhbGciOiJSUzI1NiIs...",
    "refresh_token": "ory_rt_...",
    "expires_at": 1769262948,
    "branch": "release"
}
```

| Field | Description |
|-------|-------------|
| `access_token` | JWT for downloading game files |
| `refresh_token` | Token to obtain new access token |
| `expires_at` | Unix timestamp when access token expires |
| `branch` | Patchline (release, beta, etc.) |

#### `.hytale-server-credentials.json`

```json
{
    "access_token": "eyJhbGciOiJSUzI1NiIs...",
    "expires_in": 3599,
    "id_token": "eyJhbGciOiJSUzI1NiIs...",
    "refresh_token": "ory_rt_...",
    "scope": "openid offline auth:server",
    "token_type": "bearer"
}
```

| Field | Description |
|-------|-------------|
| `access_token` | JWT for server API calls |
| `id_token` | OpenID Connect identity token |
| `refresh_token` | Token to obtain new access token |
| `expires_in` | Seconds until access token expires |
| `scope` | OAuth scopes granted |

### JWT Claims

The access tokens contain these relevant claims:

| Claim | Description |
|-------|-------------|
| `sub` | Subject - your Account UUID |
| `client_id` | OAuth client (`hytale-downloader` or `hytale-server`) |
| `scp` | Scopes array |
| `exp` | Expiration timestamp |
| `iss` | Issuer (`https://oauth.accounts.hytale.com`) |

### Authentication Flow

```
1. Container starts
        │
        ▼
2. Check for saved OAuth credentials
   (.hytale-server-credentials.json)
        │
        ├─── No credentials ──► Device Auth Flow
        │                              │
        ▼                              ▼
3. Try create_game_session()      User approves OAuth
   with saved access_token              │
        │                              ▼
        ├─── Token expired ──► Refresh token
        │                              │
        ▼                              ▼
4. GET /my-account/get-profiles
   Returns:
   - .owner (Account UUID)
   - .profiles[0].uuid (Profile UUID)
        │
        ▼
5. POST /game-session/new
   Body: {"uuid": "<Profile UUID>"}
   Returns:
   - sessionToken
   - identityToken
        │
        ▼
6. Start server with:
   --session-token <sessionToken>
   --identity-token <identityToken>
   --owner-uuid <Profile UUID>
```

### API Endpoints

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `oauth.accounts.hytale.com/oauth2/device/auth` | POST | Start device auth flow |
| `oauth.accounts.hytale.com/oauth2/token` | POST | Exchange/refresh tokens |
| `account-data.hytale.com/my-account/get-profiles` | GET | Get account profiles |
| `sessions.hytale.com/game-session/new` | POST | Create game session |
