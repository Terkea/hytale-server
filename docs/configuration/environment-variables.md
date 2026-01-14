---
title: Environment Variables
permalink: /configuration/environment-variables
---

# Environment Variables

Complete list of all supported environment variables.

## Server Settings

| Variable | Default | Description |
|----------|---------|-------------|
| `SERVER_NAME` | `Hytale Server` | Server name shown to players |
| `MOTD` | `""` | Message displayed on player login |
| `PASSWORD` | `""` | Server password (empty = public) |
| `MAX_PLAYERS` | `100` | Maximum concurrent players |
| `MAX_VIEW_RADIUS` | `12` | View distance in chunks |
| `DEFAULT_WORLD` | `default` | Default world loaded at startup |
| `DEFAULT_GAMEMODE` | `Adventure` | Initial game mode for players |

## Memory / JVM Settings

| Variable | Default | Description |
|----------|---------|-------------|
| `MEMORY` | `4G` | Java heap size (sets both Xms and Xmx) |
| `INIT_MEMORY` | `${MEMORY}` | Initial heap size (-Xms) |
| `MAX_MEMORY` | `${MEMORY}` | Maximum heap size (-Xmx) |
| `JVM_OPTS` | `""` | Additional JVM arguments |
| `JVM_XX_OPTS` | `""` | Additional -XX JVM arguments |
| `USE_AOT_CACHE` | `true` | Use AOT cache for faster startup |

## Network Settings

| Variable | Default | Description |
|----------|---------|-------------|
| `SERVER_PORT` | `5520` | UDP port for connections |
| `BIND_ADDRESS` | `0.0.0.0` | Network bind address |

## User / Permissions

| Variable | Default | Description |
|----------|---------|-------------|
| `UID` | `1000` | Linux user ID for file ownership |
| `GID` | `1000` | Linux group ID for file ownership |
| `TZ` | `UTC` | Container timezone |

## Backup Settings

| Variable | Default | Description |
|----------|---------|-------------|
| `ENABLE_BACKUP` | `false` | Enable automatic backups |
| `BACKUP_FREQUENCY` | `30` | Backup interval in minutes |
| `BACKUP_DIR` | `/data/backups` | Backup storage directory |

## Download Settings

| Variable | Default | Description |
|----------|---------|-------------|
| `AUTO_DOWNLOAD` | `true` | Auto-download server files |
| `AUTO_UPDATE` | `true` | Check for updates on start |
| `PATCHLINE` | `release` | Hytale patchline to use |
| `SKIP_DOWNLOAD` | `false` | Skip download entirely |

## Config Settings

| Variable | Default | Description |
|----------|---------|-------------|
| `OVERRIDE_CONFIG` | `true` | Regenerate config.json on start |
| `SKIP_CONFIG_UPDATE` | `false` | Never modify config.json |

## Advanced / Authentication

| Variable | Default | Description |
|----------|---------|-------------|
| `HYTALE_SERVER_SESSION_TOKEN` | `""` | Pre-authenticated session token |
| `HYTALE_SERVER_IDENTITY_TOKEN` | `""` | Pre-authenticated identity token |
| `OWNER_UUID` | `""` | Server owner UUID |
| `DISABLE_SENTRY` | `false` | Disable error reporting |

## Example

```yaml
environment:
  - SERVER_NAME=My Awesome Server
  - MOTD=Welcome to my Hytale server!
  - MAX_PLAYERS=50
  - MAX_VIEW_RADIUS=16
  - MEMORY=8G
  - TZ=America/New_York
  - ENABLE_BACKUP=true
  - BACKUP_FREQUENCY=60
```
