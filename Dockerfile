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

# Expose GUI port (VNC/noVNC)
EXPOSE 5800
EXPOSE 5900
