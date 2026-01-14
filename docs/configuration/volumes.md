---
title: Volumes & Data
layout: default
parent: Configuration
nav_order: 2
---

# Volumes & Data

Understanding the server's directory structure and data persistence.

## Data Volume

The `/data` volume contains all server data:

```bash
-v ./hytale-data:/data
```

{: .important }
Always mount a volume to `/data` to persist your server data across container restarts.

## Directory Structure

```
/data/
├── config.json          # Server configuration (auto-generated)
├── HytaleServer.jar     # Server executable (auto-downloaded)
├── Assets.zip           # Game assets (auto-downloaded)
├── HytaleServer.aot     # AOT cache (optional, for faster startup)
├── universe/            # World data
│   └── worlds/
│       └── default/     # Default world
├── mods/                # Server mods (.zip or .jar)
├── logs/                # Server logs
├── backups/             # Automatic backups
├── bans.json            # Banned players
├── whitelist.json       # Whitelisted players
├── permissions.json     # Player permissions
└── .downloader/         # OAuth credentials cache
```

## Important Files

### config.json

Server configuration. Auto-generated from environment variables unless `SKIP_CONFIG_UPDATE=true`.

### universe/

Contains all world data. **Back this up regularly!**

### mods/

Place mod files (`.zip` or `.jar`) here. The server will load them automatically.

### .downloader/

Stores OAuth tokens from the Hytale Downloader. These persist authentication across restarts.

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
