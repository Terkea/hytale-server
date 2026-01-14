#!/bin/bash
# Hytale Server Health Check Script
# Used by Docker HEALTHCHECK to determine container health

# Check if the Java process running HytaleServer.jar is alive
if pgrep -f "HytaleServer.jar" > /dev/null 2>&1; then
    # Process is running
    exit 0
else
    # Process is not running
    exit 1
fi
