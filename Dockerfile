# Hytale Dedicated Server Docker Image
# Based on the itzg/minecraft-server pattern, adapted for Hytale

FROM eclipse-temurin:25-jre-alpine

LABEL maintainer="hytale-docker"
LABEL description="Hytale Dedicated Server"
LABEL version="1.0.0"

# Install dependencies
# libgcc and libstdc++ are required for Netty QUIC native libraries
RUN apk add --no-cache \
    bash \
    curl \
    wget \
    jq \
    shadow \
    tzdata \
    procps \
    su-exec \
    libgcc \
    libstdc++ \
    gcompat \
    unzip

# Download and install Hytale Downloader CLI
ARG TARGETARCH
RUN mkdir -p /opt/hytale-downloader && \
    wget -q -O /tmp/hytale-downloader.zip "https://downloader.hytale.com/hytale-downloader.zip" && \
    unzip -q /tmp/hytale-downloader.zip -d /opt/hytale-downloader && \
    ARCH=$([ "$TARGETARCH" = "arm64" ] && echo "arm64" || echo "amd64") && \
    chmod +x /opt/hytale-downloader/hytale-downloader-linux-${ARCH} && \
    ln -s /opt/hytale-downloader/hytale-downloader-linux-${ARCH} /usr/local/bin/hytale-downloader && \
    rm /tmp/hytale-downloader.zip

# Environment defaults - Core Server Settings
ENV SERVER_NAME="Hytale Server" \
    MOTD="" \
    PASSWORD="" \
    MAX_PLAYERS=100 \
    MAX_VIEW_RADIUS=12 \
    DEFAULT_WORLD="default" \
    DEFAULT_GAMEMODE="Adventure" \
    LOCAL_COMPRESSION_ENABLED="false"

# Environment defaults - Memory/JVM Settings
ENV MEMORY="4G" \
    INIT_MEMORY="" \
    MAX_MEMORY="" \
    JVM_OPTS="" \
    JVM_XX_OPTS="" \
    USE_AOT_CACHE="true"

# Environment defaults - Network Settings
ENV SERVER_PORT=5520 \
    BIND_ADDRESS="0.0.0.0"

# Environment defaults - User/Permission Settings
ENV UID=1000 \
    GID=1000 \
    TZ="UTC"

# Environment defaults - Authentication Settings
ENV AUTH_MODE="" \
    DISABLE_SENTRY="false"

# Environment defaults - Backup Settings
ENV ENABLE_BACKUP="false" \
    BACKUP_FREQUENCY=30 \
    BACKUP_DIR="/data/backups"

# Environment defaults - Download/Update Settings
ENV AUTO_DOWNLOAD="true" \
    AUTO_UPDATE="true" \
    PATCHLINE="release" \
    SKIP_DOWNLOAD="false"

# Environment defaults - Config Override
ENV OVERRIDE_CONFIG="true" \
    SKIP_CONFIG_UPDATE="false"

# Create hytale user and data directory
RUN addgroup -g 1000 hytale && \
    adduser -D -u 1000 -G hytale -h /data hytale && \
    mkdir -p /data /data/universe /data/mods /data/logs /data/backups /data/.cache && \
    chown -R hytale:hytale /data

WORKDIR /data

# Copy scripts
COPY --chmod=755 scripts/entrypoint.sh /entrypoint.sh
COPY --chmod=755 scripts/config-generator.sh /config-generator.sh
COPY --chmod=755 scripts/health-check.sh /health-check.sh

# Expose UDP port (QUIC protocol - NOT TCP!)
EXPOSE 5520/udp

# Health check - check if Java process is running
# Start period is longer because server needs time to download and start
HEALTHCHECK --interval=30s --timeout=10s --start-period=180s --retries=3 \
    CMD /health-check.sh

# Volume for persistent data
VOLUME ["/data"]

# Entrypoint
ENTRYPOINT ["/entrypoint.sh"]
