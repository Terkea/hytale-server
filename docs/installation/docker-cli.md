---
title: Docker CLI
layout: default
parent: Installation
nav_order: 2
---

# Docker CLI Installation

Run your Hytale server using Docker commands directly.

## 1. Pull the Image

```bash
docker pull ghcr.io/terkea/hytale-server:latest
```

## 2. Create Data Directory

```bash
mkdir -p hytale-data
```

## 3. Run the Server

```bash
docker run -d --name hytale-server \
  -p 5520:5520/udp \
  -v ./hytale-data:/data \
  -e SERVER_NAME="My Hytale Server" \
  -e MOTD="Welcome!" \
  -e MAX_PLAYERS=50 \
  -e MEMORY=4G \
  -it \
  ghcr.io/terkea/hytale-server:latest
```

> **Important:** The `-it` flags are required for interactive authentication.

## 4. Complete OAuth

```bash
docker logs -f hytale-server
```

Complete both OAuth prompts shown in the logs.

## Useful Commands

```bash
# Start server
docker start hytale-server

# Stop server
docker stop hytale-server

# View logs
docker logs hytale-server

# Follow logs
docker logs -f hytale-server

# Attach to console
docker attach hytale-server

# Remove container
docker rm hytale-server
```
