---
title: Home
layout: home
nav_order: 1
---

# Hytale Server Docker

A Docker image for running Hytale dedicated servers, inspired by [itzg/minecraft-server](https://github.com/itzg/docker-minecraft-server).

{: .warning }
Hytale is currently in early access. Server software and this Docker image may change frequently.

## Features

- **Auto-download** - Automatically downloads server files using official Hytale Downloader CLI
- **Auto-authentication** - Programmatic OAuth flow for server authentication
- **Persistent credentials** - Both download and server tokens are saved and auto-refreshed
- **Easy configuration** - All settings via environment variables
- **Multi-platform** - Supports `linux/amd64` and `linux/arm64`
- **Java 25** - Uses Eclipse Temurin JRE 25 as required by Hytale
- **UDP/QUIC ready** - Properly configured for Hytale's QUIC protocol

## Quick Start

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
      - ./machine-id:/etc/machine-id:ro
    stdin_open: true
    tty: true
    restart: unless-stopped
```

Create a `machine-id` file:
```bash
# Linux
cp /etc/machine-id ./machine-id

# Windows/macOS
uuidgen | tr -d '-' > machine-id
```

Start and follow the OAuth prompts:
```bash
docker compose up -d
docker logs -f hytale-server
```

## First-Time Authentication

On first run, you'll complete **two OAuth authorizations** (Hytale requirement):

1. **Download OAuth** - Authorizes downloading game files
2. **Server OAuth** - Authenticates server for player connections

Both credentials are saved - all future restarts require **zero logins**.

[Learn more about authentication](installation/authentication)

## Requirements

- Docker installed on your system
- A valid Hytale account with game access
- At least 4GB RAM available

## Important Notes

{: .note }
Hytale uses **UDP port 5520** (QUIC protocol), not TCP. Make sure your firewall and port forwarding are configured for UDP.

{: .important }
Two OAuth authorizations are required on first run. Watch `docker logs -f hytale-server` for the authorization URLs.
