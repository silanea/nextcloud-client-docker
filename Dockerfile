FROM jlesage/baseimage-gui:debian-12-v4

# Environment
ENV APPIMAGE_PATH=/opt/nextcloud/Nextcloud.AppImage
ENV DISPLAY_WIDTH=1280
ENV DISPLAY_HEIGHT=800

# Install dependencies for downloading and version checking
RUN apt-get update && \
    apt-get install -y --no-install-recommends curl wget jq ca-certificates fuse && \
    rm -rf /var/lib/apt/lists/*

# Create directory for Nextcloud client
RUN mkdir -p /opt/nextcloud

# Copy scripts
COPY update.sh /usr/local/bin/update.sh
COPY entrypoint.sh /entrypoint.sh
COPY crontab.txt /etc/cron.d/nextcloud-updater

# Permissions
RUN chmod +x /usr/local/bin/update.sh /entrypoint.sh && \
    chmod 0644 /etc/cron.d/nextcloud-updater && \
    touch /var/log/cron.log

# Add cron job
RUN crontab /etc/cron.d/nextcloud-updater

ENTRYPOINT ["/entrypoint.sh"]
