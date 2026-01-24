---
title: FAQ
layout: default
nav_order: 4
---

# Frequently Asked Questions

Common questions and troubleshooting tips.

---

## General

### Why are there two OAuth logins?

Hytale uses separate OAuth clients with different scopes:
- `hytale-downloader` (scope: `auth:downloader`) - Downloads game files
- `hytale-server` (scope: `auth:server`) - Authenticates server for players

These cannot be combined (Hytale security restriction). **But both are saved** - subsequent restarts need zero logins.

### Why UDP instead of TCP?

Hytale uses the **QUIC protocol** which runs over UDP, not TCP. This is different from Minecraft which uses TCP. Make sure your port forwarding and firewall rules are configured for **UDP port 5520**.

### What Java version is required?

Hytale requires **Java 25**. This Docker image uses Eclipse Temurin JRE 25, so you don't need to worry about it.

### Does it work on ARM / Raspberry Pi / Apple Silicon?

Yes. The image supports both `linux/amd64` and `linux/arm64` architectures. It works on Raspberry Pi 4/5, Apple Silicon Macs (M1/M2/M3), AWS Graviton, and other ARM64 systems.

**Note:** On ARM64, the auto-download feature is not available because Hytale only provides an x86 downloader. You must provide server files manually:

```yaml
volumes:
  - ./hytale-data:/data
  # Copy these files to ./hytale-data/:
  # - HytaleServer.jar
  # - Assets.zip
  # - HytaleServer.aot (optional)
```

Copy the files from your local Hytale installation, then start the container. Server authentication still works normally.

### Is this affiliated with Hypixel Studios?

No. This is a community project. Hytale is a trademark of Hypixel Studios.

---

## Updates

### How do I update the Hytale server?

Hytale is in early access with frequent updates. To update your server, simply restart the container:

```bash
docker compose restart
```

With `AUTO_UPDATE=true` (default), the container checks for updates on every start and downloads new server files automatically.

### How do I check if an update is available?

Watch the logs during startup:

```bash
docker compose restart
docker logs -f hytale-server
```

If an update is available, you'll see download progress in the logs.

### Can I disable automatic updates?

Yes, set `AUTO_UPDATE=false`:

```yaml
environment:
  - AUTO_UPDATE=false
```

The server will only download files if they're missing, not check for newer versions.

---

## Authentication

### Do I need to log in every time?

No. Both OAuth credentials are saved to your data volume and automatically refreshed. After first-time setup, restarts require zero logins.

### OAuth code expired before I could use it

Restart the container to get a new code:
```bash
docker compose restart
docker logs -f hytale-server
```

### Server shows "No server tokens configured"

The second OAuth (server auth) failed. Check:
1. Did you complete both OAuth prompts?
2. Look for errors in logs: `docker logs hytale-server | grep -i error`
3. Delete credentials and retry:
   ```bash
   rm ./hytale-data/.hytale-server-credentials.json
   docker compose restart
   ```

### Can I skip the download OAuth?

Yes. If you have server files from your local Hytale installation:
```yaml
environment:
  - SKIP_DOWNLOAD=true
```
Copy `HytaleServer.jar`, `Assets.zip`, and optionally `HytaleServer.aot` to your data directory.

---

## Connection Issues

### Players can't connect

1. **Authentication**: Ensure server shows `Authentication mode: AUTHENTICATED` in logs
2. **Port forwarding**: Ensure UDP 5520 is forwarded to your server
3. **Firewall**: Allow UDP traffic on port 5520
4. **Server status**: Check logs with `docker logs hytale-server`

### "Connection timed out" error

- Verify the server is running: `docker ps`
- Check UDP port is exposed: `docker port hytale-server`
- Test from local network first before external

---

## Performance

### Server is using too much memory

Adjust the `MEMORY` variable:

```yaml
environment:
  - MEMORY=4G
```

### Slow startup times

Enable AOT caching (enabled by default):

```yaml
environment:
  - USE_AOT_CACHE=true
```

### High CPU usage

- Reduce `MAX_VIEW_RADIUS` (default: 12)
- Reduce `MAX_PLAYERS`
- Ensure adequate CPU resources

---

## Configuration

### How do I edit config.json manually?

Set `SKIP_CONFIG_UPDATE=true` to prevent the container from overwriting your changes:

```yaml
environment:
  - SKIP_CONFIG_UPDATE=true
```

### Changes aren't being applied

By default, `config.json` is regenerated on each start. Either:
- Set `OVERRIDE_CONFIG=false` to keep manual changes
- Or set `SKIP_CONFIG_UPDATE=true` to fully disable auto-config

### How do I add mods?

Place mod files in the `mods/` directory inside your data volume:

```bash
cp my-mod.zip ./hytale-data/mods/
docker compose restart
```

---

## Docker

### How do I access the server console?

```bash
docker attach hytale-server
```

Press `Ctrl+P`, `Ctrl+Q` to detach without stopping.

### How do I view logs?

```bash
# All logs
docker logs hytale-server

# Follow logs
docker logs -f hytale-server

# Last 100 lines
docker logs --tail 100 hytale-server
```

### Container keeps restarting

Check the logs for errors:

```bash
docker logs hytale-server
```

Common causes:
- OAuth authorization not completed
- Missing server files (check `AUTO_DOWNLOAD=true`)
- Insufficient memory

### How do I update the Docker image?

Even if you already have `:latest` locally, Docker will check for a newer version:

```bash
# Pull the latest image from registry
docker compose pull

# Recreate containers with new image
docker compose up -d
```

Or as a single command with full cleanup:

```bash
docker compose down && docker compose pull && docker compose up -d
```

**If pull doesn't update** (rare caching issues):

```bash
# Force remove the old image
docker compose down
docker rmi ghcr.io/yourusername/hytale-server:latest
docker compose pull
docker compose up -d
```

**Building locally** (if you cloned the repo):

```bash
docker compose build --no-cache
docker compose up -d
```

{: .note }
The `:latest` tag is just a name - Docker checks the image digest (hash) to determine if a newer version exists on the registry.

### How do I force re-authentication?

```bash
# Remove saved credentials
rm ./hytale-data/.hytale-*-credentials.json

# Restart
docker compose restart
docker logs -f hytale-server
```
