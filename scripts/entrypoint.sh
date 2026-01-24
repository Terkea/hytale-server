#!/bin/bash
set -e

# Hytale Server Docker Entrypoint Script
# Handles user setup, server download, config generation, and server launch

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# =============================================================================
# Step 1: User and Group Setup
# =============================================================================
setup_user() {
    log_info "Setting up user with UID=${UID} and GID=${GID}"

    # Modify existing hytale user/group if UID/GID differ from defaults
    if [ "$UID" != "1000" ] || [ "$GID" != "1000" ]; then
        # Update group ID
        if [ "$GID" != "1000" ]; then
            groupmod -g "$GID" hytale 2>/dev/null || true
        fi

        # Update user ID
        if [ "$UID" != "1000" ]; then
            usermod -u "$UID" hytale 2>/dev/null || true
        fi
    fi

    # Ensure /data is owned by the correct user
    chown -R "$UID:$GID" /data

    log_success "User setup complete"
}

# =============================================================================
# Step 2: Set Timezone
# =============================================================================
setup_timezone() {
    if [ -n "$TZ" ] && [ "$TZ" != "UTC" ]; then
        log_info "Setting timezone to ${TZ}"
        ln -snf "/usr/share/zoneinfo/$TZ" /etc/localtime
        echo "$TZ" > /etc/timezone
    fi
}

# =============================================================================
# Step 3: Download Server Files (using Hytale Downloader CLI)
# =============================================================================
download_server_files() {
    log_info "Checking server files..."

    # Check if running on ARM64 (no downloader available)
    if [ "$(uname -m)" = "aarch64" ] && [ ! -f "/usr/local/bin/hytale-downloader" ]; then
        log_warn "ARM64 detected - Hytale Downloader not available for this architecture"
        if [ ! -f "/data/HytaleServer.jar" ] || [ ! -f "/data/Assets.zip" ]; then
            log_error "Server files not found!"
            log_error "On ARM64, you must provide server files manually."
            log_error "Copy from your Hytale installation to ./hytale-data/:"
            log_error "  - HytaleServer.jar"
            log_error "  - Assets.zip"
            log_error "  - HytaleServer.aot (optional)"
            exit 1
        fi
        log_success "Server files found - continuing on ARM64"
        return
    fi

    # Skip download if disabled
    if [ "$SKIP_DOWNLOAD" = "true" ]; then
        log_info "Skipping download (SKIP_DOWNLOAD=true)"
        if [ ! -f "/data/HytaleServer.jar" ] || [ ! -f "/data/Assets.zip" ]; then
            log_error "Server files not found and SKIP_DOWNLOAD=true!"
            log_error "Please provide HytaleServer.jar and Assets.zip in /data"
            exit 1
        fi
        return
    fi

    local need_download=false

    # Check if server JAR exists
    if [ ! -f "/data/HytaleServer.jar" ]; then
        need_download=true
    fi

    # Check if assets exist
    if [ ! -f "/data/Assets.zip" ]; then
        need_download=true
    fi

    # Force update check if AUTO_UPDATE is enabled
    if [ "$AUTO_UPDATE" = "true" ] && [ "$need_download" = "false" ]; then
        log_info "Checking for updates..."
        need_download=true
    fi

    if [ "$need_download" = "true" ] && [ "$AUTO_DOWNLOAD" = "true" ]; then
        log_info "Downloading server files using Hytale Downloader CLI..."
        echo ""
        echo "========================================"
        echo "  HYTALE DOWNLOADER"
        echo "========================================"
        echo ""

        # Set HOME for credentials storage (downloader stores at $HOME/.hytale-downloader-credentials.json)
        export HOME=/data

        cd /data

        # Run the downloader
        local download_args="-download-path /data/game.zip"

        if [ "$PATCHLINE" != "release" ]; then
            download_args="$download_args -patchline $PATCHLINE"
        fi

        # Run downloader - this will prompt for OAuth if needed
        if hytale-downloader $download_args; then
            log_success "Download completed!"

            # Extract the downloaded files
            if [ -f "/data/game.zip" ]; then
                log_info "Extracting server files..."
                unzip -o /data/game.zip -d /data/

                # Move files to correct locations
                if [ -d "/data/Server" ]; then
                    cp -f /data/Server/* /data/ 2>/dev/null || true
                    rm -rf /data/Server
                fi

                # Clean up
                rm -f /data/game.zip
                rm -rf /data/Client 2>/dev/null || true

                log_success "Server files extracted!"
            fi
        else
            log_error "Download failed!"
            log_error "This could be due to:"
            log_error "  1. Invalid/expired OAuth credentials"
            log_error "  2. Network issues"
            log_error "  3. No valid Hytale license"

            # If files exist, continue anyway
            if [ -f "/data/HytaleServer.jar" ] && [ -f "/data/Assets.zip" ]; then
                log_warn "Existing server files found, continuing..."
            else
                exit 1
            fi
        fi
    elif [ "$need_download" = "true" ]; then
        log_warn "AUTO_DOWNLOAD is disabled. Please provide server files manually."
        log_warn "Required files in /data:"
        log_warn "  - HytaleServer.jar"
        log_warn "  - Assets.zip"

        if [ ! -f "/data/HytaleServer.jar" ] || [ ! -f "/data/Assets.zip" ]; then
            log_error "Server files not found!"
            exit 1
        fi
    else
        log_success "Server files already present"
    fi

    # Verify files exist
    if [ ! -f "/data/HytaleServer.jar" ]; then
        log_error "HytaleServer.jar not found!"
        exit 1
    fi

    if [ ! -f "/data/Assets.zip" ]; then
        log_error "Assets.zip not found!"
        exit 1
    fi

    log_success "Server files ready"
}

# =============================================================================
# Step 4: Generate Configuration
# =============================================================================
generate_config() {
    if [ "$SKIP_CONFIG_UPDATE" = "true" ]; then
        log_info "Skipping config generation (SKIP_CONFIG_UPDATE=true)"
        return
    fi

    if [ ! -f "/data/config.json" ] || [ "$OVERRIDE_CONFIG" = "true" ]; then
        log_info "Generating config.json..."
        /config-generator.sh
        log_success "Config generated"
    else
        log_info "Using existing config.json (set OVERRIDE_CONFIG=true to regenerate)"
    fi
}

# =============================================================================
# Step 5: Create Directory Structure
# =============================================================================
create_directories() {
    log_info "Ensuring directory structure..."

    mkdir -p /data/universe/worlds
    mkdir -p /data/mods
    mkdir -p /data/logs
    mkdir -p /data/backups
    mkdir -p /data/.cache

    # Set permissions
    chown -R "$UID:$GID" /data

    log_success "Directory structure ready"
}

# =============================================================================
# Step 6: Build JVM Arguments
# =============================================================================
build_jvm_args() {
    local jvm_args=""

    # Memory settings
    local init_mem="${INIT_MEMORY:-$MEMORY}"
    local max_mem="${MAX_MEMORY:-$MEMORY}"

    jvm_args="-Xms${init_mem} -Xmx${max_mem}"

    # AOT Cache
    if [ "$USE_AOT_CACHE" = "true" ] && [ -f "/data/HytaleServer.aot" ]; then
        jvm_args="$jvm_args -XX:AOTCache=/data/HytaleServer.aot"
        log_info "Using AOT cache for faster startup" >&2
    fi

    # Custom JVM options
    if [ -n "$JVM_OPTS" ]; then
        jvm_args="$jvm_args $JVM_OPTS"
    fi

    # Custom -XX options
    if [ -n "$JVM_XX_OPTS" ]; then
        jvm_args="$jvm_args $JVM_XX_OPTS"
    fi

    echo "$jvm_args"
}

# =============================================================================
# Step 6b: Server Authentication (OAuth Device Flow)
# =============================================================================
SERVER_CREDS_FILE="/data/.hytale-server-credentials.json"

refresh_server_tokens() {
    local refresh_token="$1"

    log_info "Refreshing server OAuth tokens..." >&2

    local token_response=$(curl -s -X POST "https://oauth.accounts.hytale.com/oauth2/token" \
        -H "Content-Type: application/x-www-form-urlencoded" \
        -d "client_id=hytale-server" \
        -d "grant_type=refresh_token" \
        -d "refresh_token=$refresh_token" 2>/dev/null)

    if [ -z "$token_response" ]; then
        log_error "Failed to refresh tokens - no response" >&2
        return 1
    fi

    local error=$(echo "$token_response" | jq -r '.error' 2>/dev/null)
    if [ -n "$error" ] && [ "$error" != "null" ]; then
        log_error "Token refresh failed: $error" >&2
        return 1
    fi

    local new_access=$(echo "$token_response" | jq -r '.access_token' 2>/dev/null)
    local new_refresh=$(echo "$token_response" | jq -r '.refresh_token' 2>/dev/null)

    if [ -z "$new_access" ] || [ "$new_access" = "null" ]; then
        log_error "No access token in refresh response" >&2
        return 1
    fi

    # Save new tokens
    echo "$token_response" > "$SERVER_CREDS_FILE"
    log_success "OAuth tokens refreshed" >&2

    echo "$new_access"
}

create_game_session() {
    local access_token="$1"

    # Verify we have a token
    if [ -z "$access_token" ]; then
        log_error "No access token provided to create_game_session"
        return 1
    fi

    log_info "Getting game profiles..."

    # Get profiles
    local profiles_response=$(curl -s "https://account-data.hytale.com/my-account/get-profiles" \
        -H "Authorization: Bearer $access_token")

    if [ -z "$profiles_response" ]; then
        log_error "Failed to get profiles - empty response"
        return 1
    fi

    # Check for error in response
    local api_error=$(echo "$profiles_response" | jq -r '.error // .message // empty' 2>/dev/null)
    if [ -n "$api_error" ]; then
        log_error "Profile API error: $api_error"
        return 1
    fi

    local profile_uuid=$(echo "$profiles_response" | jq -r '.profiles[0].uuid' 2>/dev/null)
    local owner_uuid=$(echo "$profiles_response" | jq -r '.owner' 2>/dev/null)

    if [ -z "$profile_uuid" ] || [ "$profile_uuid" = "null" ]; then
        log_error "No profile found in response"
        log_error "Response: $profiles_response"
        return 1
    fi

    log_info "Creating game session for profile: $profile_uuid"

    # Create game session
    local session_response=$(curl -s -X POST "https://sessions.hytale.com/game-session/new" \
        -H "Authorization: Bearer $access_token" \
        -H "Content-Type: application/json" \
        -d "{\"uuid\": \"$profile_uuid\"}")

    if [ -z "$session_response" ]; then
        log_error "Failed to create game session - empty response"
        return 1
    fi

    # Check for error in response
    local session_error=$(echo "$session_response" | jq -r '.error // .message // empty' 2>/dev/null)
    if [ -n "$session_error" ]; then
        log_error "Session API error: $session_error"
        return 1
    fi

    local session_token=$(echo "$session_response" | jq -r '.sessionToken' 2>/dev/null)
    local identity_token=$(echo "$session_response" | jq -r '.identityToken' 2>/dev/null)

    if [ -z "$session_token" ] || [ "$session_token" = "null" ]; then
        log_error "No session token in response"
        log_error "Response: $session_response"
        return 1
    fi

    export HYTALE_SERVER_SESSION_TOKEN="$session_token"
    export HYTALE_SERVER_IDENTITY_TOKEN="$identity_token"
    export OWNER_UUID="$profile_uuid"

    log_success "Game session created!"
    log_info "Session token length: ${#session_token}"
    log_info "Identity token length: ${#identity_token}"
    return 0
}

do_device_auth_flow() {
    log_info "Starting server OAuth device flow..."

    # Request device code
    local device_response=$(curl -s -X POST "https://oauth.accounts.hytale.com/oauth2/device/auth" \
        -H "Content-Type: application/x-www-form-urlencoded" \
        -d "client_id=hytale-server" \
        -d "scope=openid offline auth:server" 2>/dev/null)

    if [ -z "$device_response" ]; then
        log_error "Failed to get device code"
        return 1
    fi

    local device_code=$(echo "$device_response" | jq -r '.device_code' 2>/dev/null)
    local user_code=$(echo "$device_response" | jq -r '.user_code' 2>/dev/null)
    local verification_uri=$(echo "$device_response" | jq -r '.verification_uri_complete' 2>/dev/null)
    local expires_in=$(echo "$device_response" | jq -r '.expires_in' 2>/dev/null)
    local interval=$(echo "$device_response" | jq -r '.interval' 2>/dev/null)

    if [ -z "$device_code" ] || [ "$device_code" = "null" ]; then
        log_error "No device code received"
        return 1
    fi

    echo "" >&2
    echo "========================================" >&2
    echo "  SERVER AUTHENTICATION REQUIRED" >&2
    echo "========================================" >&2
    echo "" >&2
    echo "  Visit: $verification_uri" >&2
    echo "  Code:  $user_code" >&2
    echo "" >&2
    echo "  Waiting for authorization..." >&2
    echo "========================================" >&2
    echo "" >&2

    # Poll for token
    local max_attempts=$((expires_in / interval))
    local attempt=0

    while [ $attempt -lt $max_attempts ]; do
        sleep "$interval"
        attempt=$((attempt + 1))

        local token_response=$(curl -s -X POST "https://oauth.accounts.hytale.com/oauth2/token" \
            -H "Content-Type: application/x-www-form-urlencoded" \
            -d "client_id=hytale-server" \
            -d "grant_type=urn:ietf:params:oauth:grant-type:device_code" \
            -d "device_code=$device_code" 2>/dev/null)

        local error=$(echo "$token_response" | jq -r '.error' 2>/dev/null)

        if [ "$error" = "authorization_pending" ]; then
            continue
        elif [ "$error" = "slow_down" ]; then
            interval=$((interval + 1))
            continue
        elif [ -n "$error" ] && [ "$error" != "null" ]; then
            log_error "Authorization failed: $error"
            return 1
        fi

        # Success!
        local access_token=$(echo "$token_response" | jq -r '.access_token' 2>/dev/null)
        if [ -n "$access_token" ] && [ "$access_token" != "null" ]; then
            log_success "Server OAuth authorized!" >&2
            log_info "Saving credentials..." >&2
            echo "$token_response" > "$SERVER_CREDS_FILE"
            echo "$access_token"
            return 0
        fi
    done

    log_error "Authorization timed out"
    return 1
}

setup_server_auth() {
    # Skip if tokens already provided via env vars
    if [ -n "$HYTALE_SERVER_SESSION_TOKEN" ] && [ -n "$HYTALE_SERVER_IDENTITY_TOKEN" ]; then
        log_info "Using provided server tokens"
        return 0
    fi

    # Check if we have saved server credentials with valid session
    if [ -f "$SERVER_CREDS_FILE" ]; then
        log_info "Found saved server credentials..."

        local access_token=$(jq -r '.access_token' "$SERVER_CREDS_FILE" 2>/dev/null)
        local refresh_token=$(jq -r '.refresh_token' "$SERVER_CREDS_FILE" 2>/dev/null)

        # Try to create game session with existing token
        if [ -n "$access_token" ] && [ "$access_token" != "null" ]; then
            if create_game_session "$access_token"; then
                return 0
            fi
        fi

        # Token might be expired, try refreshing
        if [ -n "$refresh_token" ] && [ "$refresh_token" != "null" ]; then
            log_info "Refreshing tokens..."
            local new_token=$(refresh_server_tokens "$refresh_token")
            if [ -n "$new_token" ]; then
                if create_game_session "$new_token"; then
                    return 0
                fi
            fi
        fi

        log_warn "Saved credentials invalid, need to re-authenticate"
        rm -f "$SERVER_CREDS_FILE"
    fi

    # Need to do device auth flow
    do_device_auth_flow
    if [ -f "$SERVER_CREDS_FILE" ]; then
        local access_token=$(jq -r '.access_token' "$SERVER_CREDS_FILE" 2>/dev/null)
        if [ -n "$access_token" ] && [ "$access_token" != "null" ]; then
            if create_game_session "$access_token"; then
                return 0
            fi
        fi
    fi

    log_warn "Server authentication failed - server will start unauthenticated"
    log_warn "Use /auth login device in the console to authenticate"
    return 0
}

# =============================================================================
# Step 7: Build Server Arguments
# =============================================================================
build_server_args() {
    local server_args="--assets /data/Assets.zip"

    # Bind address
    server_args="$server_args --bind ${BIND_ADDRESS}:${SERVER_PORT}"

    # Auth mode (authenticated, offline, etc.)
    if [ -n "$AUTH_MODE" ]; then
        server_args="$server_args --auth-mode $AUTH_MODE"
        log_info "Auth mode: $AUTH_MODE" >&2
    fi

    # Token passthrough (for pre-authenticated servers)
    if [ -n "$HYTALE_SERVER_SESSION_TOKEN" ]; then
        server_args="$server_args --session-token $HYTALE_SERVER_SESSION_TOKEN"
        log_info "Using provided session token" >&2
    fi

    if [ -n "$HYTALE_SERVER_IDENTITY_TOKEN" ]; then
        server_args="$server_args --identity-token $HYTALE_SERVER_IDENTITY_TOKEN"
        log_info "Using provided identity token" >&2
    fi

    if [ -n "$OWNER_UUID" ]; then
        server_args="$server_args --owner-uuid $OWNER_UUID"
        log_info "Using owner UUID: $OWNER_UUID" >&2
    fi

    # Backup settings
    if [ "$ENABLE_BACKUP" = "true" ]; then
        server_args="$server_args --backup"
        server_args="$server_args --backup-frequency ${BACKUP_FREQUENCY}"
        server_args="$server_args --backup-dir ${BACKUP_DIR}"
        log_info "Automatic backups enabled (every ${BACKUP_FREQUENCY} minutes)" >&2
    fi

    # Disable sentry if requested
    if [ "$DISABLE_SENTRY" = "true" ]; then
        server_args="$server_args --disable-sentry"
        log_info "Sentry error reporting disabled" >&2
    fi

    echo "$server_args"
}

# =============================================================================
# Step 8: Start Server
# =============================================================================
start_server() {
    log_info "Starting Hytale server..."

    local jvm_args=$(build_jvm_args)
    local server_args=$(build_server_args)

    log_info "JVM Arguments: $jvm_args"
    log_info "Server Arguments: $server_args"
    log_info "Bind: ${BIND_ADDRESS}:${SERVER_PORT}/udp"

    echo ""
    echo "========================================"
    echo "  Hytale Server Starting"
    echo "========================================"
    echo "  Server Name: ${SERVER_NAME}"
    echo "  Max Players: ${MAX_PLAYERS}"
    echo "  View Radius: ${MAX_VIEW_RADIUS}"
    echo "  Memory: ${MEMORY}"
    echo "  Port: ${SERVER_PORT}/udp"
    echo "========================================"
    echo ""

    if [ -n "$HYTALE_SERVER_SESSION_TOKEN" ] && [ -n "$HYTALE_SERVER_IDENTITY_TOKEN" ]; then
        log_success "Server authenticated and ready!"
        echo ""
    else
        log_warn "Server starting without authentication"
        log_warn "Players won't be able to connect until authenticated"
        echo ""
    fi

    # Run as hytale user
    cd /data
    exec su-exec "$UID:$GID" java $jvm_args -jar /data/HytaleServer.jar $server_args
}

# =============================================================================
# Main Execution
# =============================================================================
main() {
    echo ""
    echo "========================================"
    echo "  Hytale Server Docker Container"
    echo "========================================"
    echo ""

    setup_user
    setup_timezone
    create_directories
    download_server_files
    generate_config
    setup_server_auth
    start_server
}

# Run main function
main "$@"
