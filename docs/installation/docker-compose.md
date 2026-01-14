---
title: Docker Compose
permalink: /installation/docker-compose
---

# Docker Compose Installation

The recommended way to run your Hytale server.

## 1. Create Project Directory

```bash
mkdir hytale-server
cd hytale-server
```

## 2. Create machine-id File

Required for persistent authentication:

```bash
# Linux
cp /etc/machine-id ./machine-id

# Windows/macOS
uuidgen | tr -d '-' > machine-id
```

## 3. Create docker-compose.yml

```yaml
services:
  hytale:
    image: ghcr.io/terkea/hytale-server:latest
    container_name: hytale-server
    ports:
      - "5520:5520/udp"
    environment:
      - SERVER_NAME=My Hytale Server
      - MOTD=Welcome to my server!
      - MAX_PLAYERS=50
      - MEMORY=4G
    volumes:
      - ./hytale-data:/data
      - ./machine-id:/etc/machine-id:ro
    stdin_open: true
    tty: true
    restart: unless-stopped
```

## 4. Start the Server

```bash
docker compose up -d
docker logs -f hytale-server
```

## 5. Complete OAuth

Watch the logs for two OAuth prompts:

1. **Download OAuth** - Authorizes downloading game files
2. **Server OAuth** - Authenticates server for players

Visit the URLs shown and authorize with your Hytale account.

> **Tip:** Press `Ctrl+C` to stop following logs. The server keeps running in the background.

## Useful Commands

| Command | Description |
|---------|-------------|
| `docker compose up -d` | Start server in background |
| `docker compose down` | Stop server |
| `docker compose logs -f` | Follow server logs |
| `docker compose restart` | Restart server |
| `docker attach hytale-server` | Access server console |
