FROM jlesage/baseimage-gui:debian-12-v4

# Install dependencies for AppImage and cron
RUN apt-get update && \
    apt-get install -y wget curl fuse libfuse2 cron && \
    rm -rf /var/lib/apt/lists/*

# Copy our scripts
COPY scripts/startapp.sh /startapp.sh
COPY scripts/update-nextcloud.sh /scripts/update-nextcloud.sh
COPY scripts/nextcloud-cron /etc/cron.d/nextcloud-cron

# Set permissions
RUN chmod +x /startapp.sh /scripts/update-nextcloud.sh && \
    chmod 0644 /etc/cron.d/nextcloud-cron && \
    crontab /etc/cron.d/nextcloud-cron
