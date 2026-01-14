---
title: Volumes & Data
permalink: /configuration/volumes
---

# Volumes & Data

Understanding the server's directory structure and data persistence.

## Data Volume

The `/data` volume contains all server data:

```bash
-v ./hytale-data:/data
```

> **Important:** Always mount a volume to `/data` to persist your server data across container restarts.

## Directory Structure

```
/data/
├── config.json                        # Server configuration (auto-generated)
├── HytaleServer.jar                   # Server executable (auto-downloaded)
├── Assets.zip                         # Game assets (auto-downloaded)
├── HytaleServer.aot                   # AOT cache (for faster startup)
├── .hytale-downloader-credentials.json # Download OAuth tokens
├── .hytale-server-credentials.json    # Server OAuth tokens
├── universe/                          # World data
│   └── worlds/
│       └── default/                   # Default world
├── mods/                              # Server mods (.zip or .jar)
├── logs/                              # Server logs
├── backups/                           # Automatic backups
├── bans.json                          # Banned players
├── whitelist.json                     # Whitelisted players
└── permissions.json                   # Player permissions
```

## Important Files

### config.json

Server configuration. Auto-generated from environment variables unless `SKIP_CONFIG_UPDATE=true`.

### universe/

Contains all world data. **Back this up regularly!**

### mods/

Place mod files (`.zip` or `.jar`) here. The server will load them automatically.

### Credential Files

OAuth tokens that persist authentication across restarts:
- `.hytale-downloader-credentials.json` - Download authorization
- `.hytale-server-credentials.json` - Server authentication

## Backup Strategy

Recommended backup approach:

```bash
# Stop the server first for consistency
docker compose stop

# Backup the data directory
tar -czf backup-$(date +%Y%m%d).tar.gz hytale-data/

# Restart
docker compose start
```

Or use the built-in backup feature:

```yaml
environment:
  - ENABLE_BACKUP=true
  - BACKUP_FREQUENCY=60  # Every hour
```
