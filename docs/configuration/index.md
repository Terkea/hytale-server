---
title: Configuration
layout: default
nav_order: 3
has_children: true
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

See the sub-pages for complete configuration options.
