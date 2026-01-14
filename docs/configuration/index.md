---
title: Configuration
permalink: /configuration/
---

# Configuration

Configure your Hytale server using environment variables.

All settings are passed as environment variables to the Docker container. The entrypoint script automatically generates the appropriate `config.json` file.

## Quick Reference

| Variable | Default | Description |
|----------|---------|-------------|
| `SERVER_NAME` | `Hytale Server` | Server name |
| `MAX_PLAYERS` | `100` | Maximum players |
| `MEMORY` | `4G` | Java heap size |
| `SERVER_PORT` | `5520` | UDP port |

## Configuration Pages

- [Environment Variables](environment-variables) - All available settings
- [Volumes](volumes) - Data persistence and file locations
