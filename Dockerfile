# Base image with GUI support
FROM jlesage/baseimage-gui:debian-12-v4

# Install Nextcloud Desktop Client
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        nextcloud-desktop \
        cron \
        && apt-get clean && rm -rf /var/lib/apt/lists/*

# Add rootfs contents (services + cron job)
COPY rootfs/ /
# Make sure the update script is executable
RUN chmod +x /usr/local/bin/update-nextcloud.sh /startapp.sh
# Expose GUI port (VNC/noVNC)
EXPOSE 5800 5900
