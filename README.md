# Hytale Server Docker Image

[![Build](https://github.com/terkea/hytale-server/actions/workflows/build.yml/badge.svg)](https://github.com/terkea/hytale-server/actions/workflows/build.yml)
[![Docs](https://github.com/terkea/hytale-server/actions/workflows/docs.yml/badge.svg)](https://terkea.github.io/hytale-server/)

Run your own [Hytale](https://hytale.com/) dedicated server in Docker with minimal setup. This image handles everything automatically: downloading the server files, authenticating with Hytale's OAuth system, and persisting your credentials so you never have to log in again after the first run.

Whether you're hosting a private server for friends or deploying to production, just start the container, complete two quick OAuth prompts, and you're online.

**[Full Documentation](https://terkea.github.io/hytale-server/)** | [FAQ](https://terkea.github.io/hytale-server/faq) | [Configuration](https://terkea.github.io/hytale-server/configuration/)

## Features

- **Auto-download** - Automatically downloads server files using official Hytale Downloader CLI
- **Auto-authentication** - Programmatic OAuth flow for server authentication
- **Persistent credentials** - Both download and server tokens are saved and auto-refreshed
- **Easy configuration** - All settings via environment variables
- **Multi-platform** - Supports `linux/amd64` and `linux/arm64`

## Quick Start

### Using Docker Compose (Recommended)

```yaml
services:
  hytale:
    image: ghcr.io/terkea/hytale-server:latest
    container_name: hytale-server
    ports:
      - "5520:5520/udp"
    environment:
      - SERVER_NAME=My Hytale Server
      - MAX_PLAYERS=50
      - MEMORY=4G
    volumes:
      - ./hytale-data:/data
    stdin_open: true
    tty: true
    restart: unless-stopped
```

Start the server:
```bash
docker compose up -d
docker logs -f hytale-server
```

### Using Docker CLI

```bash
docker run -d --name hytale-server \
  -p 5520:5520/udp \
  -v ./hytale-data:/data \
  -e SERVER_NAME="My Hytale Server" \
  -e MEMORY=4G \
  -it \
  ghcr.io/terkea/hytale-server:latest
```

## First-Time Authentication

On first run, you'll need to complete **two OAuth authorizations** (Hytale requirement):

### 1. Download OAuth
The container will show:
```
========================================
  HYTALE DOWNLOADER
========================================
Please visit the following URL to authenticate:
https://oauth.accounts.hytale.com/oauth2/device/verify?user_code=XXXX
Authorization code: XXXX
```

Visit the URL, log in with your Hytale account, and authorize.

### 2. Server OAuth
After download completes, you'll see:
```
========================================
  SERVER AUTHENTICATION REQUIRED
========================================
  Visit: https://oauth.accounts.hytale.com/oauth2/device/verify?user_code=YYYY
  Code:  YYYY
```

Authorize this as well.

### Why Two Logins?

Hytale uses separate OAuth clients with different scopes:
- `hytale-downloader` - Downloads game files
- `hytale-server` - Authenticates server for player connections

These cannot be combined (Hytale security restriction). **But both credentials are saved** - all future restarts require **zero logins**.

## Configuration

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `SERVER_NAME` | `Hytale Server` | Server name shown to players |
| `MOTD` | `""` | Message displayed on login |
| `PASSWORD` | `""` | Server password (empty = public) |
| `MAX_PLAYERS` | `100` | Maximum concurrent players |
| `MAX_VIEW_RADIUS` | `12` | View distance in chunks |
| `MEMORY` | `4G` | Java heap size |
| `SERVER_PORT` | `5520` | UDP port (QUIC protocol) |
| `TZ` | `UTC` | Container timezone |
| `ENABLE_BACKUP` | `false` | Enable automatic backups |
| `BACKUP_FREQUENCY` | `30` | Backup interval in minutes |
| `USE_AOT_CACHE` | `true` | Use AOT cache for faster startup |
| `AUTO_DOWNLOAD` | `true` | Auto-download server files |
| `AUTO_UPDATE` | `true` | Check for updates on start |
| `SKIP_DOWNLOAD` | `false` | Skip download (use existing files) |
| `UID` | `1000` | Linux user ID |
| `GID` | `1000` | Linux group ID |

### Skip Auto-Download

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

## Important Notes

### UDP Protocol (QUIC)

Hytale uses **QUIC over UDP**, not TCP. Ensure:
- Port forwarding is set for **UDP** port 5520
- Firewall allows UDP traffic

### Java 25 Required

Hytale requires Java 25. This image uses Eclipse Temurin JRE 25.

### Credential Persistence

Credentials are stored in the data volume:
- `.hytale-downloader-credentials.json` - Download OAuth tokens
- `.hytale-server-credentials.json` - Server OAuth tokens

Both auto-refresh. Delete these files to force re-authentication.

## Directory Structure

```
/data/
├── config.json                        # Server configuration (auto-generated)
├── HytaleServer.jar                   # Server executable (auto-downloaded)
├── Assets.zip                         # Game assets (auto-downloaded)
├── HytaleServer.aot                   # AOT cache (auto-downloaded)
├── .hytale-downloader-credentials.json # Download OAuth tokens
├── .hytale-server-credentials.json    # Server OAuth tokens
├── universe/                          # World data
├── mods/                              # Server mods
├── logs/                              # Server logs
├── backups/                           # Automatic backups
├── bans.json                          # Banned players
├── whitelist.json                     # Whitelisted players
└── permissions.json                   # Player permissions
```

## Building Locally

```bash
git clone https://github.com/terkea/hytale-server.git
cd hytale-server
docker build -t hytale-server:latest .
```

## Troubleshooting

### Server won't start
- Check logs: `docker logs hytale-server`
- Verify at least 4GB RAM is available
- Ensure OAuth was completed for both download and server

### Players can't connect
- Verify server OAuth was completed (check logs for "Server authenticated")
- Verify UDP port 5520 is forwarded correctly
- Check firewall allows UDP traffic

### OAuth keeps prompting
- Ensure data volume is mounted correctly
- Check if credential files exist in `/data/`

### Performance issues
- Increase memory: `MEMORY=8G`
- Reduce view radius: `MAX_VIEW_RADIUS=8`
- Enable AOT cache: `USE_AOT_CACHE=true`

## License

MIT License - See [LICENSE](LICENSE) file.

## Disclaimer

This project is not affiliated with Hypixel Studios or Hytale. Hytale is a trademark of Hypixel Studios. Users must own a valid Hytale license to use the server software.

## Links

- [Hytale Official Website](https://hytale.com/)
- [Hytale Server Manual](https://support.hytale.com/hc/en-us/articles/45326769420827-Hytale-Server-Manual)
- [Server Provider Authentication Guide](https://support.hytale.com/hc/en-us/articles/45326769420827)
