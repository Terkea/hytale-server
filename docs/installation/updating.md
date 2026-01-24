---
title: Updating
layout: default
parent: Installation
nav_order: 4
---

# Updating

This guide covers updating both the Hytale server (game files) and the Docker image itself.

## Updating the Hytale Server (Game)

Hytale is in early access with frequent updates. By default, the container checks for game updates automatically.

### Automatic Updates (Default)

With `AUTO_UPDATE=true` (default), simply restart the container:

```bash
docker compose restart
```

The container will:
1. Check for new server files
2. Download updates if available
3. Extract and apply the update
4. Start the server

Watch the logs to see update progress:
```bash
docker logs -f hytale-server
```

### Manual Updates

If you've disabled auto-updates (`AUTO_UPDATE=false`):

```bash
# Remove old server files
rm ./hytale-data/HytaleServer.jar
rm ./hytale-data/Assets.zip

# Restart to trigger download
docker compose restart
```

---

## Updating the Docker Image

When we release bug fixes or improvements to the container itself, you'll need to update the Docker image.

### From Docker Registry (Most Users)

If you're using the pre-built image from a registry:

```bash
# Stop the container
docker compose down

# Pull the latest image
docker compose pull

# Start with the new image
docker compose up -d
```

Or as a single command:
```bash
docker compose down && docker compose pull && docker compose up -d
```

{: .note }
Even if you already have `:latest` locally, `docker compose pull` checks the registry for a newer version by comparing image digests.

### Force Update (Cache Issues)

If `docker compose pull` says "Image is up to date" but you know there's a newer version:

```bash
# Stop container
docker compose down

# Remove the cached image
docker rmi ghcr.io/terkea/hytale-server:latest

# Pull fresh and start
docker compose pull
docker compose up -d
```

### Building Locally (Developers)

If you cloned the repository and build locally:

```bash
# Stop container
docker compose down

# Pull latest code
git pull

# Rebuild without cache
docker compose build --no-cache

# Start with new image
docker compose up -d
```

Or as a single command:
```bash
docker compose down && git pull && docker compose build --no-cache && docker compose up -d
```

---

## Version Pinning

For production stability, you may want to pin to a specific version instead of `:latest`:

```yaml
services:
  hytale:
    image: ghcr.io/terkea/hytale-server:v1.2.0  # Pin to specific version
```

Check the [releases page](https://github.com/terkea/hytale-server-docker/releases) for available versions.

---

## What Gets Updated

| Update Type | What Changes | Data Preserved |
|-------------|--------------|----------------|
| Game Update | `HytaleServer.jar`, `Assets.zip` | Worlds, config, credentials |
| Image Update | Container scripts, Java version | All `/data` volume contents |

{: .important }
Your world data, configuration, and credentials are stored in the `/data` volume and are **never** deleted during updates.

---

## Checking Versions

### Current Game Version

Check the logs during startup:
```bash
docker logs hytale-server | grep "version"
```

### Current Image Version

```bash
docker inspect hytale-server --format '{{.Config.Image}}'
docker images ghcr.io/terkea/hytale-server
```

### Check for Available Updates

```bash
# Check if a newer image exists (without pulling)
docker pull --dry-run ghcr.io/terkea/hytale-server:latest
```
