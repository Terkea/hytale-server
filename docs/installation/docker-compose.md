---
title: Docker Compose
layout: default
parent: Installation
nav_order: 1
---

# Docker Compose Installation

The recommended way to run your Hytale server.

## 1. Create Project Directory

```bash
mkdir hytale-server
cd hytale-server
```

## 2. Create docker-compose.yml

Create a `docker-compose.yml` file:

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
    stdin_open: true
    tty: true
    restart: unless-stopped
```

## 3. Start the Server

```bash
docker compose up -d
```

## 4. Authenticate

The server needs OAuth authentication before accepting players:

```bash
# View logs to see the auth URL
docker compose logs -f

# Or attach to enter commands
docker attach hytale-server
```

Follow the instructions to complete authentication at `accounts.hytale.com/device`.

{: .note }
Press `Ctrl+P`, then `Ctrl+Q` to detach from the container without stopping it.

## 5. Verify

Check that the server is running:

```bash
docker compose ps
docker compose logs --tail 50
```

## Useful Commands

| Command | Description |
|---------|-------------|
| `docker compose up -d` | Start server in background |
| `docker compose down` | Stop server |
| `docker compose logs -f` | Follow server logs |
| `docker compose restart` | Restart server |
| `docker attach hytale-server` | Access server console |
