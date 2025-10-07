# nextcloud-gui/Dockerfile
FROM jlesage/baseimage-gui:debian-12-v4

USER root
# Environment variables for jlesage base image
ENV APP_NAME="Nextcloud Desktop"
ENV KEEP_APP_RUNNING=1
ENV HOME=/config

# ----------------------------------------------------
# 1️⃣ System setup and dependencies
# ----------------------------------------------------

# Install dependencies
RUN apt-get update && \
    apt-get install -y python3 python3-pip curl gnupg ca-certificates cron jq locales && \
    pip3 install pyyaml && \
    rm -rf /var/lib/apt/lists/*

# Install Nextcloud desktop client and cron
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        nextcloud-desktop && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Set locale (avoids Qt warnings)
RUN echo "en_GB.UTF-8 UTF-8" > /etc/locale.gen && locale-gen

# ----------------------------------------------------
# Create configuration directories
# These will be re-owned automatically by the runtime user.
# ----------------------------------------------------
RUN mkdir -p /defaults/config/.config/Nextcloud && \
    chmod -R 777 /defaults/config

# Add rootfs (cron + startup script)
COPY rootfs/ /

# Make scripts executable
RUN chmod +x /startapp.sh /usr/local/bin/update-nextcloud.sh && \
    chmod 0644 /etc/cron.d/nextcloud-update && \
    crontab /etc/cron.d/nextcloud-update

# Expose GUI ports
EXPOSE 5800 5900

USER app
