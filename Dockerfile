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

RUN apt-get update && \
    apt-get install -y locales && \
    locale-gen en_US.UTF-8 && \
    update-locale LANG=en_US.UTF-8
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

# Install dependencies
RUN apt-get update && \
    apt-get install -y python3 python3-yaml curl gnupg ca-certificates cron jq && \
    rm -rf /var/lib/apt/lists/*

# Install Nextcloud desktop client and cron
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        nextcloud-desktop && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# ----------------------------------------------------
# Create configuration directories
# These will be re-owned automatically by the runtime user.
# ----------------------------------------------------
RUN mkdir -p /defaults/config/.config/Nextcloud && \
    mkdir -p /config/log && \
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
