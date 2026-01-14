#!/bin/bash
# Hytale Server Configuration Generator
# Generates config.json from environment variables

set -e

CONFIG_FILE="/data/config.json"

# Convert string to boolean for JSON
bool_to_json() {
    local value="$1"
    if [ "$value" = "true" ] || [ "$value" = "TRUE" ] || [ "$value" = "1" ]; then
        echo "true"
    else
        echo "false"
    fi
}

# Escape string for JSON
escape_json_string() {
    local string="$1"
    # Escape backslashes, double quotes, and control characters
    echo -n "$string" | sed 's/\\/\\\\/g; s/"/\\"/g; s/\t/\\t/g; s/\n/\\n/g; s/\r/\\r/g'
}

# Generate the config.json file
generate_config() {
    local server_name=$(escape_json_string "${SERVER_NAME:-Hytale Server}")
    local motd=$(escape_json_string "${MOTD:-}")
    local password=$(escape_json_string "${PASSWORD:-}")
    local max_players="${MAX_PLAYERS:-100}"
    local max_view_radius="${MAX_VIEW_RADIUS:-12}"
    local default_world=$(escape_json_string "${DEFAULT_WORLD:-default}")
    local default_gamemode=$(escape_json_string "${DEFAULT_GAMEMODE:-Adventure}")
    local local_compression=$(bool_to_json "${LOCAL_COMPRESSION_ENABLED:-false}")

    cat > "$CONFIG_FILE" << EOF
{
  "Version": 3,
  "ServerName": "${server_name}",
  "MOTD": "${motd}",
  "Password": "${password}",
  "MaxPlayers": ${max_players},
  "MaxViewRadius": ${max_view_radius},
  "LocalCompressionEnabled": ${local_compression},
  "Defaults": {
    "World": "${default_world}",
    "GameMode": "${default_gamemode}"
  },
  "ConnectionTimeouts": {
    "JoinTimeouts": {}
  },
  "RateLimit": {},
  "Modules": {},
  "LogLevels": {},
  "Mods": {},
  "DisplayTmpTagsInStrings": false,
  "PlayerStorage": {
    "Type": "Hytale"
  }
}
EOF

    echo "Generated config.json:"
    cat "$CONFIG_FILE"
}

# Main execution
generate_config
